import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_background.dart';
import '../widgets/loopkos_header.dart';
import '../widgets/main_shell.dart';
import '../widgets/ui_kit.dart';

class _BundleItemDraft {
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  String category;

  _BundleItemDraft({
    String name = '',
    String price = '',
  })  : nameCtrl = TextEditingController(text: name),
        priceCtrl = TextEditingController(text: price),
        category = '';

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

class SellRoomScreen extends StatefulWidget {
  final int initialStepForTest;

  const SellRoomScreen({
    super.key,
    this.initialStepForTest = 1,
  });

  /// Clamps a raw bundle discount input so submitted and previewed discounts
  /// never go negative or exceed the bundle's total item price.
  static int clampBundleDiscount(int rawDiscount, int totalPrice) {
    final safeTotal = math.max(0, totalPrice);
    return math.max(0, math.min(rawDiscount, safeTotal));
  }

  @override
  State<SellRoomScreen> createState() => _SellRoomScreenState();
}

class _SellRoomScreenState extends State<SellRoomScreen> {
  late int _step;
  String _listingType = 'single'; // single | bundle
  bool _isSubmitting = false;
  bool _isDone = false;

  final List<File> _images = [];

  // Single fields
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');
  final _descCtrl = TextEditingController();
  String _category = '';
  String _condition = 'Baik';

  // Bundle fields
  final _bundleNameCtrl = TextEditingController();
  final _bundleDiscountCtrl = TextEditingController();
  final List<_BundleItemDraft> _bundleItems = [_BundleItemDraft()];

