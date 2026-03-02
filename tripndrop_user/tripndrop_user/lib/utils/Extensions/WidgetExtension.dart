import 'package:flutter/material.dart';

extension WidgetExtension on Widget? {
  /// set visibility
  Widget visible(bool visible, {Widget? defaultWidget}) {
    return visible ? this! : (defaultWidget ?? SizedBox());
  }
}