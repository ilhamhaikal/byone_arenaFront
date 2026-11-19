import '../models/user_model.dart';

/// Katalog izin (permission) terpusat untuk menu & aksi sensitif.
///
/// Key di sini HARUS sama dengan katalog di backend
/// (`internal/domain/entity/permission.go`). Saat menambah menu baru,
/// tambahkan key + label di sini agar otomatis muncul di form Manajemen User.
class AppPermission {
  final String key;
  final String label;

  const AppPermission(this.key, this.label);
}

/// Menu yang bisa diatur hak aksesnya. Urutan mengikuti sidebar.
const List<AppPermission> kMenuPermissions = [
  AppPermission('dashboard', 'Dashboard'),
  AppPermission('rental', 'Rental'),
  AppPermission('console', 'Konsol'),
  AppPermission('tv_log', 'Log TV'),
  AppPermission('member', 'Member'),
  AppPermission('discount', 'Diskon'),
  AppPermission('voucher', 'Voucher'),
  AppPermission('promo_bonus', 'Bonus Waktu'),
  AppPermission('menu', 'Menu'),
  AppPermission('food_order', 'Pesanan'),
  AppPermission('notif', 'Notifikasi'),
  AppPermission('report', 'Laporan'),
  AppPermission('booking', 'Booking'),
  AppPermission('rental_harian', 'Rental Harian'),
  AppPermission('user_management', 'User'),
  AppPermission('controller', 'Controller'),
];

/// Izin aksi sensitif — hanya superadmin yang boleh memberikan.
const List<AppPermission> kSensitivePermissions = [
  AppPermission('member_price', 'Harga Member'),
  AppPermission('daily_price', 'Harga Harian'),
  AppPermission('console.price', 'Harga Konsol'),
];

/// Menu yang punya aksi tambah/ubah/hapus. Menu read-only (Dashboard, Log TV,
/// Laporan, Controller) tidak punya izin aksi.
const List<String> kWritableMenuKeys = [
  'rental',
  'console',
  'member',
  'discount',
  'voucher',
  'promo_bonus',
  'menu',
  'food_order',
  'notif',
  'booking',
  'rental_harian',
  'user_management',
];

/// Menu yang memiliki aksi hapus data. Menu operasional seperti Rental,
/// Booking, dan Rental Harian tidak punya tombol hapus (koreksi dilakukan
/// lewat ubah status / pembatalan).
const List<String> kDeletableMenuKeys = [
  'console',
  'member',
  'discount',
  'voucher',
  'promo_bonus',
  'menu',
  'food_order',
  'notif',
  'user_management',
];

/// Default kasir: Dashboard, seluruh menu Rental & Penjualan, Konsol, Member,
/// dan Controller. Tanpa Log TV, Notifikasi, Diskon, Voucher, Bonus Waktu,
/// Laporan, Manajemen User, dan Lisensi.
const List<String> _kasirDefaultKeys = [
  'dashboard',
  'rental',
  'console',
  'member',
  'menu',
  'food_order',
  'booking',
  'rental_harian',
  'controller',
];

/// Menu yang boleh diubah kasir secara default (Menu/Bahan hanya lihat).
const List<String> _kasirWriteMenus = [
  'rental',
  'console',
  'member',
  'food_order',
  'booking',
  'rental_harian',
];

/// Menu yang boleh dihapus kasir — hanya Konsol (CRUD penuh).
const List<String> _kasirDeleteMenus = ['console'];

String _writeKey(String menu) => '$menu.write';
String _deleteKey(String menu) => '$menu.delete';

List<String> _allActionKeys() {
  return [
    for (final menu in kWritableMenuKeys) ...[
      _writeKey(menu),
      _deleteKey(menu),
    ],
  ];
}

/// Default izin untuk sebuah role.
List<String> defaultPermissionsForRole(String role) {
  switch (role) {
    case 'superadmin':
      return [
        ...kMenuPermissions.map((p) => p.key),
        ..._allActionKeys(),
        ...kSensitivePermissions.map((p) => p.key),
      ];
    case 'admin':
      // Admin: semua menu + aksi + pengaturan harga, kecuali Lisensi.
      return [
        ...kMenuPermissions.map((p) => p.key),
        ..._allActionKeys(),
        ...kSensitivePermissions.map((p) => p.key),
      ];
    default:
      return [
        ..._kasirDefaultKeys,
        ..._kasirWriteMenus.map(_writeKey),
        ..._kasirDeleteMenus.map(_deleteKey),
      ];
  }
}

/// Apakah user boleh melihat menu dengan [permKey].
///
/// Superadmin selalu mendapat semua menu (sama seperti middleware backend).
/// Menu Lisensi tidak pernah bisa diberikan lewat permission.
bool canAccessNav(UserModel? user, String permKey) {
  if (user == null) return false;

  if (permKey == 'license') {
    return user.role == 'superadmin';
  }
  if (user.role == 'superadmin') {
    return true;
  }

  final perms = user.permissions;
  if (perms.isEmpty) {
    // Fallback untuk user lama yang belum punya permissions eksplisit.
    return defaultPermissionsForRole(user.role).contains(permKey);
  }
  return perms.contains(permKey);
}

/// Apakah user boleh mengubah pengaturan sensitif (mis. harga member).
bool canEditPermission(UserModel? user, String permission) {
  if (user == null) return false;
  if (user.role == 'superadmin') return true;
  return user.permissions.contains(permission);
}

bool _hasPermission(UserModel user, String key) {
  final perms = user.permissions;
  if (perms.isEmpty) {
    return defaultPermissionsForRole(user.role).contains(key);
  }
  return perms.contains(key);
}

/// Apakah user boleh menambah/mengubah data pada [menuKey]
/// (mis. `canWriteMenu(user, 'member')`).
///
/// User harus punya akses lihat ke menu tersebut DAN izin `<menu>.write`.
bool canWriteMenu(UserModel? user, String menuKey) {
  if (user == null) return false;
  if (user.role == 'superadmin') return true;
  if (!canAccessNav(user, menuKey)) return false;
  return _hasPermission(user, _writeKey(menuKey));
}

/// Apakah user boleh menghapus data pada [menuKey].
bool canDeleteMenu(UserModel? user, String menuKey) {
  if (user == null) return false;
  if (user.role == 'superadmin') return true;
  if (!canAccessNav(user, menuKey)) return false;
  return _hasPermission(user, _deleteKey(menuKey));
}
