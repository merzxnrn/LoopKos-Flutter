import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppConstants {
  static const String projectId = 'onsltmqoijolmndcdzxh';
  static const String publicAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9uc2x0bXFvaWpvbG1uZGNkenhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxODAwODYsImV4cCI6MjA5MTc1NjA4Nn0.6X6USIWFkXB5MZnOJEhenkf0QaDNpozod1Th8vrSDN0';

  static const String supabaseUrl = 'https://$projectId.supabase.co';
  static const String serverUrl = '$supabaseUrl/functions/v1/make-server-f1672a97';

  static const List<String> campusOptions = [
    'Universitas Indonesia',
    'Institut Teknologi Bandung',
    'Universitas Gadjah Mada',
    'Institut Teknologi Sepuluh Nopember',
    'Universitas Airlangga',
    'Universitas Diponegoro',
    'Universitas Brawijaya',
    'Universitas Padjadjaran',
    'Universitas Sebelas Maret',
    'Lainnya',
  ];

  static const List<String> bankOptions = [
    'BCA (Bank Central Asia)',
    'BRI (Bank Rakyat Indonesia)',
    'BNI (Bank Negara Indonesia)',
    'Bank Mandiri',
    'CIMB Niaga',
    'Danamon',
    'Permata Bank',
    'BTN (Bank Tabungan Negara)',
    'BSI (Bank Syariah Indonesia)',
    'Bank Jago',
    'SeaBank',
    'Neo Commerce (BNC)',
    'OCBC NISP',
    'Maybank',
    'Panin Bank',
    'BPD (Bank Daerah)',
    'Lainnya',
  ];

  static const List<String> conditions = [
    'Seperti Baru',
    'Sangat Baik',
    'Baik',
    'Cukup Baik',
  ];

  static const List<Map<String, String>> categories = [
    {'id': 'furnitur', 'name': 'Furnitur & Kamar', 'icon': '🛋️'},
    {'id': 'elektronik', 'name': 'Elektronik & Gadget', 'icon': '⚡'},
    {'id': 'dapur', 'name': 'Dapur & Makan', 'icon': '🍳'},
    {'id': 'pakaian', 'name': 'Pakaian & Fashion', 'icon': '👕'},
    {'id': 'buku', 'name': 'Buku & Alat Tulis', 'icon': '📚'},
    {'id': 'lainnya', 'name': 'Lainnya', 'icon': '📦'},
  ];

  static String categoryEmoji(String? cat) {
    const map = {
      'furnitur': '🛋️',
      'elektronik': '⚡',
      'dapur': '🍳',
      'pakaian': '👕',
      'buku': '📚',
      'lainnya': '📦',
      'bundle': '📦',
    };
    return map[cat] ?? '📦';
  }

  static IconData categoryIconData(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'furnitur':
        return Icons.chair_outlined;
      case 'elektronik':
        return Icons.bolt_outlined;
      case 'dapur':
        return Icons.soup_kitchen_outlined;
      case 'pakaian':
        return Icons.checkroom_outlined;
      case 'buku':
        return Icons.menu_book_outlined;
      case 'bundle':
        return Icons.layers_outlined;
      case 'lainnya':
      default:
        return Icons.inventory_2_outlined;
    }
  }

  static String formatRp(num amount) {
    final formatter = NumberFormat.decimalPattern('id_ID');
    return 'Rp ${formatter.format(amount.round())}';
  }

  static String formatPhoneForWa(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('62')) return digits;
    if (digits.startsWith('0')) return '62${digits.substring(1)}';
    return '62$digits';
  }
}
