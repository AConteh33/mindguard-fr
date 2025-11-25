import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    
    if (builder != null) {
      return builder(context, deviceType);
    }
    
    // Use specific widgets if provided
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile ?? Container();
      case DeviceType.tablet:
        return tablet ?? mobile ?? Container();
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile ?? Container();
    }
  }
}
