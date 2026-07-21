class ApiConfig {
  static String baseUrl = 'http://localhost:8080/api/v1';

  /// Token khusus client display (Android TV).
  /// Kosongkan jika endpoint overview sudah public (tanpa auth).
  /// Jika backend tetap butuh auth, isi token yang di-generate khusus client.
  static const String clientToken = '';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

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

  // Notifications (promosi TV)
  static const String notifications = '/notifications';
  static const String notificationsLoopStart = '/notifications/loop/start';
  static const String notificationsLoopStop = '/notifications/loop/stop';

  // Activities (recent timeline)
  static const String activitiesRecent = '/activities/recent';

  // Reports
  static const String reportSummary = '/reports/summary';

  // Payments
  static const String payments = '/payments';

  // Shifts
  static const String shifts = '/shifts';

  // Users
  static const String users = '/users';

  // Vouchers (diskon berbasis kode)
  static const String vouchers = '/vouchers';
  static const String voucherByCode = '/vouchers/code';

  // Discount Rules (aturan diskon otomatis)
  static const String discounts = '/discounts';
  static const String activeDiscounts = '/discounts/active';

  // Menu
  static const String menus = '/menus';
  static const String availableMenus = '/menus/available';

  // Food Orders
  static const String foodOrders = '/food-orders';

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
