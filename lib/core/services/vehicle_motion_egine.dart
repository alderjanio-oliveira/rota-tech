import 'dart:async';
import 'package:app_tracking/core/config/motion_config.dart';
import 'package:app_tracking/ui/model/motion_state.dart';
import 'package:app_tracking/utils/geo_utils.dart';
import 'package:latlong2/latlong.dart';

class VehicleMotionEngine {
  final _controller = StreamController<MotionUpdate>.broadcast();
  Stream<MotionUpdate> get stream => _controller.stream;

  final MotionState _state = MotionState();

  Timer? _timer;

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  void updateRealPosition({required LatLng newPosition, required double heading, double? speedKmh}) {
    final now = DateTime.now();

    final gapSinceLastFix = _state.lastUpdate == null ? null : now.difference(_state.lastUpdate!);

    // Só conta como hiato de verdade (quebra visual da trilha) quando passa
    // MUITO do intervalo normal de report do rastreador — senão qualquer
    // pausa comum entre pings já fragmentava a linha inteira.
    final hadGap = gapSinceLastFix != null && gapSinceLastFix > MotionConfig.trailGapThreshold;

    if (_state.lastRealPosition != null && speedKmh == null && gapSinceLastFix != null && gapSinceLastFix.inSeconds > 0) {
      final distance = GeoUtils.distanceInMeters(_state.lastRealPosition!, newPosition);
      _state.speed = distance / gapSinceLastFix.inSeconds;
    } else if (speedKmh != null) {
      _state.speed = speedKmh / 3.6;
    }

    _state.heading = heading;
    _state.lastRealPosition = newPosition;
    _state.currentPosition = newPosition;
    _state.lastUpdate = now;

    // Depois de um hiato de verdade (tela bloqueada, sem sinal por um bom
    // tempo), pula direto pra posição real — não conecta com uma linha reta
    // cruzando o hiato, começa um trecho novo de trilha.
    _controller.add(MotionUpdate(newPosition, startsNewSegment: hadGap));

    _startPrediction();
  }

  void _startPrediction() {
    _timer?.cancel();

    final interval = Duration(milliseconds: (1000 / MotionConfig.fps).round());

    _timer = Timer.periodic(interval, (timer) {
      if (_state.currentPosition == null || _state.lastUpdate == null) return;

      if (DateTime.now().difference(_state.lastUpdate!) > MotionConfig.maxPredictionAge) {
        // Sem posição real há tempo demais: para de "chutar" a posição em
        // vez de continuar projetando reto indefinidamente. Não conta como
        // hiato visual sozinho — só quando passar de trailGapThreshold.
        timer.cancel();
        return;
      }

      final distancePerFrame = _state.speed / MotionConfig.fps;

      final projected = GeoUtils.projectPosition(
        start: _state.currentPosition!,
        distanceMeters: distancePerFrame,
        headingDegrees: _state.heading,
      );

      _state.currentPosition = projected;

      _controller.add(MotionUpdate(projected));
    });
  }
}

class MotionUpdate {
  final LatLng position;

  /// true só na primeira posição depois de um hiato (tela bloqueada, app
  /// pausado, sem sinal) — sinaliza pra trilha começar um trecho novo em
  /// vez de ligar com uma linha reta ao ponto anterior.
  final bool startsNewSegment;

  const MotionUpdate(this.position, {this.startsNewSegment = false});
}
