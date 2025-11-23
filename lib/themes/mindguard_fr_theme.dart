import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

// Custom theme extension for the French version
class MindGuardFRThemeExtension extends ThemeExtension<MindGuardFRThemeExtension> {
  final Color? cardBackgroundColor;
  final Color? accentColor;
  final TextStyle? headlineStyle;
  final TextStyle? bodyStyle;

  const MindGuardFRThemeExtension({
    this.cardBackgroundColor,
    this.accentColor,
    this.headlineStyle,
    this.bodyStyle,
  });

  @override
  ThemeExtension<MindGuardFRThemeExtension> copyWith({
    Color? cardBackgroundColor,
    Color? accentColor,
    TextStyle? headlineStyle,
    TextStyle? bodyStyle,
  }) {
    return MindGuardFRThemeExtension(
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      accentColor: accentColor ?? this.accentColor,
      headlineStyle: headlineStyle ?? this.headlineStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
    );
  }

  @override
  ThemeExtension<MindGuardFRThemeExtension> lerp(ThemeExtension<MindGuardFRThemeExtension>? other, double t) {
    if (other is! MindGuardFRThemeExtension) return this;
    
    return MindGuardFRThemeExtension(
      cardBackgroundColor: Color.lerp(cardBackgroundColor, other.cardBackgroundColor, t),
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      headlineStyle: TextStyle.lerp(headlineStyle, other.headlineStyle, t),
      bodyStyle: TextStyle.lerp(bodyStyle, other.bodyStyle, t),
    );
  }
}

// Helper class to apply custom theme properties
class MindGuardFRTheme {
  static MindGuardFRThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<MindGuardFRThemeExtension>() ?? 
           const MindGuardFRThemeExtension();
  }
}