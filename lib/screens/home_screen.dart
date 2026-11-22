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
import '../widgets/main_shell.dart';
import '../widgets/ui_kit.dart';

class HomeScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function({
    String? category,
    String? search,
  })? loader;

  const HomeScreen({super.key, this.loader});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _catalogKey = GlobalKey();

  String? _selectedCategory;
  String _searchQuery = '';
  bool _hasSearchText = false;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchTextChanged);
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchTextChanged);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final hasText = _searchCtrl.text.isNotEmpty;
    if (hasText != _hasSearchText) {
      setState(() => _hasSearchText = hasText);
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final fetch = widget.loader ?? ApiService.getProducts;
      final data = await fetch(
        category: _selectedCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) {
        setState(() {
          _products = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      var filtered = List<Map<String, dynamic>>.from(MockData.products);
      if (_selectedCategory != null) {
        filtered = filtered.where((p) => p['category'] == _selectedCategory).toList();
      }
      if (_searchQuery.isNotEmpty) {
        filtered = filtered
            .where((p) => p['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
      }
      if (mounted) {
        setState(() {
          _products = filtered;
          _isLoading = false;
        });
      }
    }
  }

  void _applySearch([String? raw]) {
    FocusScope.of(context).unfocus();
    setState(() => _searchQuery = (raw ?? _searchCtrl.text).trim());
    _fetchProducts();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    if (_searchQuery.isNotEmpty) {
      setState(() => _searchQuery = '');
      _fetchProducts();
    }
  }

  void _resetFilters() {
    _searchCtrl.clear();
    setState(() {
      _selectedCategory = null;
      _searchQuery = '';
    });
    _fetchProducts();
  }

  void _scrollToCatalog() {
    final ctx = _catalogKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        220,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = _searchQuery.isNotEmpty || _selectedCategory != null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const LoopKosHeader(currentRoute: '/home'),
        body: RefreshIndicator(
          color: AppColors.primaryText,
          backgroundColor: AppColors.card,
          onRefresh: _fetchProducts,
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Compact top greeting & impact strip
                const Text(
                  'Marketplace Preloved Mahasiswa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: const [
                    _ImpactChip(
                      icon: Icons.eco_outlined,
                      label: '10k+ Barang Terselamatkan',
                      color: AppColors.priceGreen,
                    ),
                    _ImpactChip(
                      icon: Icons.school_outlined,
                      label: '50+ Kampus',
                      color: AppColors.primaryText,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          onSubmitted: _applySearch,
                          decoration: const InputDecoration(
                            hintText: 'Cari barang kos kamu...',
                            hintStyle: TextStyle(color: AppColors.mutedForeground),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.mutedForeground,
                              size: 20,
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      if (_hasSearchText || _searchQuery.isNotEmpty)
                        IconButton(
                          onPressed: _clearSearch,
                          tooltip: 'Hapus pencarian',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.mutedForeground,
                            size: 20,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ElevatedButton(
                          onPressed: () => _applySearch(),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(56, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cari'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Compact dual quick-mode cards
                Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        onTap: _scrollToCatalog,
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                size: 18,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Satuan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Pilih per item',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        onTap: () => MainShell.switchTab(context, 1),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.layers_outlined,
                                size: 18,
                                color: AppColors.priceGreen,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bundle Hemat',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Paket 1-klik',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Catalog Header
                Row(
                  key: _catalogKey,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Hasil: "$_searchQuery"'
                                : 'Produk Tersedia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isLoading
                                ? 'Memuat katalog...'
                                : '${_products.length} barang ditemukan',
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => MainShell.switchTab(context, 2),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Jual'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(84, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _categoryChip(null, 'Semua', Icons.apps_rounded),
                      ...AppConstants.categories.map(
                        (cat) => _categoryChip(
                          cat['id'],
                          cat['name']!,
                          AppConstants.categoryIconData(cat['id']),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Product Grid / Loading / Empty
                if (_isLoading)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: 6,
                    itemBuilder: (_, _) => const _ProductShimmerCard(),
                  )
                else if (_products.isEmpty)
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: hasActiveFilter
                        ? EmptyStateView(
                            icon: Icons.search_off_rounded,
                            title: 'Barang tidak ditemukan',
                            subtitle: 'Coba kata kunci lain atau reset filter yang aktif.',
                            actionLabel: 'Reset Filter',
                            onAction: _resetFilters,
                          )
                        : EmptyStateView(
                            icon: Icons.inventory_2_outlined,
                            title: 'Belum ada produk',
                            subtitle: 'Jadilah yang pertama jual barang kos di LoopKos.',
                            actionLabel: 'Mulai Jualan',
                            onAction: () => MainShell.switchTab(context, 2),
                          ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (_, index) => _ProductGridCard(product: _products[index]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String? id, String label, IconData icon) {
    final selected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: selected ? AppColors.primaryBright : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = (id != null && _selectedCategory == id) ? null : id;
            });
            _fetchProducts();
          },
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ImpactChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductShimmerCard extends StatelessWidget {
  const _ProductShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ShimmerBox(radius: 0),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, width: 120, radius: 6),
                SizedBox(height: 6),
                ShimmerBox(height: 12, width: 85, radius: 6),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(height: 16, width: 76, radius: 6),
                    ShimmerBox(height: 36, width: 36, radius: 10),
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

class _ProductGridCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductGridCard({required this.product});

  Future<void> _handleCartAction(
    BuildContext context, {
    required CartProvider cart,
    required bool inCart,
    required List<String> imageUrls,
    required String sellerName,
    required int price,
  }) async {
    if (inCart) {
      Navigator.of(context).pushNamed('/checkout');
      return;
    }

    final rawSellerName =
        (product['sellerName'] ?? product['seller']?['name'] ?? '').toString();
    final sellerId = CartProvider.resolveSellerId(
      sellerId: product['sellerId'] ?? product['seller']?['id'],
      sellerName: rawSellerName,
      itemId: product['id'],
    );
    final item = CartItem(
      id: product['id'].toString(),
      name: (product['name'] ?? '').toString(),
      price: price,
      category: (product['category'] ?? 'lainnya').toString(),
      imageUrls: imageUrls,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerPhone: product['sellerPhone']?.toString(),
      condition: (product['condition'] ?? 'Baik').toString(),
      location: (product['location'] ?? '').toString(),
    );

    if (cart.hasDifferentSeller(item.sellerId)) {
      final currentSeller = cart.items.first.sellerName;
      final confirmed = await confirmReplaceCartDialog(
        context,
        currentSeller: currentSeller,
        newSeller: sellerName,
      );
      if (!confirmed || !context.mounted) return;
      cart.replaceWithItem(item);
    } else {
      cart.addItem(item);
    }

    if (!context.mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.items.any((i) => i.id == product['id'].toString());
    final imageUrls = List<String>.from(product['imageUrls'] ?? []);
    final sellerName =
        (product['sellerName'] ?? product['seller']?['name'] ?? 'Penjual').toString();
    final location = (product['location'] ?? product['sellerCampus'] ?? '').toString();
    final sellerLine = location.isNotEmpty ? '$sellerName · $location' : sellerName;
    final price = (product['price'] as num?)?.toInt() ?? 0;
    final categoryIcon = AppConstants.categoryIconData(product['category']?.toString());
    final condition = (product['condition'] ?? 'Baik').toString();

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          '/product',
          arguments: product['id'].toString(),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: AppColors.surfaceElevated,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrls.isNotEmpty)
                      Image.network(
                        imageUrls.first,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const ShimmerBox(radius: 0);
                        },
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(
                            categoryIcon,
                            size: 40,
                            color: AppColors.primaryText,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          categoryIcon,
                          size: 40,
                          color: AppColors.primaryText,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.primaryBright.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          condition,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (product['name'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sellerLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppConstants.formatRp(price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.priceGreen,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _handleCartAction(
                          context,
                          cart: cart,
                          inCart: inCart,
                          imageUrls: imageUrls,
                          sellerName: sellerName,
                          price: price,
                        ),
                        tooltip: inCart ? 'Lihat di keranjang' : 'Tambah ke keranjang',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: inCart
                              ? AppColors.success.withValues(alpha: 0.18)
                              : AppColors.surfaceElevated,
                          foregroundColor:
                              inCart ? AppColors.priceGreen : AppColors.primaryText,
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
