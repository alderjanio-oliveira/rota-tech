import 'dart:core';

class Constants {
  static const String traccarBaseUrl = "https://demo.traccar.org";
  static const String traccarApiVersion = "v3";
  static const String taskTripAlert = "trip_alert";
  static const String taskTripAlertNext = "trip_alert_next";

  static const String notificationKey = "notification_payload";
  static const int minFrequencyWorkmanager = 60 * 24; // 24 horas
  static const int tripAlertCriticalKm = 100;
  static const int tripAlertWarningKm = 300;
  static const int tripAlertCriticalFrequencyMinutes = 60;
  static const int tripAlertWarningFrequencyMinutes = 180;
  static const int tripAlertNormalFrequencyMinutes = 60 * 24;
}
