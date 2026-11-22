import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_background.dart';
import '../widgets/loopkos_header.dart';
import '../widgets/ui_kit.dart';

class TransactionsScreen extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function({required String role})?
      loader;

  const TransactionsScreen({super.key, this.loader});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _activeTab = 'buyer';
  String _filterStatus = 'all';
  List<Map<String, dynamic>> _buyerTxs = [];
  List<Map<String, dynamic>> _sellerTxs = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _uploadingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TransactionsScreen oldWidget) {
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
      late final List<List<Map<String, dynamic>>> results;
      if (widget.loader != null) {
        results = await Future.wait([
          widget.loader!(role: 'buyer'),
          widget.loader!(role: 'seller'),
        ]);
      } else {
        final token = readAuthOrNull(context)?.accessToken;
        if (token == null) {
          if (mounted) {
            setState(() {
              _buyerTxs = [];
              _sellerTxs = [];
              _isLoading = false;
            });
          }
          return;
        }
        results = await Future.wait([
          ApiService.getTransactions(token, role: 'buyer'),
          ApiService.getTransactions(token, role: 'seller'),
        ]);
      }

      if (!mounted) return;
      setState(() {
        _buyerTxs = results[0];
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

  Future<void> _uploadProofForTx(String txId) async {
    final token = readAuthOrNull(context)?.accessToken;
    if (token == null) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingId = txId);
    try {
      final upload = await ApiService.uploadFile(
        token,
        File(picked.path),
        bucket: 'proofs',
      );
      await ApiService.updateTransaction(token, txId, {
        'status': 'payment_uploaded',
        'paymentProofUrl': upload['url'],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti transfer berhasil dikirim')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengunggah: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingId = null);
    }
  }

  Future<void> _sellerAction(
    String txId,
    String newStatus, {
    String? rejectionReason,
  }) async {
    final token = readAuthOrNull(context)?.accessToken;
    if (token == null) return;
    try {
      await ApiService.updateTransaction(token, txId, {
        'status': newStatus,
        'rejectionReason': ?rejectionReason,
      });
      if (!mounted) return;
      final message = switch (newStatus) {
        'payment_verified' => 'Pembayaran dikonfirmasi',
        'completed' => 'Pesanan selesai',
        _ => 'Pembayaran ditolak',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBuyer =
        _buyerTxs.where((t) => t['status'] != 'expired').toList();
    final activeSeller =
        _sellerTxs.where((t) => t['status'] != 'expired').toList();
    final sellerPending =
        _sellerTxs.where((t) => t['status'] == 'payment_uploaded').length;

    final list = _activeTab == 'buyer' ? _buyerTxs : _sellerTxs;
    final filtered = _filterStatus == 'all'
        ? list.where((t) => t['status'] != 'expired').toList()
        : list.where((t) => t['status'] == _filterStatus).toList();

    const filters = [
      {'id': 'all', 'label': 'Semua'},
      {'id': 'pending_payment', 'label': 'Menunggu Bayar'},
      {'id': 'payment_uploaded', 'label': 'Bukti Dikirim'},
      {'id': 'payment_verified', 'label': 'Diverifikasi'},
      {'id': 'completed', 'label': 'Selesai'},
      {'id': 'cancelled', 'label': 'Dibatalkan'},
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const LoopKosHeader(
          currentRoute: '/transactions',
          title: 'Transaksi',
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
                            'RIWAYAT',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Transaksi',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Kelola pembelian dan penjualan kamu',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                      label: const Text('Muat Ulang'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _tabBtn('buyer', 'Pembelian Saya', activeBuyer.length),
                      _tabBtn(
                        'seller',
                        'Pesanan Masuk',
                        sellerPending > 0 ? sellerPending : activeSeller.length,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((f) {
                      final active = _filterStatus == f['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f['label']!),
                          selected: active,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          onSelected: (_) =>
                              setState(() => _filterStatus = f['id']!),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceElevated,
                          side: BorderSide(
                            color: active
                                ? AppColors.primaryText
                                : AppColors.border,
                          ),
                          labelStyle: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Column(
                    children: [
                      ShimmerBox(height: 168, radius: 16),
                      SizedBox(height: 14),
                      ShimmerBox(height: 168, radius: 16),
                    ],
                  )
                else if (_hasError)
                  ErrorStateView(
                    message:
                        'Gagal memuat riwayat transaksi. Periksa koneksi lalu coba lagi.',
                    onRetry: _load,
                  )
                else if (filtered.isEmpty)
                  EmptyStateView(
                    icon: _activeTab == 'buyer'
                        ? Icons.shopping_bag_outlined
                        : Icons.storefront_outlined,
                    title: _activeTab == 'buyer'
                        ? 'Belum ada pembelian'
                        : 'Belum ada pesanan masuk',
                    subtitle: _activeTab == 'buyer'
                        ? 'Pesanan yang kamu buat akan muncul di sini.'
                        : 'Pesanan dari pembeli akan muncul di sini.',
                  )
                else
                  ...filtered.map(
                    (tx) => _TxCard(
                      tx: tx,
                      isSeller: _activeTab == 'seller',
                      isUploading: _uploadingId == tx['id'].toString(),
                      onUploadProof: () =>
                          _uploadProofForTx(tx['id'].toString()),
                      onVerify: () =>
                          _sellerAction(tx['id'].toString(), 'payment_verified'),
                      onComplete: () =>
                          _sellerAction(tx['id'].toString(), 'completed'),
                      onReject: (reason) => _sellerAction(
                        tx['id'].toString(),
                        'cancelled',
                        rejectionReason: reason,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String id, String label, int badge) {
    final active = _activeTab == id;
    return Expanded(
      child: Material(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () => setState(() {
            _activeTab = id;
            _filterStatus = 'all';
          }),
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (badge > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.22)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final bool isSeller;
  final bool isUploading;
  final VoidCallback onUploadProof;
  final VoidCallback onVerify;
  final VoidCallback onComplete;
  final void Function(String reason) onReject;

  const _TxCard({
    required this.tx,
    required this.isSeller,
    required this.isUploading,
    required this.onUploadProof,
    required this.onVerify,
    required this.onComplete,
    required this.onReject,
  });

  StatusBadge _buildStatusBadge(String status) {
    switch (status) {
      case 'pending_payment':
        return const StatusBadge(
          label: 'Menunggu Pembayaran',
          color: AppColors.warning,
          icon: Icons.schedule_rounded,
        );
      case 'payment_uploaded':
        return const StatusBadge(
          label: 'Bukti Dikirim',
          color: AppColors.primaryText,
          icon: Icons.upload_file_rounded,
        );
      case 'payment_verified':
        return const StatusBadge(
          label: 'Pembayaran Terverifikasi',
          color: AppColors.primaryBright,
          icon: Icons.verified_outlined,
        );
      case 'completed':
        return const StatusBadge(
          label: 'Selesai',
          color: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
        );
      case 'cancelled':
        return const StatusBadge(
          label: 'Dibatalkan',
          color: AppColors.destructive,
          icon: Icons.cancel_outlined,
        );
      default:
        return StatusBadge(
          label: status,
          color: AppColors.mutedForeground,
        );
    }
  }

  Future<void> _showProofDialog(BuildContext context, String proofUrl) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final maxImgHeight = math.min(
          380.0,
          math.max(120.0, MediaQuery.sizeOf(ctx).height * 0.42),
        );
        return Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bukti Transfer',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      tooltip: 'Tutup',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: maxImgHeight),
                    color: AppColors.surfaceElevated,
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Image.network(
                        proofUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            height: math.min(220.0, maxImgHeight),
                            child: Center(
                              child: ShimmerBox(
                                height: math.min(220.0, maxImgHeight),
                                radius: 12,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => SizedBox(
                          height: math.min(200.0, maxImgHeight),
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 36,
                                    color: AppColors.mutedForeground,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Gagal memuat gambar bukti transfer.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => launchExternalUri(
                          ctx,
                          Uri.parse(proofUrl),
                          external: true,
                          failureMessage:
                              'Tidak dapat membuka bukti transfer.',
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Buka di Browser', maxLines: 1),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openRejectDialog(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectPaymentDialog(),
    );
    if (reason != null) {
      onReject(reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (tx['status'] ?? 'pending_payment').toString();
    final items = List<Map<String, dynamic>>.from(tx['items'] ?? []);
    final total = (tx['totalPrice'] as num?)?.toInt() ?? 0;
    final proofUrl = tx['paymentProofUrl']?.toString();
    final sellerPhone = tx['sellerPhone']?.toString();
    final txId = (tx['id'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      txId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(status),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (item['name'] ?? '').toString(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppConstants.formatRp((item['price'] as num?) ?? 0),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                  if (proofUrl != null && proofUrl.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _showProofDialog(context, proofUrl),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Lihat Bukti Transfer'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                  if (!isSeller && status == 'pending_payment') ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        '/payment',
                        arguments: txId,
                      ),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('Bayar / Info Rekening'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (sellerPhone != null && sellerPhone.isNotEmpty) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final wa =
                                    AppConstants.formatPhoneForWa(sellerPhone);
                                final msg = Uri.encodeComponent(
                                  'Halo, ini tindak lanjut pesanan LoopKos ID: $txId.',
                                );
                                launchExternalUri(
                                  context,
                                  Uri.parse('https://wa.me/$wa?text=$msg'),
                                  external: true,
                                  failureMessage:
                                      'Tidak dapat membuka WhatsApp.',
                                );
                              },
                              icon: const Icon(Icons.chat_outlined, size: 18),
                              label: const Text('Hubungi'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                backgroundColor: AppColors.whatsapp,
                                foregroundColor: AppColors.background,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isUploading ? null : onUploadProof,
                            icon: const Icon(Icons.upload_rounded, size: 18),
                            label: Text(
                              isUploading ? 'Mengunggah...' : 'Upload Bukti',
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (isSeller && status == 'payment_uploaded') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onVerify,
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('Konfirmasi'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.background,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openRejectDialog(context),
                            icon: const Icon(
                              Icons.block_rounded,
                              size: 18,
                              color: Color(0xFFF87171),
                            ),
                            label: const Text(
                              'Tolak',
                              style: TextStyle(color: Color(0xFFF87171)),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              side: BorderSide(
                                color: AppColors.destructive.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (isSeller && status == 'payment_verified') ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Tandai Selesai & Barang Dikirim'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectPaymentDialog extends StatefulWidget {
  const _RejectPaymentDialog();

  @override
  State<_RejectPaymentDialog> createState() => _RejectPaymentDialogState();
}

class _RejectPaymentDialogState extends State<_RejectPaymentDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak Pembayaran'),
      content: TextField(
        controller: _ctrl,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Alasan penolakan (opsional)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _ctrl.text.trim().isEmpty
                ? 'Bukti pembayaran tidak valid.'
                : _ctrl.text.trim();
            Navigator.pop(context, text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.destructive,
            foregroundColor: Colors.white,
          ),
          child: const Text('Ya, Tolak'),
        ),
      ],
    );
  }
}
