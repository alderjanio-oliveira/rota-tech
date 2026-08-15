/// Espelha `org.traccar.model.DistanceReminder` do backend (fork
/// gps-mobgotech) — tabela `tc_distance_reminders`, endpoint
/// `/api/distancereminders`. Isso substitui o antigo `attributes.trip`
/// no device, que esse fork nunca mais escreve.
class DistanceReminder {
  static const statusPending = 'pending';
  static const statusNotified = 'notified';
  static const statusDone = 'done';
  static const statusCancelled = 'cancelled';

  final int id;
  final String name;

  /// Meta de km (mesma unidade de `totalDistance`, ou seja, metros).
  final double thresholdDistance;

  /// Odômetro no momento em que o lembrete foi criado/resetado.
  final double startValue;

  final String status;
  final DateTime? notifiedAt;
  final DateTime? confirmedAt;
  final double traveledDistance;
  final DateTime? cancelledAt;

  const DistanceReminder({
    required this.id,
    required this.name,
    required this.thresholdDistance,
    required this.startValue,
    required this.status,
    this.notifiedAt,
    this.confirmedAt,
    required this.traveledDistance,
    this.cancelledAt,
  });

  bool get isPending => status == statusPending || status == statusNotified;

  /// Km rodado desde o início, calculado ao vivo a partir do odômetro atual
  /// do device (enquanto pendente; depois de confirmado, `traveledDistance`
  /// já vem pronto do servidor).
  double traveledFor(double currentTotalDistance) {
    if (!isPending) return traveledDistance;
    return currentTotalDistance - startValue;
  }

  bool reachedFor(double currentTotalDistance) {
    if (!isPending) return false;
    return traveledFor(currentTotalDistance) >= thresholdDistance;
  }

  factory DistanceReminder.fromJson(Map<String, dynamic> json) {
    return DistanceReminder(
      id: json['id'],
      name: json['name'] ?? '',
      thresholdDistance: (json['thresholdDistance'] ?? 0).toDouble(),
      startValue: (json['startValue'] ?? 0).toDouble(),
      status: json['status'] ?? statusPending,
      notifiedAt: _parseDate(json['notifiedAt']),
      confirmedAt: _parseDate(json['confirmedAt']),
      traveledDistance: (json['traveledDistance'] ?? 0).toDouble(),
      cancelledAt: _parseDate(json['cancelledAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
