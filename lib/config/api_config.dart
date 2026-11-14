import 'platform_config.dart';

class ApiConfig {
  /// Gunakan [PlatformConfig.baseUrl] — bisa di-override via:
  /// 1. `--dart-define=API_BASE_URL=http://192.168.1.100:8080/api/v1` saat build
  /// 2. `PlatformConfig.setBaseUrl(...)` saat runtime (mis. dari settings screen)
  static String get baseUrl => PlatformConfig.baseUrl;

  /// Token khusus client display (Android TV).
  /// Kosongkan jika endpoint overview sudah public (tanpa auth).
  /// Jika backend tetap butuh auth, isi token yang di-generate khusus client.
  static const String clientToken = '';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Consoles
  static const String consoles = '/consoles';
  static const String availableConsoles = '/consoles/available';
  static const String consolesOverview = '/consoles/overview';

  // Customers
  static const String customers = '/customers';

  // Sessions
  static const String sessions = '/sessions';
  static const String activeSessions = '/sessions/active';
  static const String startSession = '/sessions/start';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';
  static const String dashboardRevenueChart = '/dashboard/revenue-chart';

  // Notifications (promosi TV)
  static const String notifications = '/notifications';
  static const String notificationsLoopStart = '/notifications/loop/start';
  static const String notificationsLoopStop = '/notifications/loop/stop';

  // Activities (recent timeline)
  static const String activitiesRecent = '/activities/recent';

  // Reports
  static const String reportSummary = '/reports/summary';

  // Capital (pembukuan modal awal)
  static const String capital = '/capital';
  static const String capitalMonthly = '/capital/monthly';

  // Rental Packages (paket begadang dll)
  static const String rentalPackages = '/rental-packages';
  static const String startSessionPackage = '/sessions/start-package';

  // Payments
  static const String payments = '/payments';

  // Users
  static const String users = '/users';
  static const String usersChangePassword = '/users/change-password';

  // Shifts
  static const String shifts = '/shifts';

  // Vouchers (diskon berbasis kode)
  static const String vouchers = '/vouchers';
  static const String voucherByCode = '/vouchers/code';

  // Discount Rules (aturan diskon otomatis)
  static const String discounts = '/discounts';

  // Food Orders
  static const String foodOrders = '/food-orders';
  static const String activeDiscounts = '/discounts/active';

  // Menu
  static const String menus = '/menus';
  static const String availableMenus = '/menus/available';

  // Ingredients (bahan baku)
  static const String ingredients = '/ingredients';

  // Booking (reservasi)
  static const String bookings = '/bookings';

  // Daily Rental (rental harian / console dibawa pulang)
  static const String dailyRentals = '/daily-rentals';

  // Settings (pengaturan global)
  static const String membershipSettings = '/settings/membership';
  static const String dailyPriceSettings = '/settings/daily-price';

  // Legacy mock (belum ada di backend)
  static const String members = '/members';
  static const String rentals = '/rentals';
}
