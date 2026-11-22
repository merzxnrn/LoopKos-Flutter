import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/cart_provider.dart';
import 'main_shell.dart';

class LoopKosHeader extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;
  final String? title;
  final bool showBack;

  const LoopKosHeader({
    super.key,
    this.currentRoute = '/home',
    this.title,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  int _readCartCountSafely(BuildContext context) {
    try {
      return context.watch<CartProvider>().count;
    } on ProviderNotFoundException {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = _readCartCountSafely(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final hasTitle = title != null && title!.trim().isNotEmpty;

    return Container(
      height: 64 + topPadding,
      padding: EdgeInsets.only(top: topPadding, left: showBack ? 4 : 16, right: 8),
      decoration: BoxDecoration(
        color: const Color(0xB8060E1D),
        border: const Border(bottom: BorderSide(color: AppColors.borderGlass)),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Kembali',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: hasTitle
                ? Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => MainShell.switchTab(context, 0),
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1,
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                                children: [
                                  TextSpan(text: 'Loop', style: TextStyle(color: AppColors.textPrimary)),
                                  TextSpan(text: 'Kos', style: TextStyle(color: AppColors.primaryText)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  if (currentRoute == '/checkout') return;
                  Navigator.of(context).pushNamed('/checkout');
                },
                tooltip: 'Keranjang',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: currentRoute == '/checkout'
                      ? AppColors.surfaceElevated
                      : Colors.transparent,
                  foregroundColor: currentRoute == '/checkout'
                      ? AppColors.primaryText
                      : AppColors.textSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.shopping_cart_outlined, size: 22),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        cartCount > 9 ? '9+' : '$cartCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
