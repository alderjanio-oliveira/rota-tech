import 'dart:core';

class Constants {
  static const String traccarBaseUrl = "https://demo.traccar.org";
  static const String traccarApiVersion = "v3";
  static const String taskTripAlert = "trip_alert";
  static const String taskTripAlertNext = "trip_alert_next";

  static const String notificationKey = "notification_payload";
  static const int minFrequencyWorkmanager = 60 * 24; // 24 horas

  /// A partir de quantos km restantes a checagem passa a rodar por hora
  /// (antes disso, roda 1x por dia).
  static const int tripAlertHourlyThresholdKm = 200;
  static const int tripAlertHourlyFrequencyMinutes = 60;
  static const int tripAlertNormalFrequencyMinutes = 60 * 24;
}
