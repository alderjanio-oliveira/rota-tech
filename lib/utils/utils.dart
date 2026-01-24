import 'package:flutter/material.dart';

class Utils {
  choiceColorStatus(bool? status) {
    if (status == null) return Colors.grey;
    return status ? Colors.green : Colors.red;
  }
}
