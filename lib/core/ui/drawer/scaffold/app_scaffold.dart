import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;

  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? bottomNavigationBar;

  final bool safeTop;
  final bool safeBottom;
  final EdgeInsetsGeometry? padding;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.bottomNavigationBar,
    this.safeTop = true,
    this.safeBottom = true,
    this.padding,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      top: safeTop,
      bottom: safeBottom,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: body),
    );

    return Scaffold(
      appBar: appBar,
      body: content,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
