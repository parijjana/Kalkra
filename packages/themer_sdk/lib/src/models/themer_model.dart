import 'package:flutter/material.dart';

/// Represents the color tokens of a theme.
class ThemerColors {
  final Color primary;
  final Color onPrimary;
  final Color? secondary;
  final Color? onSecondary;
  final Color surface;
  final Color onSurface;
  final Color background;
  final Color? onBackground;
  final Color? error;
  final Color? onError;
  final Color? shadow;

  const ThemerColors({
    required this.primary,
    required this.onPrimary,
    this.secondary,
    this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.background,
    this.onBackground,
    this.error,
    this.onError,
    this.shadow,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemerColors &&
          runtimeType == other.runtimeType &&
          primary == other.primary &&
          onPrimary == other.onPrimary &&
          secondary == other.secondary &&
          onSecondary == other.onSecondary &&
          surface == other.surface &&
          onSurface == other.onSurface &&
          background == other.background &&
          onBackground == other.onBackground &&
          error == other.error &&
          onError == other.onError &&
          shadow == other.shadow;

  @override
  int get hashCode =>
      primary.hashCode ^
      onPrimary.hashCode ^
      secondary.hashCode ^
      onSecondary.hashCode ^
      surface.hashCode ^
      onSurface.hashCode ^
      background.hashCode ^
      onBackground.hashCode ^
      error.hashCode ^
      onError.hashCode ^
      shadow.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'primary': _colorToHex(primary),
      'onPrimary': _colorToHex(onPrimary),
      if (secondary != null) 'secondary': _colorToHex(secondary!),
      if (onSecondary != null) 'onSecondary': _colorToHex(onSecondary!),
      'surface': _colorToHex(surface),
      'onSurface': _colorToHex(onSurface),
      'background': _colorToHex(background),
      if (onBackground != null) 'onBackground': _colorToHex(onBackground!),
      if (error != null) 'error': _colorToHex(error!),
      if (onError != null) 'onError': _colorToHex(onError!),
      if (shadow != null) 'shadow': _colorToHex(shadow!),
    };
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

/// Represents the typography tokens of a theme.
class ThemerTypography {
  final String? fontFamily;
  final double? headingSize;
  final double? bodySize;
  final double? labelSize;

  const ThemerTypography({
    this.fontFamily,
    this.headingSize,
    this.bodySize,
    this.labelSize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemerTypography &&
          runtimeType == other.runtimeType &&
          fontFamily == other.fontFamily &&
          headingSize == other.headingSize &&
          bodySize == other.bodySize &&
          labelSize == other.labelSize;

  @override
  int get hashCode =>
      fontFamily.hashCode ^
      headingSize.hashCode ^
      bodySize.hashCode ^
      labelSize.hashCode;

  Map<String, dynamic> toJson() {
    return {
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (headingSize != null) 'headingSize': headingSize,
      if (bodySize != null) 'bodySize': bodySize,
      if (labelSize != null) 'labelSize': labelSize,
    };
  }
}

/// Represents the visual effect tokens of a theme.
class ThemerEffects {
  final double? roundness;
  final double? elevation;

  const ThemerEffects({
    this.roundness,
    this.elevation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemerEffects &&
          runtimeType == other.runtimeType &&
          roundness == other.roundness &&
          elevation == other.elevation;

  @override
  int get hashCode => roundness.hashCode ^ elevation.hashCode;

  Map<String, dynamic> toJson() {
    return {
      if (roundness != null) 'roundness': roundness,
      if (elevation != null) 'elevation': elevation,
    };
  }
}

/// The root model for a .themer theme definition.
class ThemerModel {
  final String version;
  final String name;
  final ThemerColors colors;
  final ThemerTypography? typography;
  final ThemerEffects? effects;

  const ThemerModel({
    required this.version,
    required this.name,
    required this.colors,
    this.typography,
    this.effects,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemerModel &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          name == other.name &&
          colors == other.colors &&
          typography == other.typography &&
          effects == other.effects;

  @override
  int get hashCode =>
      version.hashCode ^
      name.hashCode ^
      colors.hashCode ^
      typography.hashCode ^
      effects.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'name': name,
      'colors': colors.toJson(),
      if (typography != null) 'typography': typography!.toJson(),
      if (effects != null) 'effects': effects!.toJson(),
    };
  }
}
