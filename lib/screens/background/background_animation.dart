import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide Image;

import 'components/sign_in_dialog.dart';

class Backgrounds_animation extends StatefulWidget {
    Backgrounds_animation({required this.child});
    Widget child;

  @override
  State<Backgrounds_animation> createState() => _Backgrounds_animationState();
}

class _Backgrounds_animationState extends State<Backgrounds_animation>
    with TickerProviderStateMixin {
  late RiveAnimationController _btnAnimationController;
  late AnimationController _splineController;
  late AnimationController _rotationController;
  late Animation<double> _splineAnimation;
  late Animation<double> _rotationAnimation;

  bool isShowSignInDialog = false;

  @override
  void initState() {
    _btnAnimationController = OneShotAnimation(
      "active",
      autoplay: false,
    );

    // Initialize spline animation
    _splineController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _splineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _splineController,
      curve: Curves.easeInOut,
    ));

    // Initialize rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159, // Full rotation in radians
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    super.initState();
  }

  @override
  void dispose() {
    _btnAnimationController.dispose();
    _splineController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          
          // Animated Spline background
          AnimatedBuilder(
            animation: Listenable.merge([_splineAnimation, _rotationAnimation]),
            builder: (context, child) {
              return Positioned(
                width: MediaQuery.of(context).size.width * 1.7,
                left: 100 + (50 * _splineAnimation.value * (1 - 2 * (_splineAnimation.value % 0.5))),
                bottom: 100 + (30 * _splineAnimation.value * (1 - 2 * (_splineAnimation.value % 0.5))),
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 0.05, // Subtle rotation
                  child: Opacity(
                    opacity: 0.3 + (0.1 * _splineAnimation.value),
                    child: Image.asset(
                      "Backgrounds/Spline.png",
                    ),
                  ),
                ),
              );
            },
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const SizedBox(),
            ),),

          const RiveAnimation.asset(
            "Backgrounds/RiveAssets/shapes.riv", ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const SizedBox(),
              ),
            ),
        
        AnimatedPositioned(
            top: isShowSignInDialog ? -50 : 0,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            duration: const Duration(milliseconds: 260),
            child:widget.child,
        )
        
        //   AnimatedPositioned(
        //     top: isShowSignInDialog ? -50 : 0,
        //     height: MediaQuery.of(context).size.height,
        //     width: MediaQuery.of(context).size.width,
        //     duration: const Duration(milliseconds: 260),
        //     child: SafeArea(
        //       child: Padding(
        //         padding: const EdgeInsets.symmetric(horizontal: 32),
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             const Spacer(),
        //             const SizedBox(
        //               width: 260,
        //               child: Column(
        //                 children: [
        //                   Text(
        //                     "Learn design & code",
        //                     style: TextStyle(
        //                       fontSize: 60,
        //                       fontWeight: FontWeight.w700,
        //                       fontFamily: "Poppins",
        //                       height: 1.2,
        //                     ),
        //                   ),
        //                   SizedBox(height: 16),
        //                   Text(
        //                     "Don’t skip design. Learn design and code, by building real apps with Flutter and Swift. Complete courses about the best tools.",
        //                   ),
        //                 ],
        //               ),
        //             ),
        //             const Spacer(flex: 2),
        //             AnimatedBtn(
        //               btnAnimationController: _btnAnimationController,
        //               press: () {
        //                 _btnAnimationController.isActive = true;

        //                 Future.delayed(
        //                   const Duration(milliseconds: 800),
        //                   () {
        //                     setState(() {
        //                       isShowSignInDialog = true;
        //                     });
        //                     if (!context.mounted) return;
        //                     showCustomDialog(
        //                       context,
        //                       onValue: (_) {},
        //                     );
        //                     // showCustomDialog(
        //                     //   context,
        //                     //   onValue: (_) {
        //                     //     setState(() {
        //                     //       isShowSignInDialog = false;
        //                     //     });
        //                     //   },
        //                     // );
        //                   },
        //                 );
        //               },
        //             ),
        //             const Padding(
        //               padding: EdgeInsets.symmetric(vertical: 24),
        //               child: Text(
        //                   "Purchase includes access to 30+ courses, 240+ premium tutorials, 120+ hours of videos, source files and certificates."),
        //             )
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        
        ],
      ),
    );
  }
}