  // Shared
  late final TextEditingController _locationCtrl;
  DateTime? _pickupDate;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _step = widget.initialStepForTest.clamp(1, 3);
    final auth = readAuthOrNull(context);
    final campus = auth?.user?.campus ?? '';
    _locationCtrl = TextEditingController(text: campus);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    _bundleNameCtrl.dispose();
    _bundleDiscountCtrl.dispose();
    for (final item in _bundleItems) {
      item.dispose();
    }
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _showImagePickerSheet() async {
    if (_images.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 8 foto per listing.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pilih Sumber Foto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryBright),
                  title: const Text('Ambil Foto (Kamera)', style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryBright),
                  title: const Text('Pilih dari Galeri', style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImagesFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 85);
      if (file != null && mounted) {
        setState(() {
          if (_images.length < 8) {
            _images.add(File(file.path));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 85);
      if (files.isNotEmpty && mounted) {
        setState(() {
          for (final f in files) {
            if (_images.length < 8) {
              _images.add(File(f.path));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  int get _bundleTotalPrice {
    return _bundleItems.fold(
      0,
      (s, i) => s + math.max(0, int.tryParse(i.priceCtrl.text.trim()) ?? 0),
    );
  }

  bool get _canGoNext {
    if (_step == 1) return _images.isNotEmpty;
    if (_step == 2) {
      if (_listingType == 'single') {
        return _nameCtrl.text.trim().isNotEmpty &&
            _priceCtrl.text.trim().isNotEmpty &&
            _category.isNotEmpty;
      }
      return _bundleNameCtrl.text.trim().isNotEmpty &&
          _bundleItems.isNotEmpty &&
          _bundleItems.every((i) =>
              i.nameCtrl.text.trim().isNotEmpty &&
              i.priceCtrl.text.trim().isNotEmpty &&
              i.category.isNotEmpty);
    }
    return true;
  }

  List<String> _getMissingStep2Fields() {
    final missing = <String>[];
    if (_listingType == 'single') {
      if (_nameCtrl.text.trim().isEmpty) missing.add('nama barang');
      if (_priceCtrl.text.trim().isEmpty) missing.add('harga');
      if (_category.isEmpty) missing.add('kategori');
    } else {
      if (_bundleNameCtrl.text.trim().isEmpty) missing.add('nama bundle');
      final hasIncomplete = _bundleItems.isEmpty ||
          _bundleItems.any((i) =>
              i.nameCtrl.text.trim().isEmpty ||
              i.priceCtrl.text.trim().isEmpty ||
              i.category.isEmpty);
      if (hasIncomplete) missing.add('kelengkapan semua item');
    }
    return missing;
  }

  void _addBundleItem() {
    setState(() {
      _bundleItems.add(_BundleItemDraft());
    });
  }

  void _removeBundleItem(int idx) {
    if (_bundleItems.length <= 1) return;
    final removed = _bundleItems.removeAt(idx);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.dispose();
    });
    setState(() {});
  }

  Future<void> _submit() async {
    final auth = readAuthOrNull(context);
    if (auth == null || auth.accessToken == null || auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamu harus login terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final imageUrls = <String>[];
      for (final file in _images) {
        final uploaded = await ApiService.uploadFile(auth.accessToken!, file, bucket: 'images');
        imageUrls.add(uploaded['url'].toString());
      }

      if (_listingType == 'single') {
        await ApiService.createProduct(auth.accessToken!, {
          'name': _nameCtrl.text.trim(),
          'price': math.max(0, int.tryParse(_priceCtrl.text.trim()) ?? 0),
          'category': _category,
          'description': _descCtrl.text.trim(),
          'condition': _condition,
          'stock': math.max(1, int.tryParse(_stockCtrl.text.trim()) ?? 1),
          'imageUrls': imageUrls,
          'location': _locationCtrl.text.trim().isEmpty ? auth.user!.campus : _locationCtrl.text.trim(),
        });
      } else {
        final totalPrice = _bundleTotalPrice;
        final rawDiscount = int.tryParse(_bundleDiscountCtrl.text.trim()) ?? 0;
        final safeDiscount = SellRoomScreen.clampBundleDiscount(rawDiscount, totalPrice);
        await ApiService.createBundle(auth.accessToken!, {
          'name': _bundleNameCtrl.text.trim(),
          'items': _bundleItems
              .map((i) => {
                    'name': i.nameCtrl.text.trim(),
                    'price': math.max(0, int.tryParse(i.priceCtrl.text.trim()) ?? 0),
                    'category': i.category,
                    'imageUrls': <String>[],
                    'sellerId': auth.user!.id,
                    'sellerName': auth.user!.name,
                    'condition': 'Baik',
                  })
              .toList(),
          'totalPrice': totalPrice,
          'discount': safeDiscount,
          'location': _locationCtrl.text.trim().isEmpty ? auth.user!.campus : _locationCtrl.text.trim(),
          'pickupDate': _pickupDate != null ? _pickupDate!.toIso8601String().split('T').first : '',
          'notes': _notesCtrl.text.trim(),
          'imageUrls': imageUrls,
        });
      }

      if (!mounted) return;
      setState(() => _isDone = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendaftarkan: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDone) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const LoopKosHeader(currentRoute: '/sell', title: 'Jual Barang'),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AppCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Berhasil Didaftarkan!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _listingType == 'single'
                          ? 'Produk kamu sudah live! Pembeli bisa langsung menemukannya di LoopKos.'
                          : 'Bundle kamu sudah live! Pembeli bisa langsung menemukannya di LoopKos.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => MainShell.switchTab(context, 0),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.primaryBright,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Lihat di Beranda', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isDone = false;
                            _step = 1;
                            _images.clear();
                            _nameCtrl.clear();
                            _priceCtrl.clear();
                            _stockCtrl.text = '1';
                            _descCtrl.clear();
                            _category = '';
                            _condition = 'Baik';
                            _bundleNameCtrl.clear();
                            _bundleDiscountCtrl.clear();
                            for (final item in _bundleItems) {
                              item.dispose();
                            }
                            _bundleItems
                              ..clear()
                              ..add(_BundleItemDraft());
                            _pickupDate = null;
                            _notesCtrl.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Daftarkan Barang Lagi', style: TextStyle(color: AppColors.textPrimary)),
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

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const LoopKosHeader(currentRoute: '/sell', title: 'Jual Barang'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stepNode(1, 'Foto'),
                  _stepLine(_step > 1),
                  _stepNode(2, 'Detail'),
                  _stepLine(_step > 2),
                  _stepNode(3, 'Lokasi'),
                ],
              ),
              const SizedBox(height: 8),

              AppCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step == 1) ...[
                      const Text(
                        'Upload Foto Barang',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Foto yang jelas mempercepat penjualan (min. 1 foto)',
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ..._images.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final file = entry.value;
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(file, width: 92, height: 92, fit: BoxFit.cover),
                                ),
                                if (idx == 0)
                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBright,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Sampul',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: IconButton(
                                      iconSize: 18,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                      onPressed: () => setState(() => _images.removeAt(idx)),
                                      icon: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.destructive,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                      tooltip: 'Hapus foto',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          if (_images.length < 8)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showImagePickerSheet,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, color: AppColors.mutedForeground, size: 24),
                                      SizedBox(height: 6),
                                      Text(
                                        'Tambah',
                                        style: TextStyle(
                                          color: AppColors.mutedForeground,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_images.isEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBright.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primaryBright.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppColors.primaryBright),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Minimal 1 foto diperlukan sebelum lanjut ke Step 2.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else if (_step == 2) ...[
                      const Text(
                        'Detail Barang',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _typeCard(
                              'single',
                              'Jual Satuan',
                              'Satu barang per listing',
                              Icons.inventory_2_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _typeCard(
                              'bundle',
                              'Bundle Sekaligus',
                              'Paket banyak barang',
                              Icons.auto_awesome_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_listingType == 'single') ...[
                        TextField(
                          controller: _nameCtrl,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Nama Barang *',
                            hintText: 'Contoh: Kursi Belajar Ergonomis',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _priceCtrl,
                                onChanged: (_) => setState(() {}),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  labelText: 'Harga (Rp) *',
                                  hintText: '250000',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _stockCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  labelText: 'Stok',
                                  hintText: '1',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _category.isEmpty ? null : _category,
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Kategori *',
                            isDense: true,
                          ),
                          items: AppConstants.categories.map((c) {
                            final catId = c['id'] ?? '';
                            final name = c['name'] ?? '';
                            return DropdownMenuItem<String>(
                              value: catId,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(AppConstants.categoryIconData(catId), size: 18, color: AppColors.primaryBright),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _category = v ?? ''),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _condition,
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Kondisi *',
                            isDense: true,
                          ),
                          items: AppConstants.conditions.map((c) {
                            return DropdownMenuItem<String>(
                              value: c,
                              child: Text(c, style: const TextStyle(color: AppColors.textPrimary)),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _condition = v ?? 'Baik'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            hintText: 'Jelaskan kondisi barang...',
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: _bundleNameCtrl,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Nama Bundle *',
                            hintText: 'Contoh: Set Kos Siap Huni',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Daftar Barang *',
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _addBundleItem,
                              icon: const Icon(Icons.add, size: 18, color: AppColors.primaryBright),
                              label: const Text(
                                'Tambah Item',
                                style: TextStyle(color: AppColors.primaryBright, fontWeight: FontWeight.w600),
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        ..._bundleItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final priceField = TextField(
                            key: ValueKey('bundle_item_price_$idx'),
                            controller: item.priceCtrl,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Harga (Rp) *',
                              hintText: 'Harga (Rp)',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          );
                          final categoryField = DropdownButtonFormField<String>(
                            key: ValueKey('bundle_item_category_$idx'),
                            initialValue: item.category.isEmpty ? null : item.category,
                            isExpanded: true,
                            dropdownColor: AppColors.card,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Kategori *',
                              hintText: 'Pilih kategori',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: AppConstants.categories.map((c) {
                              final catId = c['id'] ?? '';
                              final name = c['name'] ?? '';
                              return DropdownMenuItem<String>(
                                value: catId,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(AppConstants.categoryIconData(catId), size: 16, color: AppColors.primaryBright),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => item.category = v ?? ''),
                          );

                          return Container(
                            key: ObjectKey(item),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                              borderColor: AppColors.border,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Barang ${idx + 1}',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (_bundleItems.length > 1)
                                        IconButton(
                                          key: ValueKey('bundle_item_delete_$idx'),
                                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _removeBundleItem(idx),
                                          icon: const Icon(Icons.delete_outline, color: AppColors.destructive, size: 20),
                                          tooltip: 'Hapus barang',
                                        ),
                                    ],
                                  ),
                                  if (_bundleItems.length <= 1) const SizedBox(height: 6),
                                  TextField(
                                    key: ValueKey('bundle_item_name_$idx'),
                                    controller: item.nameCtrl,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                    decoration: const InputDecoration(
                                      labelText: 'Nama Barang *',
                                      hintText: 'Nama barang',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth < 300) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            priceField,
                                            const SizedBox(height: 8),
                                            categoryField,
                                          ],
                                        );
                                      }
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: priceField),
                                          const SizedBox(width: 8),
                                          Expanded(child: categoryField),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        TextField(
                          controller: _bundleDiscountCtrl,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Diskon Bundle (Rp)',
                            hintText: 'Contoh: 50000',
                            isDense: true,
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final rawDiscount = int.tryParse(_bundleDiscountCtrl.text.trim()) ?? 0;
                            final safeDiscount = SellRoomScreen.clampBundleDiscount(rawDiscount, _bundleTotalPrice);
                            final netPrice = math.max(0, _bundleTotalPrice - safeDiscount);
                            final isDiscountTooHigh = rawDiscount > _bundleTotalPrice && _bundleTotalPrice > 0;

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: AppCard(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderColor: AppColors.primaryBright.withValues(alpha: 0.3),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primaryBright),
                                        SizedBox(width: 8),
                                        Text(
                                          'Ringkasan Bundle',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Total Nilai Item: ${AppConstants.formatRp(_bundleTotalPrice)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Harga Jual Bundle: ${AppConstants.formatRp(netPrice)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBright,
                                      ),
                                    ),
                                    if (isDiscountTooHigh) ...[
                                      const SizedBox(height: 6),
                                      const Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Diskon melebihi total nilai item. Harga jual menjadi Rp 0.',
                                              style: TextStyle(fontSize: 11, color: AppColors.warning),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      if (!_canGoNext) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lengkapi ${_getMissingStep2Fields().join(", ")} sebelum lanjut.',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'Lokasi & Jadwal',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _locationCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Lokasi / Alamat Kost',
                          hintText: 'Kost Mahasiswa, Depok',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _pickupDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppColors.primaryBright,
                                    onPrimary: Colors.white,
                                    surface: AppColors.card,
                                    onSurface: AppColors.textPrimary,
                                  ),
                                  dialogTheme: const DialogThemeData(
                                    backgroundColor: AppColors.card,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && mounted) {
                            setState(() => _pickupDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryBright),
                        label: Text(
                          _pickupDate == null
                              ? 'Pilih Tanggal Pengambilan'
                              : 'Tanggal: ${_pickupDate!.day}/${_pickupDate!.month}/${_pickupDate!.year}',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Catatan Tambahan',
                          hintText: 'Bisa COD area kampus...',
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_step > 1) ...[
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _step--),
                            icon: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textPrimary),
                            label: const Text('Kembali', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(100, 48),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: _step < 3
                              ? ElevatedButton(
                                  onPressed: _canGoNext ? () => setState(() => _step++) : null,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    backgroundColor: AppColors.primaryBright,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: AppColors.card,
                                    disabledForegroundColor: AppColors.mutedForeground,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    'Lanjut ke Step ${_step + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : _submit,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.check_circle_outline, size: 20),
                                  label: Text(
                                    _isSubmitting ? 'Menyimpan...' : 'Daftarkan Barang',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        ),
      ),
    );
  }

  Widget _stepNode(int n, String label) {
    final done = _step > n;
    final active = _step == n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: done
                ? AppColors.success
                : active
                    ? AppColors.primaryBright
                    : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '$n',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _step >= n ? AppColors.primaryBright : AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Container(
      width: 36,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
      color: active ? AppColors.primaryBright : Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _typeCard(String id, String title, String desc, IconData icon) {
    final active = _listingType == id;
    return AppCard(
      onTap: () => setState(() => _listingType = id),
      borderColor: active ? AppColors.primaryBright : AppColors.border,
      color: active ? AppColors.primary.withValues(alpha: 0.15) : AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? AppColors.primaryBright : AppColors.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: active ? AppColors.primaryBright : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 10,
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
