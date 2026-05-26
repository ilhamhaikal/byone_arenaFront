import '../models/member_model.dart';
import '../models/rental_model.dart';
import '../models/user_model.dart';
import '../models/voucher_model.dart';

class MockData {
  // ── Auth ──────────────────────────────────────────────────
  static UserModel get adminUser => UserModel(
        id: 'mock-admin-id',
        username: 'admin',
        fullName: 'Administrator',
        role: 'admin',
        isActive: true,
      );

  // ── Rentals ───────────────────────────────────────────────
  static final _now = DateTime.now();

  static List<RentalModel> get activeRentals => [
        RentalModel(
          id: 1,
          rentalCode: 'R-20260001',
          consoleNumber: 1,
          consoleType: 'PS5',
          memberId: 1,
          memberName: 'Budi Santoso',
          startTime: _now.subtract(const Duration(hours: 2, minutes: 15)),
          pricePerHour: 25000,
          status: 'active',
        ),
        RentalModel(
          id: 2,
          rentalCode: 'R-20260002',
          consoleNumber: 2,
          consoleType: 'PS4',
          startTime: _now.subtract(const Duration(hours: 1)),
          pricePerHour: 15000,
          status: 'active',
          notes: 'Tamu biasa',
        ),
        RentalModel(
          id: 3,
          rentalCode: 'R-20260003',
          consoleNumber: 3,
          consoleType: 'PS5',
          memberId: 2,
          memberName: 'Siti Rahayu',
          startTime: _now.subtract(const Duration(minutes: 45)),
          pricePerHour: 25000,
          status: 'active',
        ),
        RentalModel(
          id: 4,
          rentalCode: 'R-20260004',
          consoleNumber: 4,
          consoleType: 'PS4',
          startTime: _now.subtract(const Duration(hours: 3)),
          pricePerHour: 15000,
          status: 'active',
        ),
      ];

  static List<RentalModel> get completedRentals => [
        RentalModel(
          id: 10,
          rentalCode: 'R-20250010',
          consoleNumber: 1,
          consoleType: 'PS5',
          memberId: 3,
          memberName: 'Ahmad Fauzi',
          startTime: _now.subtract(const Duration(hours: 5)),
          endTime: _now.subtract(const Duration(hours: 2)),
          durationMinutes: 180,
          pricePerHour: 25000,
          totalPrice: 75000,
          discountAmount: 7500,
          finalPrice: 67500,
          status: 'completed',
        ),
        RentalModel(
          id: 11,
          rentalCode: 'R-20250011',
          consoleNumber: 2,
          consoleType: 'PS4',
          startTime: _now.subtract(const Duration(hours: 8)),
          endTime: _now.subtract(const Duration(hours: 6)),
          durationMinutes: 120,
          pricePerHour: 15000,
          totalPrice: 30000,
          finalPrice: 30000,
          status: 'completed',
        ),
        RentalModel(
          id: 12,
          rentalCode: 'R-20250012',
          consoleNumber: 3,
          consoleType: 'PS4',
          startTime: _now.subtract(const Duration(hours: 10)),
          endTime: _now.subtract(const Duration(hours: 9)),
          durationMinutes: 60,
          pricePerHour: 15000,
          totalPrice: 15000,
          voucherCode: 'GAME10',
          discountAmount: 1500,
          finalPrice: 13500,
          status: 'completed',
        ),
      ];

  static List<RentalModel> get allRentals =>
      [...activeRentals, ...completedRentals];

  static Map<String, dynamic> get dashboardStats => {
        'active_rentals': 4,
        'today_revenue': 217500.0,
        'total_rentals_today': 7,
        'total_members': 5,
        'ps4_active': 2,
        'ps5_active': 2,
      };

  // ── Members ───────────────────────────────────────────────
  static List<MemberModel> get members => [
        MemberModel(
          id: 1,
          memberCode: 'MBR-001',
          fullName: 'Budi Santoso',
          phone: '081234567890',
          email: 'budi@email.com',
          membershipType: 'gold',
          totalPoints: 1250,
          registeredAt: DateTime(2025, 1, 15),
          expiredAt: DateTime(2027, 1, 15),
          isActive: true,
        ),
        MemberModel(
          id: 2,
          memberCode: 'MBR-002',
          fullName: 'Siti Rahayu',
          phone: '082345678901',
          email: 'siti@email.com',
          membershipType: 'silver',
          totalPoints: 580,
          registeredAt: DateTime(2025, 3, 20),
          expiredAt: DateTime(2026, 9, 20),
          isActive: true,
        ),
        MemberModel(
          id: 3,
          memberCode: 'MBR-003',
          fullName: 'Ahmad Fauzi',
          phone: '083456789012',
          email: 'ahmad@email.com',
          membershipType: 'platinum',
          totalPoints: 3400,
          registeredAt: DateTime(2024, 6, 10),
          expiredAt: DateTime(2027, 6, 10),
          isActive: true,
        ),
        MemberModel(
          id: 4,
          memberCode: 'MBR-004',
          fullName: 'Dewi Kurnia',
          phone: '084567890123',
          email: '',
          membershipType: 'regular',
          totalPoints: 90,
          registeredAt: DateTime(2026, 2, 5),
          isActive: true,
        ),
        MemberModel(
          id: 5,
          memberCode: 'MBR-005',
          fullName: 'Rizky Pratama',
          phone: '085678901234',
          email: 'rizky@email.com',
          membershipType: 'silver',
          totalPoints: 420,
          registeredAt: DateTime(2025, 8, 12),
          expiredAt: DateTime(2026, 8, 12),
          isActive: false,
        ),
      ];

  // ── Vouchers ──────────────────────────────────────────────
  static List<VoucherModel> get vouchers => [
        VoucherModel(
          id: 'mock-1',
          code: 'GAME10',
          name: 'Voucher Diskon 10%',
          discountType: 'percentage',
          discountValue: 10,
          minPurchase: 20000,
          maxUsage: 100,
          usageCount: 37,
          expiresAt: DateTime(2026, 12, 31),
          isActive: true,
        ),
        VoucherModel(
          id: 'mock-2',
          code: 'BYONE5K',
          name: 'Potongan Rp 5.000',
          discountType: 'fixed_amount',
          discountValue: 5000,
          minPurchase: 15000,
          maxUsage: 50,
          usageCount: 12,
          expiresAt: DateTime(2026, 7, 31),
          isActive: true,
        ),
        VoucherModel(
          id: 'mock-3',
          code: 'NEWMEMBER',
          name: 'Member Baru 20%',
          discountType: 'percentage',
          discountValue: 20,
          minPurchase: 30000,
          maxUsage: 200,
          usageCount: 200,
          expiresAt: DateTime(2026, 4, 30),
          isActive: false,
        ),
      ];
}
