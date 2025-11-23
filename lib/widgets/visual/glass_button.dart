import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsets? padding;
  final double? opacity;
  final double? blurSigma;
  final BorderRadius? borderRadius;
  final Border? border;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.opacity = 0.7,
    this.blurSigma = 10.0,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma ?? 10.0,
          sigmaY: blurSigma ?? 10.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(opacity ?? 0.7),
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            border: border ?? Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              child: Padding(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to make it easy to convert existing ShadButton usage
extension GlassButtonExtension on ShadButton {
  Widget toGlass({
    double? opacity,
    double? blurSigma,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return GlassButton(
      opacity: opacity,
      blurSigma: blurSigma,
      borderRadius: borderRadius,
      border: border,
      onPressed: () {
        // Extract onPressed from original button if possible
        // This is a simplified approach - in practice you might need to pass it explicitly
      },
      child: this,
    );
  }
}
