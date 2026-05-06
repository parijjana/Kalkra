import 'package:flutter/material.dart';
import '../models/themer_model.dart';
import '../compiler/themer_compiler.dart';

/// A widget that provides a [.themer] theme to the widget tree.
///
/// It uses [ThemerCompiler] to translate the [ThemerModel] into [ThemeData]
/// and wraps its child in a [Theme] widget.
class ThemerProvider extends StatelessWidget {
  final ThemerModel theme;
  final Widget child;

  const ThemerProvider({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = ThemerCompiler.compile(theme);

    return Theme(
      data: themeData,
      child: child,
    );
  }
}
