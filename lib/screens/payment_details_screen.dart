import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_background.dart';
import '../widgets/loopkos_header.dart';
import '../widgets/main_shell.dart';
import '../widgets/ui_kit.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String transactionId;
  final Future<Map<String, dynamic>?> Function(String txId)? loader;

  const PaymentDetailsScreen({
    super.key,
    required this.transactionId,
    this.loader,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  Map<String, dynamic>? _tx;
  bool _isLoading = true;
  bool _hasError = false;
  File? _proofFile;
  bool _isUploading = false;
  bool _proofSubmitted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PaymentDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactionId != widget.transactionId ||
        oldWidget.loader != widget.loader) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      Map<String, dynamic>? found;
      if (widget.loader != null) {
        found = await widget.loader!(widget.transactionId);
      } else {
        final token = readAuthOrNull(context)?.accessToken;
        if (token == null) {
          if (mounted) {
            setState(() {
              _tx = null;
              _isLoading = false;
            });
          }
          return;
        }
        final txs = await ApiService.getTransactions(token, role: 'buyer');
        found = txs
            .where((t) => t['id'].toString() == widget.transactionId)
            .firstOrNull;
      }

      if (!mounted) return;
      setState(() {
        _tx = found;
        _proofSubmitted = found?['paymentProofUrl'] != null &&
            found!['paymentProofUrl'].toString().isNotEmpty;
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

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _proofFile = File(picked.path));
  }

  Future<void> _submitProof() async {
    final token = readAuthOrNull(context)?.accessToken;
    if (token == null || _proofFile == null || _tx == null) return;

    setState(() => _isUploading = true);
    try {
      final upload = await ApiService.uploadFile(
        token,
        _proofFile!,
        bucket: 'proofs',
      );
      await ApiService.updateTransaction(token, _tx!['id'].toString(), {
        'paymentProofUrl': upload['url'],
        'paymentProofPath': upload['path'],
        'status': 'payment_uploaded',
      });
      if (!mounted) return;
      setState(() {
        _proofSubmitted = true;
        _tx = {
          ..._tx!,
          'status': 'payment_uploaded',
          'paymentProofUrl': upload['url'],
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti pembayaran berhasil dikirim')),
      );
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
      if (mounted) setState(() => _isUploading = false);
    }
  }

  int _currentProgressStep(String status) {
    if (status == 'completed' || status == 'payment_verified') return 4;
    if (status == 'payment_uploaded' || _proofSubmitted) return 3;
    return 2;
  }

  StatusBadge _buildStatusBadge(String status) {
    switch (status) {
      case 'payment_uploaded':
        return const StatusBadge(
          label: 'Menunggu Verifikasi',
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
      case 'pending_payment':
      default:
        return const StatusBadge(
          label: 'Menunggu Pembayaran',
          color: AppColors.warning,
          icon: Icons.schedule_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: LoopKosHeader(
            currentRoute: '/payment',
            title: 'Detail Pembayaran',
            showBack: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShimmerBox(height: 82, radius: 16),
                SizedBox(height: 16),
                ShimmerBox(height: 360, radius: 16),
                SizedBox(height: 16),
                ShimmerBox(height: 130, radius: 16),
              ],
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const LoopKosHeader(
            currentRoute: '/payment',
            title: 'Detail Pembayaran',
            showBack: true,
          ),
          body: ErrorStateView(
            message: 'Gagal memuat detail pembayaran. Periksa koneksi lalu coba lagi.',
            onRetry: _load,
          ),
        ),
      );
    }

    if (_tx == null) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const LoopKosHeader(
            currentRoute: '/payment',
            title: 'Detail Pembayaran',
            showBack: true,
          ),
          body: EmptyStateView(
            icon: Icons.receipt_long_outlined,
            title: 'Transaksi tidak ditemukan',
            subtitle: 'Pesanan yang kamu cari tidak tersedia atau sudah dihapus.',
            actionLabel: 'Kembali',
            onAction: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
    }

    final tx = _tx!;
    final status = (tx['status'] ?? 'pending_payment').toString();
    final bankAccount = tx['sellerBankAccount']?.toString();
    final bankName = tx['sellerBankName']?.toString() ?? 'Bank';
    final sellerPhone = tx['sellerPhone']?.toString();
    final sellerName = (tx['sellerName'] ?? 'Penjual').toString();
    final items = List<Map<String, dynamic>>.from(tx['items'] ?? []);
    final proofUrl = tx['paymentProofUrl']?.toString();
    final activeStep = _currentProgressStep(status);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const LoopKosHeader(
          currentRoute: '/payment',
          title: 'Detail Pembayaran',
          showBack: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (status != 'cancelled') ...[
                _PaymentProgressBar(currentStep: activeStep),
                const SizedBox(height: 16),
              ],

              AppCard(
                padding: EdgeInsets.zero,
                borderColor: AppColors.primary.withValues(alpha: 0.6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(height: 4, color: AppColors.primaryBright),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusBadge(status),
                          const SizedBox(height: 10),
                          const Text(
                            'Pembayaran Manual',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Transfer sesuai nominal tagihan lalu unggah bukti transfer agar penjual dapat memverifikasi pesanan.',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Bank Info
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'INFORMASI REKENING',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mutedForeground,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (bankAccount != null && bankAccount.isNotEmpty) ...[
                                  Text(
                                    bankName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                      right: 4,
                                      top: 4,
                                      bottom: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            bankAccount,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.2,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            Clipboard.setData(
                                              ClipboardData(text: bankAccount),
                                            );
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Nomor rekening disalin'),
                                              ),
                                            );
                                          },
                                          tooltip: 'Salin nomor rekening',
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                          style: IconButton.styleFrom(
                                            minimumSize: const Size(48, 48),
                                          ),
                                          icon: const Icon(
                                            Icons.copy_rounded,
                                            size: 20,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'a.n. $sellerName',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ] else
                                  const Text(
                                    'Penjual belum mengatur rekening. Hubungi penjual via WhatsApp.',
                                    style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Total Bill
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Tagihan',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                AppConstants.formatRp((tx['totalPrice'] as num?) ?? 0),
                                style: const TextStyle(
                                  color: AppColors.priceGreen,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // WhatsApp button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: sellerPhone == null || sellerPhone.isEmpty
                                  ? null
                                  : () {
                                      final wa = AppConstants.formatPhoneForWa(sellerPhone);
                                      final msg = Uri.encodeComponent(
                                        'Halo kak, saya ingin menanyakan pesanan #${tx['id']}. Terima kasih.',
                                      );
                                      launchExternalUri(
                                        context,
                                        Uri.parse('https://wa.me/$wa?text=$msg'),
                                        external: true,
                                        failureMessage: 'Tidak dapat membuka WhatsApp.',
                                      );
                                    },
                              icon: const Icon(Icons.chat_outlined, size: 18),
                              label: const Text('Hubungi Penjual via WhatsApp'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                backgroundColor: AppColors.whatsapp,
                                foregroundColor: AppColors.background,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Bukti Pembayaran',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_proofSubmitted)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.40),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Color(0xFF6EE7B7),
                                        size: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Bukti pembayaran terkirim. Penjual akan memverifikasi pembayaran kamu.',
                                          style: TextStyle(
                                            color: Color(0xFF6EE7B7),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_proofFile != null ||
                                      (proofUrl != null && proofUrl.isNotEmpty)) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        height: 150,
                                        width: double.infinity,
                                        child: _proofFile != null
                                            ? Image.file(
                                                _proofFile!,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                proofUrl!,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (_, child, progress) {
                                                  if (progress == null) return child;
                                                  return const ShimmerBox(radius: 0);
                                                },
                                                errorBuilder: (_, _, _) => Container(
                                                  color: AppColors.surfaceElevated,
                                                  alignment: Alignment.center,
                                                  child: const Icon(
                                                    Icons.broken_image_outlined,
                                                    color: AppColors.mutedForeground,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => MainShell.switchTab(context, 3),
                                    icon: const Icon(
                                      Icons.receipt_long_outlined,
                                      size: 18,
                                      color: Color(0xFF6EE7B7),
                                    ),
                                    label: const Text(
                                      'Lihat Riwayat Transaksi',
                                      style: TextStyle(color: Color(0xFF6EE7B7)),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                      side: BorderSide(
                                        color: AppColors.success.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            Material(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: _pickProof,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 148,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _proofFile != null
                                      ? Image.file(_proofFile!, fit: BoxFit.cover)
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_outlined,
                                              size: 36,
                                              color: AppColors.primaryText,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Ketuk untuk pilih foto bukti transfer',
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Format JPG atau PNG, maks. 5 MB',
                                              style: TextStyle(
                                                color: AppColors.mutedForeground,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    (_proofFile == null || _isUploading) ? null : _submitProof,
                                icon: const Icon(Icons.upload_rounded, size: 18),
                                label: Text(
                                  _isUploading ? 'Mengunggah...' : 'Kirim Bukti Pembayaran',
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                ),
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

              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RINGKASAN PESANAN',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                (item['name'] ?? '').toString(),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppConstants.formatRp((item['price'] as num?) ?? 0),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _PaymentProgressBar extends StatelessWidget {
  final int currentStep;

  const _PaymentProgressBar({required this.currentStep});

  static const _steps = ['Pesanan', 'Transfer', 'Upload', 'Verifikasi'];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          for (int i = 0; i < _steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 18),
                  color: (i + 1) <= currentStep
                      ? AppColors.primaryBright
                      : AppColors.border,
                ),
              ),
            _StepDot(
              stepNumber: i + 1,
              label: _steps[i],
              isDone: (i + 1) < currentStep || (currentStep == 4 && i == 3),
              isActive: (i + 1) == currentStep && currentStep < 4,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int stepNumber;
  final String label;
  final bool isDone;
  final bool isActive;

  const _StepDot({
    required this.stepNumber,
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDone
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : AppColors.surfaceElevated;
    final borderColor = isDone
        ? AppColors.success
        : isActive
            ? AppColors.primaryText
            : AppColors.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppColors.mutedForeground,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: (isActive || isDone) ? FontWeight.w700 : FontWeight.w500,
            color: (isActive || isDone)
                ? AppColors.textPrimary
                : AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
