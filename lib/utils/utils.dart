import 'package:flutter/material.dart';

class Utils {
  choiceColorStatus(bool? status) {
    if (status == null) return Colors.grey;
    return status ? Colors.green : Colors.red;
  }

  /// Minúsculas e sem '-', para buscas que ignoram esse separador
  /// (ex.: "TSM-2I44" casa com "2i44" ou "tsm2i44").
  static String normalizeSearch(String value) => value.toLowerCase().replaceAll('-', '');
}
