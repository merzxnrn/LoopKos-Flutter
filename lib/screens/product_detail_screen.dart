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

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Future<Map<String, dynamic>> Function(String id)? loader;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.loader,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  bool _hasError = false;
  int _imgIdx = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _load();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final fetch = widget.loader ?? ApiService.getProduct;
      final p = await fetch(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = p;
        _imgIdx = 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (widget.loader != null) {
        setState(() {
          _product = null;
          _hasError = true;
          _isLoading = false;
        });
        return;
      }
      final mock = MockData.products
          .where((p) => p['id'] == widget.productId)
          .firstOrNull;
      setState(() {
        _product = mock;
        _imgIdx = 0;
        _isLoading = false;
      });
    }
  }

  CartItem _buildCartItem(Map<String, dynamic> product) {
    final images = List<String>.from(product['imageUrls'] ?? []);
    final rawSellerName =
        (product['sellerName'] ?? product['seller']?['name'] ?? '').toString();
    final sellerId = CartProvider.resolveSellerId(
      sellerId: product['sellerId'] ?? product['seller']?['id'],
      sellerName: rawSellerName,
      itemId: product['id'],
    );
    final sellerName =
        rawSellerName.trim().isNotEmpty ? rawSellerName.trim() : 'Penjual';

    return CartItem(
      id: product['id'].toString(),
      name: (product['name'] ?? '').toString(),
      price: (product['price'] as num?)?.toInt() ?? 0,
      category: (product['category'] ?? 'lainnya').toString(),
      imageUrls: images,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerPhone: product['sellerPhone']?.toString(),
      condition: (product['condition'] ?? 'Baik').toString(),
      location: (product['location'] ?? '').toString(),
    );
  }

  Future<void> _handleAddToCart(
    Map<String, dynamic> product, {
    required bool goToCheckout,
  }) async {
    final cart = context.read<CartProvider>();
    final productId = product['id'].toString();
    final inCart = cart.items.any((i) => i.id == productId);

    if (!inCart) {
      final item = _buildCartItem(product);
      if (cart.hasDifferentSeller(item.sellerId)) {
        final currentSeller = cart.items.first.sellerName;
        final confirmed = await confirmReplaceCartDialog(
          context,
          currentSeller: currentSeller,
          newSeller: item.sellerName,
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
                  child: Text('${product['name']} ditambahkan ke keranjang'),
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

  void _openAskSellerSheet(Map<String, dynamic> product) {
    final sellerName =
        (product['sellerName'] ?? product['seller']?['name'] ?? 'Penjual')
            .toString();
    final sellerPhone = product['sellerPhone']?.toString().trim();
    final sellerCampus = (product['sellerCampus'] ?? '').toString();
    final location = (product['location'] ?? '').toString();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hubungi Penjual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryText.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            sellerName.isNotEmpty
                                ? sellerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sellerName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (sellerCampus.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                sellerCampus,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (location.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                location,
                                style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (sellerPhone != null && sellerPhone.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetCtx).pop();
                            launchExternalUri(
                              context,
                              Uri.parse('tel:$sellerPhone'),
                              failureMessage:
                                  'Tidak dapat membuka aplikasi telepon.',
                            );
                          },
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          label: const Text('Telepon'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetCtx).pop();
                            final wa =
                                AppConstants.formatPhoneForWa(sellerPhone);
                            final msg = Uri.encodeComponent(
                              'Halo, saya tertarik dengan ${product['name']} di LoopKos (ID: ${product['id']}). Apakah masih tersedia?',
                            );
                            launchExternalUri(
                              context,
                              Uri.parse('https://wa.me/$wa?text=$msg'),
                              external: true,
                              failureMessage: 'Tidak dapat membuka WhatsApp.',
                            );
                          },
                          icon: const Icon(Icons.chat_outlined, size: 18),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            backgroundColor: AppColors.whatsapp,
                            foregroundColor: AppColors.background,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primaryText,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nomor telepon penjual belum tersedia. Silakan lanjutkan pemesanan melalui keranjang.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = watchAuthOrNull(context)?.user;
    final cart = context.watch<CartProvider>();

    if (_isLoading) {
      return const AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: LoopKosHeader(
            currentRoute: '/product',
            title: 'Detail Produk',
            showBack: true,
          ),
          body: _ProductDetailLoadingSkeleton(),
        ),
      );
    }

    if (_hasError) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const LoopKosHeader(
            currentRoute: '/product',
            title: 'Detail Produk',
            showBack: true,
          ),
          body: ErrorStateView(
            message: 'Gagal memuat detail produk. Silakan coba lagi.',
            onRetry: _load,
          ),
        ),
      );
    }

    if (_product == null) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const LoopKosHeader(
            currentRoute: '/product',
            title: 'Detail Produk',
            showBack: true,
          ),
          body: EmptyStateView(
            icon: Icons.inventory_2_outlined,
            title: 'Produk tidak ditemukan',
            subtitle: 'Barang ini mungkin sudah terjual atau dihapus.',
            actionLabel: 'Kembali',
            onAction: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
    }

    final product = _product!;
    final images = List<String>.from(product['imageUrls'] ?? []);
    final inCart = cart.items.any((i) => i.id == product['id'].toString());
    final sellerId =
        (product['sellerId'] ?? product['seller']?['id'] ?? '').toString();
    final isOwnProduct =
        user != null && sellerId.isNotEmpty && user.id == sellerId;
    final sellerName =
        (product['sellerName'] ?? product['seller']?['name'] ?? 'Penjual')
            .toString();
    final sellerCampus = (product['sellerCampus'] ?? '').toString();
    final location = (product['location'] ?? '').toString();
    final category = (product['category'] ?? 'lainnya').toString();
    final categoryIcon = AppConstants.categoryIconData(category);
    final condition = (product['condition'] ?? 'Baik').toString();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const LoopKosHeader(
          currentRoute: '/product',
          title: 'Detail Produk',
          showBack: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Swipeable Gallery
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (images.isNotEmpty)
                        PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (i) => setState(() => _imgIdx = i),
                          itemBuilder: (_, i) => Image.network(
                            images[i],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const ShimmerBox(radius: 0);
                            },
                            errorBuilder: (_, _, _) => Center(
                              child: Icon(
                                categoryIcon,
                                size: 64,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: AppColors.surfaceElevated,
                          child: Center(
                            child: Icon(
                              categoryIcon,
                              size: 72,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: StatusBadge(
                          label: condition,
                          color: AppColors.success,
                          icon: Icons.verified_outlined,
                        ),
                      ),
                      if (images.isNotEmpty)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.background.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '${_imgIdx + 1}/${images.length}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 14,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (i) {
                              final active = i == _imgIdx;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: active ? 18 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.primaryText
                                      : AppColors.mutedForeground
                                          .withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (images.length > 1) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 68,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final selected = i == _imgIdx;
                      return Material(
                        color: AppColors.surfaceElevated,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primaryText
                                : AppColors.border,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            setState(() => _imgIdx = i);
                            if (_pageController.hasClients) {
                              _pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          child: SizedBox(
                            width: 68,
                            height: 68,
                            child: Image.network(
                              images[i],
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const ShimmerBox(radius: 0);
                              },
                              errorBuilder: (_, _, _) => Center(
                                child: Icon(
                                  categoryIcon,
                                  size: 24,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Condition & Category Pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categoryIcon,
                          size: 14,
                          color: AppColors.primaryText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: condition,
                    color: AppColors.primary,
                    icon: Icons.verified_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                (product['name'] ?? '').toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product['rating'] ?? 4.5}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product['reviews'] ?? 0} ulasan)',
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: AppColors.priceGreen,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${product['stock'] ?? 1} tersedia',
                        style: const TextStyle(
                          color: AppColors.priceGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 18),

              // Elevated Price Box
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HARGA',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.formatRp((product['price'] as num?) ?? 0),
                      style: const TextStyle(
                        color: AppColors.priceGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Description Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (product['description'] ?? '-').toString(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Seller Profile Card
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          sellerName.isNotEmpty
                              ? sellerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  sellerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (product['sellerVerified'] == true) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: AppColors.primaryText,
                                ),
                              ],
                            ],
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              location,
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (sellerCampus.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              sellerCampus,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Community Reviews Section
              const Text(
                'CONTOH ULASAN KOMUNITAS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedForeground,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ilustrasi pengalaman transaksi sesama mahasiswa di LoopKos.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 10),
              ...MockData.reviews.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                r.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.warning,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${r.rating}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.comment,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.date,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xCC060E1D),
            border: Border(top: BorderSide(color: AppColors.borderGlass)),
          ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: isOwnProduct
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.block_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Barang milikmu sendiri — kamu tidak dapat membelinya.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale =
                          MediaQuery.textScalerOf(context).scale(1.0);
                      final stackCta = constraints.maxWidth < 330 ||
                          (constraints.maxWidth < 380 && textScale > 1.15);

                      final askButton = OutlinedButton.icon(
                        onPressed: () => _openAskSellerSheet(product),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                        ),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Tanya Penjual',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                        ),
                      );

                      final cartButton = IconButton(
                        onPressed: () =>
                            _handleAddToCart(product, goToCheckout: false),
                        tooltip: inCart
                            ? 'Sudah di keranjang'
                            : 'Tambah ke keranjang',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: inCart
                              ? AppColors.success.withValues(alpha: 0.18)
                              : AppColors.surfaceElevated,
                          foregroundColor: inCart
                              ? AppColors.priceGreen
                              : AppColors.primaryText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: inCart
                                  ? AppColors.success.withValues(alpha: 0.5)
                                  : AppColors.border,
                            ),
                          ),
                        ),
                        icon: Icon(
                          inCart
                              ? Icons.shopping_cart_checkout_rounded
                              : Icons.add_shopping_cart_rounded,
                          size: 20,
                        ),
                      );

                      final buyButton = ElevatedButton.icon(
                        onPressed: () =>
                            _handleAddToCart(product, goToCheckout: true),
                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 18,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            inCart ? 'Lanjut ke Checkout' : 'Beli Sekarang',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
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
                      );

                      if (stackCta) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: askButton),
                                const SizedBox(width: 8),
                                cartButton,
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(width: double.infinity, child: buyButton),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(flex: 2, child: askButton),
                          const SizedBox(width: 8),
                          cartButton,
                          const SizedBox(width: 8),
                          Expanded(flex: 3, child: buyButton),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
      ),
    );
  }
}

class _ProductDetailLoadingSkeleton extends StatelessWidget {
  const _ProductDetailLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AspectRatio(
            aspectRatio: 1,
            child: ShimmerBox(radius: 18),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              ShimmerBox(height: 28, width: 96, radius: 999),
              SizedBox(width: 8),
              ShimmerBox(height: 28, width: 110, radius: 999),
            ],
          ),
          SizedBox(height: 12),
          ShimmerBox(height: 24, width: 240, radius: 6),
          SizedBox(height: 10),
          ShimmerBox(height: 16, width: 180, radius: 6),
          SizedBox(height: 18),
          ShimmerBox(height: 82, width: double.infinity, radius: 14),
          SizedBox(height: 16),
          ShimmerBox(height: 100, width: double.infinity, radius: 16),
        ],
      ),
    );
  }
}
