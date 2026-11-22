import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_background.dart';
import '../widgets/loopkos_header.dart';
import '../widgets/main_shell.dart';
import '../widgets/ui_kit.dart';

class MyListingsScreen extends StatefulWidget {
  final Future<
      ({
        List<Map<String, dynamic>> products,
        List<Map<String, dynamic>> sellerTxs,
      })> Function()? loader;

  const MyListingsScreen({super.key, this.loader});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _sellerTxs = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MyListingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loader != widget.loader) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      if (widget.loader != null) {
        final data = await widget.loader!();
        if (!mounted) return;
        setState(() {
          _products = data.products;
          _sellerTxs = data.sellerTxs;
          _isLoading = false;
        });
        return;
      }

      final auth = readAuthOrNull(context);
      if (auth == null || auth.accessToken == null || auth.user == null) {
        if (mounted) {
          setState(() {
            _products = [];
            _sellerTxs = [];
            _isLoading = false;
          });
        }
        return;
      }

      final results = await Future.wait([
        ApiService.getProducts(sellerId: auth.user!.id),
        ApiService.getTransactions(auth.accessToken!, role: 'seller'),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0];
        _sellerTxs = results[1];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String id) async {
    final token = readAuthOrNull(context)?.accessToken;
    if (token == null) return;
    try {
      await ApiService.deleteProduct(token, id);
      if (!mounted) return;
      setState(() => _products.removeWhere((p) => p['id'].toString() == id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang?'),
        content: const Text(
          'Barang ini akan dihapus permanen dari daftar jualan kamu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteProduct(product['id'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _sellerTxs
        .where((t) => t['status'] == 'completed')
        .fold<int>(0, (s, t) => s + ((t['totalPrice'] as num?)?.toInt() ?? 0));
    final pendingVerif =
        _sellerTxs.where((t) => t['status'] == 'payment_uploaded').length;
    final completedTxs =
        _sellerTxs.where((t) => t['status'] == 'completed').length;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const LoopKosHeader(
          currentRoute: '/my-listings',
          title: 'Toko Saya',
          showBack: true,
        ),
        body: RefreshIndicator(
          color: AppColors.primaryText,
          backgroundColor: AppColors.card,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PUSAT PENJUAL',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kelola Jualan',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Pantau stok barang dan verifikasi pesanan',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => MainShell.switchTab(context, 2),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.65,
                  children: [
                    _statCard(
                      'Barang Terdaftar',
                      '${_products.length}',
                      AppColors.primaryText,
                    ),
                    _statCard(
                      'Pendapatan',
                      AppConstants.formatRp(totalRevenue),
                      AppColors.priceGreen,
                    ),
                    _statCard(
                      'Pesanan Selesai',
                      '$completedTxs',
                      AppColors.primaryText,
                    ),
                    _statCard(
                      'Perlu Verifikasi',
                      '$pendingVerif',
                      pendingVerif > 0
                          ? AppColors.warning
                          : AppColors.mutedForeground,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (pendingVerif > 0) ...[
                  AppCard(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderColor: AppColors.primaryText.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.primaryText,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$pendingVerif bukti transfer menunggu verifikasi.',
                            style: const TextStyle(
                              color: AppColors.lightBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => MainShell.switchTab(context, 3),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          child: const Text('Verifikasi'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'Barang Terdaftar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Column(
                    children: [
                      ShimmerBox(height: 92, radius: 16),
                      SizedBox(height: 12),
                      ShimmerBox(height: 92, radius: 16),
                    ],
                  )
                else if (_hasError)
                  ErrorStateView(
                    message:
                        'Gagal memuat data toko. Periksa koneksi lalu coba lagi.',
                    onRetry: _load,
                  )
                else if (_products.isEmpty)
                  EmptyStateView(
                    icon: Icons.inventory_2_outlined,
                    title: 'Belum ada barang terdaftar',
                    subtitle:
                        'Tambahkan barang kos yang sudah tidak terpakai agar cepat laku.',
                    actionLabel: 'Daftarkan Barang Pertama',
                    onAction: () => MainShell.switchTab(context, 2),
                  )
                else
                  ..._products.map((p) {
                    final images = List<String>.from(p['imageUrls'] ?? []);
                    final category = p['category']?.toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => Navigator.of(context).pushNamed(
                          '/product',
                          arguments: p['id'].toString(),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: images.isNotEmpty
                                  ? Image.network(
                                      images.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Icon(
                                        AppConstants.categoryIconData(category),
                                        color: AppColors.primaryText,
                                        size: 28,
                                      ),
                                    )
                                  : Icon(
                                      AppConstants.categoryIconData(category),
                                      color: AppColors.primaryText,
                                      size: 28,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (p['name'] ?? '').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppConstants.formatRp(
                                      (p['price'] as num?) ?? 0,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.priceGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${p['condition'] ?? 'Baik'} · Stok: ${p['stock'] ?? 1}',
                                    style: const TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _confirmDelete(p),
                              tooltip: 'Hapus barang',
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              style: IconButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFF87171),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
