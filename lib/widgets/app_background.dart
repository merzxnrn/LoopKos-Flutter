import 'package:flutter/material.dart';
import '../core/theme.dart';

class _AppBackgroundScope extends InheritedWidget {
  const _AppBackgroundScope({required super.child});

  static bool hasAncestor(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppBackgroundScope>() != null;
  }

  @override
  bool updateShouldNotify(covariant _AppBackgroundScope oldWidget) => false;
}

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool forcePaint;

  const AppBackground({
    super.key,
    required this.child,
    this.forcePaint = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!forcePaint && _AppBackgroundScope.hasAncestor(context)) {
      return child;
    }

    return _AppBackgroundScope(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.background),
          Positioned.fill(
            child: Image.asset(
              'assets/images/app_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      const Color(0xFF040D1C).withValues(alpha: 0.42),
                      const Color(0xFF050C1A).withValues(alpha: 0.22),
                      const Color(0xFF030710).withValues(alpha: 0.34),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
