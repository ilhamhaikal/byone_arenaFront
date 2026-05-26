class MemberModel {
  final int id;
  final String memberCode;
  final String fullName;
  final String phone;
  final String email;
  final String membershipType; // 'regular', 'silver', 'gold', 'platinum'
  final int totalPoints;
  final DateTime registeredAt;
  final DateTime? expiredAt;
  final bool isActive;

  MemberModel({
    required this.id,
    required this.memberCode,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.membershipType,
    required this.totalPoints,
    required this.registeredAt,
    this.expiredAt,
    required this.isActive,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'],
      memberCode: json['member_code'],
      fullName: json['full_name'],
      phone: json['phone'],
      email: json['email'] ?? '',
      membershipType: json['membership_type'] ?? 'regular',
      totalPoints: json['total_points'] ?? 0,
      registeredAt: DateTime.parse(json['registered_at']),
      expiredAt: json['expired_at'] != null
          ? DateTime.parse(json['expired_at'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'member_code': memberCode,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'membership_type': membershipType,
        'is_active': isActive,
      };

  String get membershipLabel {
    switch (membershipType) {
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      default:
        return 'Regular';
    }
  }
}
