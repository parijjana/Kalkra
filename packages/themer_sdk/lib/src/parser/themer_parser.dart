import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/themer_model.dart';

/// Static utility to parse .themer JSON strings into [ThemerModel].
class ThemerParser {
  static ThemerModel parse(String jsonStr) {
    final Map<String, dynamic> data = jsonDecode(jsonStr);

    return ThemerModel(
      version: data['version'] as String,
      name: data['name'] as String,
      colors: _parseColors(data['colors'] as Map<String, dynamic>),
      typography: data['typography'] != null
          ? _parseTypography(data['typography'] as Map<String, dynamic>)
          : null,
      effects: data['effects'] != null
          ? _parseEffects(data['effects'] as Map<String, dynamic>)
          : null,
    );
  }

  static ThemerColors _parseColors(Map<String, dynamic> map) {
    return ThemerColors(
      primary: _parseColor(map['primary']),
      onPrimary: _parseColor(map['onPrimary']),
      secondary: _parseOptionalColor(map['secondary']),
      onSecondary: _parseOptionalColor(map['onSecondary']),
      surface: _parseColor(map['surface']),
      onSurface: _parseColor(map['onSurface']),
      background: _parseColor(map['background']),
      onBackground: _parseOptionalColor(map['onBackground']),
      error: _parseOptionalColor(map['error']),
      onError: _parseOptionalColor(map['onError']),
      shadow: _parseOptionalColor(map['shadow']),
    );
  }

  static ThemerTypography _parseTypography(Map<String, dynamic> map) {
    return ThemerTypography(
      fontFamily: map['fontFamily'] as String?,
      headingSize: (map['headingSize'] as num?)?.toDouble(),
      bodySize: (map['bodySize'] as num?)?.toDouble(),
      labelSize: (map['labelSize'] as num?)?.toDouble(),
    );
  }

  static ThemerEffects _parseEffects(Map<String, dynamic> map) {
    return ThemerEffects(
      roundness: (map['roundness'] as num?)?.toDouble(),
      elevation: (map['elevation'] as num?)?.toDouble(),
    );
  }

  static Color _parseColor(dynamic value) {
    if (value is! String) {
      throw const FormatException('Color value must be a string');
    }
    final hex = value.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    throw FormatException('Invalid hex color format: $value');
  }

  static Color? _parseOptionalColor(dynamic value) {
    if (value == null) return null;
    return _parseColor(value);
  }
}
