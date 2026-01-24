import 'package:flutter/material.dart';

class BasePageTemplate extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;

  const BasePageTemplate({
    super.key,
    required this.body,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(title: Text(title!), actions: actions)
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: body,
        ),
      ),
    );
  }
}
