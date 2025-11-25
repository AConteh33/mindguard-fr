import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final Alignment alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getResponsivePadding(context);
    final responsiveMaxWidth = maxWidth ?? ResponsiveHelper.getResponsiveMaxWidth(context);
    
    return Container(
      width: double.infinity,
      alignment: alignment,
      padding: responsivePadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: responsiveMaxWidth,
        ),
        child: child,
      ),
    );
  }
}
