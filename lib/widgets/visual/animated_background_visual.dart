import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

class AnimatedBackgroundVisual extends StatefulWidget {
  final Widget child;
  final bool isForScreen; // Whether this is for a full screen or just content
  final bool enableAnimation; // Control whether to show animations

  const AnimatedBackgroundVisual({
    super.key,
    required this.child,
    this.isForScreen = false,
    this.enableAnimation = true,
  });

  @override
  State<AnimatedBackgroundVisual> createState() => _AnimatedBackgroundVisualState();
}

class _AnimatedBackgroundVisualState extends State<AnimatedBackgroundVisual>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _pulseController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation for gradient colors
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    // Animation for pulsing effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.05,
      end: 0.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_gradientAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Stack(
          children: [
            // Animated gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(
                      0.03 + (_gradientAnimation.value * 0.02)
                    ),
                    Theme.of(context).colorScheme.secondary.withOpacity(
                      0.03 + (_gradientAnimation.value * 0.02)
                    ),
                    Theme.of(context).colorScheme.tertiary.withOpacity(
                      0.02 + (_gradientAnimation.value * 0.01)
                    ),
                  ],
                ),
              ),
            ),
            // Add a subtle background pattern/image if it exists
            Positioned(
              width: MediaQuery.of(context).size.width * 1.7,
              left: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.2 + (_pulseAnimation.value * 0.1),
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
            if (widget.enableAnimation)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1 + (_pulseAnimation.value * 0.05),
                  child: rive.RiveAnimation.asset(
                    "Backgrounds/RiveAssets/shapes.riv",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            // Add floating particles effect
            if (widget.enableAnimation)
              Positioned.fill(
                child: _buildFloatingParticles(),
              ),
            // Backdrop filter for blur effect (only on platforms that support it)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            // Content on top
            if (widget.isForScreen)
              SafeArea(child: widget.child)
            else
              widget.child,
          ],
        );
      },
    );
  }

  Widget _buildFloatingParticles() {
    return CustomPaint(
      painter: ParticlePainter(_pulseAnimation.value),
      size: Size.infinite,
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw some floating particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width * 0.1 * (i + 1)) + 
                (animationValue * 50 * (i % 2 == 0 ? 1 : -1));
      final y = (size.height * 0.1 * (i + 1)) + 
                (animationValue * 30 * (i % 3 == 0 ? 1 : -1));
      
      final radius = 2.0 + (animationValue * 3.0);
      
      canvas.drawCircle(
        Offset(
          x % size.width,
          y % size.height,
        ),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
