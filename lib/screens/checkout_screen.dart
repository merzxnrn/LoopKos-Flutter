import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_background.dart';
import '../widgets/loopkos_header.dart';
import '../widgets/main_shell.dart';
import '../widgets/ui_kit.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _deliveryMethod = 'pickup';
  late final TextEditingController _addressCtrl;
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final campus = readAuthOrNull(context)?.user?.campus ?? '';
    _addressCtrl = TextEditingController(text: campus);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _hasMixedSellers(CartProvider cart) {
    if (cart.items.length <= 1) return false;
    final sellers = cart.items.map((i) {
      final id = i.sellerId.trim();
      if (id.isNotEmpty) return id;
      return CartProvider.resolveSellerId(
        sellerName: i.sellerName,
        itemId: i.id,
      );
    }).toSet();
    return sellers.length > 1;
  }

  Future<void> _handleCheckout() async {
    final auth = readAuthOrNull(context);
    final cart = context.read<CartProvider>();

    if (auth == null || auth.accessToken == null || auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamu harus masuk terlebih dahulu.')),
      );
      return;
    }
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang kamu masih kosong.')),
      );
      return;
    }
    if (_hasMixedSellers(cart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang hanya dapat berisi barang dari satu penjual.'),
        ),
      );
      return;
    }
    if (_deliveryMethod == 'courier' && _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi alamat pengiriman terlebih dahulu.')),
      );
      return;
    }

    final deliveryFee = _deliveryMethod == 'courier' ? 15000 : 0;
    final total = cart.totalPrice + deliveryFee;

    setState(() => _isSubmitting = true);
    try {
      final first = cart.items.first;
      final tx = await ApiService.createTransaction(auth.accessToken!, {
        'items': cart.items
            .map((i) => {
                  'id': i.id,
                  'name': i.name,
                  'price': i.price,
                  'discount': i.discount,
                  'imageUrl': i.imageUrls.isNotEmpty ? i.imageUrls.first : null,
                  'category': i.category,
                  'isBundle': i.isBundle,
                })
            .toList(),
        'sellerId': first.sellerId,
        'sellerName': first.sellerName,
        'sellerPhone': first.sellerPhone,
        'totalPrice': total,
        'deliveryMethod': _deliveryMethod,
        'deliveryAddress':
            _deliveryMethod == 'courier' ? _addressCtrl.text.trim() : '',
        'deliveryFee': deliveryFee,
        'notes': _notesCtrl.text.trim(),
      });

      cart.clearCart();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil dibuat')),
      );
      Navigator.of(context).pushReplacementNamed(
        '/payment',
        arguments: tx['id'].toString(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuat pesanan: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final deliveryFee = _deliveryMethod == 'courier' ? 15000 : 0;
    final total = cart.totalPrice + deliveryFee;

    if (cart.items.isEmpty) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const LoopKosHeader(
            currentRoute: '/checkout',
            title: 'Checkout',
            showBack: true,
          ),
          body: EmptyStateView(
            icon: Icons.shopping_cart_outlined,
            title: 'Keranjang Kosong',
            subtitle: 'Tambahkan barang dari beranda atau bundle sebelum melakukan checkout.',
            actionLabel: 'Mulai Belanja',
            onAction: () => MainShell.switchTab(context, 0),
          ),
        ),
      );
    }

    final primarySeller = cart.items.first;
    final mixedSellers = _hasMixedSellers(cart);
    final sellerInitial = primarySeller.sellerName.trim().isNotEmpty
        ? primarySeller.sellerName.trim()[0].toUpperCase()
        : 'P';

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const LoopKosHeader(
          currentRoute: '/checkout',
          title: 'Checkout',
          showBack: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'PEMBELIAN',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tinjau Pesanan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Periksa kembali barang dan metode pengiriman kamu',
                style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (mixedSellers) ...[
                AppCard(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderColor: AppColors.warning.withValues(alpha: 0.45),
                  padding: const EdgeInsets.all(14),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Keranjang berisi barang dari lebih dari satu penjual. Hapus sebagian barang agar hanya tersisa satu penjual sebelum checkout.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Ringkasan Pesanan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (int idx = 0; idx < cart.items.length; idx++) ...[
                      if (idx > 0) const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: cart.items[idx].imageUrls.isNotEmpty
                                  ? Image.network(
                                      cart.items[idx].imageUrls.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Icon(
                                        AppConstants.categoryIconData(
                                          cart.items[idx].category,
                                        ),
                                        color: AppColors.primaryText,
                                        size: 26,
                                      ),
                                    )
                                  : Icon(
                                      AppConstants.categoryIconData(
                                        cart.items[idx].category,
                                      ),
                                      color: AppColors.primaryText,
                                      size: 26,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cart.items[idx].name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cart.items[idx].sellerName,
                                    style: const TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppConstants.formatRp(
                                      cart.items[idx].price -
                                          cart.items[idx].discount,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.priceGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  cart.removeItem(cart.items[idx].id),
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
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Metode Pengiriman',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _deliveryOption(
                'pickup',
                'Ambil Sendiri (Pickup)',
                'Gratis — Ambil langsung di lokasi penjual',
              ),
              const SizedBox(height: 10),
              _deliveryOption(
                'courier',
                'Kurir / Antar ke Kos',
                'Rp 15.000 — Diantar ke alamat kos kamu',
              ),
              if (_deliveryMethod == 'courier') ...[
                const SizedBox(height: 14),
                const Text(
                  'Alamat Pengiriman',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Jl. Margonda Raya No. 42, Depok',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Catatan untuk Penjual (opsional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Tulis waktu pengambilan atau detail tambahan...',
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Rincian Harga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal (${cart.items.length} barang)',
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          AppConstants.formatRp(cart.totalPrice),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ongkos Kirim',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          deliveryFee == 0
                              ? 'Gratis'
                              : AppConstants.formatRp(deliveryFee),
                          style: TextStyle(
                            color: deliveryFee == 0
                                ? AppColors.priceGreen
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          AppConstants.formatRp(total),
                          style: const TextStyle(
                            color: AppColors.priceGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              sellerInitial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Penjual: ${primarySeller.sellerName}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppConstants.formatRp(total),
                        style: const TextStyle(
                          color: AppColors.priceGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed:
                      (_isSubmitting || mixedSellers) ? null : _handleCheckout,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(160, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? 'Memproses...' : 'Konfirmasi Pesanan',
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

  Widget _deliveryOption(String id, String label, String subtitle) {
    final active = _deliveryMethod == id;
    return AppCard(
      onTap: () => setState(() => _deliveryMethod = id),
      color: active ? AppColors.surfaceElevated : AppColors.card,
      borderColor: active ? AppColors.primaryText : AppColors.border,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Icon(
              active
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: active ? AppColors.primaryText : AppColors.mutedForeground,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
      ),
    );
  }
}
