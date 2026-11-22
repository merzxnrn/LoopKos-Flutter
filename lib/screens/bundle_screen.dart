import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/mock_data.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_background.dart';
import '../widgets/loopkos_header.dart';
import '../widgets/ui_kit.dart';

class BundleScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function()? loader;

  const BundleScreen({super.key, this.loader});

  @override
  State<BundleScreen> createState() => _BundleScreenState();
}

class _BundleScreenState extends State<BundleScreen> {
  List<Map<String, dynamic>> _bundles = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final fetch = widget.loader ?? ApiService.getBundles;
      final data = await fetch();
      if (!mounted) return;
      setState(() {
        _bundles = widget.loader != null
            ? data
            : (data.isNotEmpty ? data : MockData.bundles);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (widget.loader != null) {
        setState(() {
          _bundles = [];
          _hasError = true;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _bundles = MockData.bundles;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleBundleAction(
    Map<String, dynamic> bundle, {
    required bool goToCheckout,
  }) async {
    final cart = context.read<CartProvider>();
    final bundleId = bundle['id'].toString();
    final inCart = cart.items.any((i) => i.id == bundleId);

    if (!inCart) {
      final items = List<Map<String, dynamic>>.from(bundle['items'] ?? []);
      final imageUrls = List<String>.from(bundle['imageUrls'] ?? []);
      final rawSellerName =
          (bundle['sellerName'] ?? bundle['seller']?['name'] ?? '').toString();
      final sellerId = CartProvider.resolveSellerId(
        sellerId: bundle['sellerId'] ?? bundle['seller']?['id'],
        sellerName: rawSellerName,
        itemId: bundleId,
      );
      final sellerName =
          rawSellerName.trim().isNotEmpty ? rawSellerName.trim() : 'Penjual';

      final item = CartItem(
        id: bundleId,
        name: (bundle['name'] ?? '').toString(),
        price: (bundle['totalPrice'] as num?)?.toInt() ?? 0,
        discount: (bundle['discount'] as num?)?.toInt() ?? 0,
        category: 'bundle',
        imageUrls: imageUrls,
        sellerId: sellerId,
        sellerName: sellerName,
        sellerPhone: bundle['sellerPhone']?.toString(),
        condition: 'Bundle',
        location: (bundle['location'] ?? '').toString(),
        isBundle: true,
        bundleItems: items,
      );

      if (cart.hasDifferentSeller(item.sellerId)) {
        final currentSeller = cart.items.first.sellerName;
        final confirmed = await confirmReplaceCartDialog(
          context,
          currentSeller: currentSeller,
          newSeller: sellerName,
        );
        if (!confirmed || !mounted) return;
        cart.replaceWithItem(item);
      } else {
        cart.addItem(item);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.priceGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${bundle['name']} ditambahkan ke keranjang'),
                ),
              ],
            ),
          ),
        );
    }

    if (goToCheckout && mounted) {
      Navigator.of(context).pushNamed('/checkout');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const LoopKosHeader(currentRoute: '/bundle'),
        body: RefreshIndicator(
          color: AppColors.primaryText,
          backgroundColor: AppColors.card,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BundleHeroBanner(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: _isLoading
                      ? const _BundleLoadingSkeleton()
                      : _hasError
                          ? ErrorStateView(
                              message:
                                  'Gagal memuat daftar bundle. Periksa koneksi lalu coba lagi.',
                              onRetry: _load,
                            )
                          : _bundles.isEmpty
                              ? EmptyStateView(
                                  icon: Icons.layers_outlined,
                                  title: 'Belum ada bundle tersedia',
                                  subtitle:
                                      'Paket kos hemat dari kakak tingkat akan muncul di sini.',
                                  actionLabel: 'Muat Ulang',
                                  onAction: _load,
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ..._bundles.map((bundle) {
                                      final inCart = cart.items.any(
                                        (i) => i.id == bundle['id'].toString(),
                                      );
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: _BundleCard(
                                          bundle: bundle,
                                          inCart: inCart,
                                          onAddToCart: () =>
                                              _handleBundleAction(
                                            bundle,
                                            goToCheckout: false,
                                          ),
                                          onBuyNow: () => _handleBundleAction(
                                            bundle,
                                            goToCheckout: true,
                                          ),
                                        ),
                                      );
                                    }),
                                    const _BundleGraduateInfoCard(),
                                  ],
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BundleHeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0E1A30),
            Color(0xFF162749),
          ],
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryText.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.layers_outlined,
              color: AppColors.primaryText,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bundle Hemat',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Paket lengkap dari mahasiswa yang lulus — solusi 1-klik untuk kos kamu.',
                  style: TextStyle(
                    color: AppColors.lightBlue,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleLoadingSkeleton extends StatelessWidget {
  const _BundleLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(height: 168, width: double.infinity, radius: 0),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: 18, width: 200, radius: 6),
                    SizedBox(height: 8),
                    ShimmerBox(height: 14, width: 140, radius: 6),
                    SizedBox(height: 14),
                    ShimmerBox(height: 24, width: 120, radius: 6),
                    SizedBox(height: 14),
                    ShimmerBox(height: 48, width: double.infinity, radius: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  final Map<String, dynamic> bundle;
  final bool inCart;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const _BundleCard({
    required this.bundle,
    required this.inCart,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final total = math.max(0, (bundle['totalPrice'] as num?)?.toInt() ?? 0);
    final rawDiscount = (bundle['discount'] as num?)?.toInt() ?? 0;
    final discount = math.max(0, math.min(rawDiscount, total));
    final finalPrice = math.max(0, total - discount);
    final pct =
        (total > 0 && discount > 0) ? ((discount / total) * 100).round() : 0;
    final items = List<Map<String, dynamic>>.from(bundle['items'] ?? []);
    final images = List<String>.from(bundle['imageUrls'] ?? []);
    final sellerName =
        (bundle['sellerName'] ?? bundle['seller']?['name'] ?? 'Penjual')
            .toString();
    final location = (bundle['location'] ?? '').toString();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 112,
            child: Container(
              color: AppColors.surfaceElevated,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (images.isNotEmpty)
                    Image.network(
                      images.first,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const ShimmerBox(radius: 0);
                      },
                      errorBuilder: (_, _, _) => const _BundlePlaceholderIcon(),
                    )
                  else
                    const _BundlePlaceholderIcon(),
                  if (pct > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: StatusBadge(
                        label: 'Hemat $pct%',
                        color: AppColors.success,
                        icon: Icons.local_offer_outlined,
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: AppColors.primaryText,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            sellerName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (bundle['name'] ?? '').toString(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      AppConstants.formatRp(finalPrice),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.priceGreen,
                      ),
                    ),
                    if (discount > 0) ...[
                      const SizedBox(width: 10),
                      Text(
                        AppConstants.formatRp(total),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const Divider(height: 16),
                Text(
                  '${items.length} BARANG TERMASUK',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mutedForeground,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                ...items.map((item) {
                  final catIcon = AppConstants.categoryIconData(
                    item['category']?.toString(),
                  );
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          catIcon,
                          size: 16,
                          color: AppColors.primaryText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (item['name'] ?? '').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppConstants.formatRp((item['price'] as num?) ?? 0),
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAddToCart,
                        icon: Icon(
                          inCart
                              ? Icons.check_circle_outline_rounded
                              : Icons.add_shopping_cart_rounded,
                          size: 18,
                          color: inCart
                              ? AppColors.priceGreen
                              : AppColors.primaryText,
                        ),
                        label: Text(
                          inCart ? 'Sudah di Keranjang' : 'Tambah ke Keranjang',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: inCart
                                ? AppColors.priceGreen
                                : AppColors.textPrimary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          side: BorderSide(
                            color: inCart
                                ? AppColors.success.withValues(alpha: 0.6)
                                : AppColors.border,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onBuyNow,
                        icon: const Icon(Icons.flash_on_rounded, size: 18),
                        label: const Text(
                          'Beli Langsung',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BundlePlaceholderIcon extends StatelessWidget {
  const _BundlePlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.layers_outlined,
          size: 32,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}

class _BundleGraduateInfoCard extends StatelessWidget {
  const _BundleGraduateInfoCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0E1A30),
                  Color(0xFF162749),
                ],
              ),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dari Kakak Tingkat',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Bundle ini dari mahasiswa yang sudah lulus. Mereka mewariskan perlengkapan kosnya ke kamu dengan harga lebih hemat!',
                  style: TextStyle(
                    color: AppColors.lightBlue,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.verified_outlined,
                  iconColor: AppColors.priceGreen,
                  title: 'Kondisi Terverifikasi',
                  desc: 'Setiap barang dicek sebelum ditawarkan sebagai paket',
                ),
                SizedBox(height: 10),
                _InfoTile(
                  icon: Icons.local_shipping_outlined,
                  iconColor: AppColors.primaryText,
                  title: 'Antar ke Kos',
                  desc: 'Koordinasi pengantaran langsung di area kampus',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
