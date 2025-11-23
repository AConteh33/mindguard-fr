import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

class BackgroundVisual extends StatelessWidget {
  final Widget child;
  final bool isForScreen; // Whether this is for a full screen or just content

  const BackgroundVisual({
    super.key,
    required this.child,
    this.isForScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Create a subtle gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
        ),
        // Add a subtle background pattern/image if it exists
        Positioned(
          width: MediaQuery.of(context).size.width * 1.7,
          left: 100,
          bottom: 100,
          child: Opacity(
            opacity: 0.3, // Make it very subtle
            child: Image.asset(
              "Backgrounds/Spline.png",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // If the image fails to load, show nothing
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        // Add animated Rive shapes in the background
        Positioned.fill(
          child: Opacity(
            opacity: 0.15, // Very subtle animation
            child: rive.RiveAnimation.asset(
              "Backgrounds/RiveAssets/shapes.riv",
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Backdrop filter for blur effect (only on platforms that support it)
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ),
        // Content on top
        if (isForScreen)
          SafeArea(child: child)
        else
          child,
      ],
    );
  }
}