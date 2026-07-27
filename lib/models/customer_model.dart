class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final bool isMember;
  final String? membershipType;
  final String? membershipStart;
  final String? membershipExpiry;
  final double? membershipPrice;
  final int timeBalanceMinutes; // sisa menit bank waktu (hanya untuk member)
  final int loyaltyPoints; // poin loyalitas (hanya untuk member)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.isMember = false,
    this.membershipType,
    this.membershipStart,
    this.membershipExpiry,
    this.membershipPrice,
    this.timeBalanceMinutes = 0,
    this.loyaltyPoints = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '?',
      phone: (json['phone'] as String?) ?? '',
      email: json['email'] as String?,
      isMember: json['isMember'] as bool? ?? false,
      membershipType: json['membershipType'] as String?,
      membershipStart: json['membershipStart'] as String?,
      membershipExpiry: json['membershipExpiry'] as String?,
      membershipPrice: (json['membershipPrice'] as num?)?.toDouble(),
      timeBalanceMinutes: (json['timeBalanceMinutes'] as int?) ?? 0,
      loyaltyPoints: (json['loyaltyPoints'] as int?) ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
      };
}
