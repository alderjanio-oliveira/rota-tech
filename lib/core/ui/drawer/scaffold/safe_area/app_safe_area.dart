import 'package:flutter/widgets.dart';

class AppSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;

  const AppSafeArea({super.key, required this.child, this.top = true, this.bottom = true});

  @override
  Widget build(BuildContext context) {
    return SafeArea(top: top, bottom: bottom, child: child);
  }
}
