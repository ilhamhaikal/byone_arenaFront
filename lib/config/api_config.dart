class ApiConfig {
  static String baseUrl = 'http://localhost:8080/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Consoles
  static const String consoles = '/consoles';
  static const String availableConsoles = '/consoles/available';

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

  // Legacy mock endpoints (discount/voucher/member — belum ada di backend)
  static const String discounts = '/discounts';
  static const String vouchers = '/vouchers';
  static const String members = '/members';
  static const String rentals = '/rentals';
  static const String validateVoucher = '/vouchers/validate';
}
