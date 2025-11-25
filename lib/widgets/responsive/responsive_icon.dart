import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const ResponsiveIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSize = size ?? ResponsiveHelper.getResponsiveIconSize(context, 24.0);
    
    return Icon(
      icon,
      size: responsiveSize,
      color: color,
    );
  }
}
