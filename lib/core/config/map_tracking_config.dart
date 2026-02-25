class MapTrackingConfig {
  final TrailMode mode;

  /// usado para:
  /// byPoints → quantidade máxima de pontos
  /// byTime → tempo máximo em minutos
  final int value;

  const MapTrackingConfig({required this.mode, required this.value});

  bool get isDisabled => value == 0 || mode == TrailMode.none;

  bool get isInfinite => value == -1;

  bool get usePoints => mode == TrailMode.byPoints;

  bool get useTime => mode == TrailMode.byTime;
}

enum TrailMode { none, byPoints, byTime }
