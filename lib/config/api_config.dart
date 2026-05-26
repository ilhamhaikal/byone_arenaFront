class ApiConfig {
  static String baseUrl = 'http://localhost:8080/api/v1';

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

  // Legacy mock (belum ada di backend)
  static const String members = '/members';
  static const String rentals = '/rentals';
}
