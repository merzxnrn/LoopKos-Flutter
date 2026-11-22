class AuthUser {
  final String id;
  final String name;
  final String email;
  final String campus;
  final String? phone;
  final String? bankAccount;
  final String? bankName;
  final bool verified;
  final double rating;
  final int totalSales;
  final int totalPurchases;
  final String joinedAt;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.campus,
    this.phone,
    this.bankAccount,
    this.bankName,
    this.verified = false,
    this.rating = 5.0,
    this.totalSales = 0,
    this.totalPurchases = 0,
    required this.joinedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      campus: (json['campus'] ?? '').toString(),
      phone: json['phone']?.toString(),
      bankAccount: json['bank_account']?.toString(),
      bankName: json['bank_name']?.toString(),
      verified: json['verified'] == true,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 5.0,
      totalSales: (json['total_sales'] is num) ? (json['total_sales'] as num).toInt() : 0,
      totalPurchases: (json['total_purchases'] is num) ? (json['total_purchases'] as num).toInt() : 0,
      joinedAt: (json['joinedAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
    );
  }

  AuthUser copyWith({
    String? name,
    String? campus,
    String? phone,
    String? bankAccount,
    String? bankName,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email,
      campus: campus ?? this.campus,
      phone: phone ?? this.phone,
      bankAccount: bankAccount ?? this.bankAccount,
      bankName: bankName ?? this.bankName,
      verified: verified,
      rating: rating,
      totalSales: totalSales,
      totalPurchases: totalPurchases,
      joinedAt: joinedAt,
    );
  }
}

class CartItem {
  final String id;
  final String name;
  final int price;
  final String category;
  final List<String> imageUrls;
  final String sellerId;
  final String sellerName;
  final String? sellerPhone;
  final String condition;
  final String location;
  final bool isBundle;
  final List<Map<String, dynamic>>? bundleItems;
  final int discount;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrls,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    required this.condition,
    required this.location,
    this.isBundle = false,
    this.bundleItems,
    this.discount = 0,
  });
}

class ReviewModel {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final String date;

  const ReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
