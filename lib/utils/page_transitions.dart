import 'package:flutter/material.dart';

/// Page Transition Animations Utility
///
/// Provides smooth, professional page transitions for the entire app.
/// Use these instead of Navigator.push for better UX.

class PageTransitions {
  /// Slide transition from right to left (default)
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Slide transition from bottom to top
  static Route<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Fade transition
  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Scale transition (zoom in effect)
  static Route<T> scale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Combined slide and fade transition (modern look)
  static Route<T> slideAndFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.3, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var slideTween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var slideAnimation = animation.drive(slideTween);

        var fadeTween = Tween<double>(begin: 0.0, end: 1.0);
        var fadeAnimation = animation.drive(fadeTween);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Rotation and scale transition (special effect)
  static Route<T> rotateAndScale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return RotationTransition(
          turns: Tween<double>(
            begin: 0.02,
            end: 0.0,
          ).animate(curvedAnimation),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: curvedAnimation,
              child: child,
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// No animation (instant transition)
  static Route<T> instant<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
      transitionDuration: Duration.zero,
    );
  }

  /// Modal/Dialog style transition (scale from center)
  static Route<T> modal<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      opaque: false,
      barrierColor: Colors.black54,
    );
  }
}

/// Extension method for easy navigation with animations
extension AnimatedNavigation on BuildContext {
  /// Navigate with slide from right animation
  Future<T?> pushWithSlide<T>(Widget page) {
    return Navigator.of(this).push<T>(PageTransitions.slideFromRight(page));
  }

  /// Navigate with slide from bottom animation
  Future<T?> pushWithSlideUp<T>(Widget page) {
    return Navigator.of(this).push<T>(PageTransitions.slideFromBottom(page));
  }

  /// Navigate with fade animation
  Future<T?> pushWithFade<T>(Widget page) {
    return Navigator.of(this).push<T>(PageTransitions.fade(page));
  }

  /// Navigate with scale animation
  Future<T?> pushWithScale<T>(Widget page) {
    return Navigator.of(this).push<T>(PageTransitions.scale(page));
  }

  /// Navigate with slide and fade animation (recommended default)
  Future<T?> pushAnimated<T>(Widget page) {
    return Navigator.of(this).push<T>(PageTransitions.slideAndFade(page));
  }

  /// Navigate with modal animation
  Future<T?> pushModal<T>(Widget page) {
    return Navigator.of(this).push<T>(PageTransitions.modal(page));
  }

  /// Replace current route with animation
  Future<T?> pushReplacementAnimated<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement<T, TO>(
      PageTransitions.slideAndFade(page),
    );
  }

  /// Push and remove all previous routes with animation
  Future<T?> pushAndRemoveUntilAnimated<T>(
    Widget page,
    bool Function(Route<dynamic>) predicate,
  ) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      PageTransitions.slideAndFade(page),
      predicate,
    );
  }
}

/// Material 3 style transitions
class Material3Transitions {
  /// Shared axis transition (Material 3 recommendation)
  static Route<T> sharedAxisX<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.1, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubicEmphasized;

        var slideTween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var slideAnimation = animation.drive(slideTween);

        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        );
        var fadeAnimation = animation.drive(fadeTween);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Fade through transition (Material 3 recommendation)
  static Route<T> fadeThrough<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubicEmphasized;

        return FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
