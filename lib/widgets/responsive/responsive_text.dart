import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final double? maxWidth;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle responsiveStyle = style ?? const TextStyle();
    
    // Adjust font size based on device type
    if (style?.fontSize != null) {
      final baseFontSize = style!.fontSize!;
      responsiveStyle = style!.copyWith(
        fontSize: ResponsiveHelper.getResponsiveFontSize(
          context,
          baseFontSize,
          tabletSize: baseFontSize * 1.1,
          desktopSize: baseFontSize * 1.2,
        ),
      );
    }
    
    Widget textWidget = Text(
      text,
      style: responsiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
    
    // Apply max width constraint if specified
    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: textWidget,
      );
    }
    
    return textWidget;
  }
}
