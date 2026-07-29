import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/shift_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/shift_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});
  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadAll();
    });
  }

  void _openForm([UserModel? user]) {
    showDialog(context: context, builder: (_) => UserFormDialog(user: user));
  }

  void _openPasswordDialog() {
    showDialog(context: context, builder: (_) => const ChangePasswordDialog());
  }

  Future<void> _deleteUser(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Hapus User', style: TextStyle(color: kTextPrimary)),
        content: Text('Hapus ${user.fullName} (@${user.username})?',
            style: const TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final success = await context.read<UserProvider>().delete(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'User dihapus' : context.read<UserProvider>().error ?? 'Gagal'),
          backgroundColor: success ? kSuccessColor : kErrorColor,
        ));
      }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'superadmin': return kAccentPurple;
      case 'admin': return kPrimaryBlue;
      case 'kasir': return kSuccessColor;
      default: return kTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Manajemen User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded),
            tooltip: 'Ganti Password',
            onPressed: _openPasswordDialog,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: kGradientBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
            ),
            tooltip: 'Tambah User',
            onPressed: _openForm,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, p, _) {
          if (p.isLoading && p.users.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (p.users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 56, color: kTextSecondary),
                  SizedBox(height: 12),
                  Text('Belum ada user', style: TextStyle(color: kTextSecondary, fontSize: 14)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: kPrimaryBlue,
            onRefresh: p.loadAll,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: p.users.length,
              itemBuilder: (_, i) => _UserCard(
                user: p.users[i],
                onEdit: () => _openForm(p.users[i]),
                onDelete: () => _deleteUser(p.users[i]),
                roleColor: _roleColor(p.users[i].role),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color roleColor;

  const _UserCard({required this.user, required this.onEdit, required this.onDelete, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [roleColor, roleColor.withAlpha(150)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(user.fullName,
                        style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: roleColor.withAlpha(25), borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: roleColor.withAlpha(60))),
                      child: Text(user.roleLabel, style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text('@${user.username}', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                  if (!user.isActive)
                    const Text('Nonaktif', style: TextStyle(color: kErrorColor, fontSize: 10)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: kTextSecondary, size: 20),
              onSelected: (v) { if (v == 'edit') onEdit(); if (v == 'delete') onDelete(); },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16, color: kPrimaryBlue), SizedBox(width: 8), Text('Edit')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: kErrorColor), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: kErrorColor))])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form Dialog ─────────────────────────────────────────────────────────────
class UserFormDialog extends StatefulWidget {
  final UserModel? user;
  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl, _fullNameCtrl, _passwordCtrl;
  String _role = 'kasir';
  bool _isActive = true;
  bool _isLoading = false;
  final Set<String> _permissions = {};
  final _shiftService = ShiftService();
  List<ShiftModel> _shifts = [];
  bool _shiftsLoaded = false;
  bool get _isEdit => widget.user != null;

  // Map: label tampilan → key permission di database
  static const _allMenuLabels = {
    'Dashboard': 'dashboard',
    'Rental': 'rental',
    'Konsol': 'console',
    'Log TV': 'tv_log',
    'Member': 'member',
    'Diskon': 'discount',
    'Voucher': 'voucher',
    'Menu': 'menu',
    'Pesanan': 'food_order',
    'Notif': 'notif',
    'Laporan': 'report',
    'Booking': 'booking',
    'Rental Harian': 'rental_harian',
    'User': 'user_management',
  };

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user?.username ?? '');
    _fullNameCtrl = TextEditingController(text: widget.user?.fullName ?? '');
    _passwordCtrl = TextEditingController();
    _role = widget.user?.role ?? 'kasir';
    _isActive = widget.user?.isActive ?? true;
    if (widget.user != null && widget.user!.permissions.isNotEmpty) {
      _permissions.addAll(widget.user!.permissions);
    }
    if (widget.user != null && widget.user!.role == 'kasir') {
      _loadShifts();
    }
  }

  Future<void> _loadShifts() async {
    if (widget.user == null) return;
    try {
      _shifts = await _shiftService.getByUser(widget.user!.id);
      _shiftsLoaded = true;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameCtrl.dispose(); _fullNameCtrl.dispose(); _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'username': _usernameCtrl.text.trim(),
      'fullName': _fullNameCtrl.text.trim(),
      'isActive': _isActive,
    };
    if (_passwordCtrl.text.isNotEmpty) data['password'] = _passwordCtrl.text;
    // Kirim role & permissions (backend validasi hierarki)
    data['role'] = _role;
    data['permissions'] = _permissions.toList();

    final provider = context.read<UserProvider>();
    final success = _isEdit
        ? await provider.update(widget.user!.id, data)
        : await provider.create(data);

    if (success && _role == 'kasir' && _shifts.isNotEmpty) {
      // Ambil userId: untuk edit pakai ID existing, untuk create ambil dari user baru
      String? userId;
      if (_isEdit) {
        userId = widget.user!.id;
      } else {
        // User baru sudah ditambahkan ke provider.users di index 0
        userId = provider.users.isNotEmpty ? provider.users.first.id : null;
        final match = provider.users.where((u) => u.username == _usernameCtrl.text.trim()).toList();
        if (match.isNotEmpty) userId = match.first.id;
      }
      if (userId != null) {
        for (final s in _shifts) {
          try {
            if (s.id.isEmpty) {
              await _shiftService.create(
                userId: userId,
                name: s.name,
                startHour: s.startHour,
                endHour: s.endHour,
                is24Hour: s.is24Hour,
              );
            } else {
              await _shiftService.update(s.id, s.toJson());
            }
          } catch (_) {}
        }
      }
    }

    setState(() => _isLoading = false);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'User diperbarui' : 'User ditambahkan'),
          backgroundColor: kSuccessColor,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.error ?? 'Gagal menyimpan'),
          backgroundColor: kErrorColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final currentRole = auth.user?.role ?? '';
    final currentId = auth.user?.id ?? '';
    final targetRole = widget.user?.role ?? _role;
    final isSelfEdit = _isEdit && widget.user!.id == currentId;

    // Superadmin bisa semua, admin hanya bisa kelola kasir
    final canEditPerms = currentRole == 'superadmin' ||
        (currentRole == 'admin' && targetRole == 'kasir');
    // Admin tidak bisa ubah role diri sendiri
    final canEditRole = canEditPerms && !(isSelfEdit && currentRole == 'admin');

    return AlertDialog(
      backgroundColor: kSurface,
      title: Text(_isEdit ? 'Edit User' : 'Tambah User', style: const TextStyle(color: kTextPrimary)),
      content: SizedBox(width: 380, child: Form(key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _fullNameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _passwordCtrl, obscureText: true,
                decoration: InputDecoration(labelText: _isEdit ? 'Password Baru (kosongkan jika tidak diubah)' : 'Password', prefixIcon: const Icon(Icons.lock_outlined)),
                validator: _isEdit ? null : (v) => v == null || v.isEmpty ? 'Wajib diisi' : null),
            const SizedBox(height: 12),
            if (canEditRole)
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                dropdownColor: kCardColor,
                items: const [
                  DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'superadmin', child: Text('Super Admin')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              )
            else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Role', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                subtitle: Text(
                  _role == 'superadmin' ? 'Super Admin' : _role == 'admin' ? 'Admin' : 'Kasir',
                  style: const TextStyle(color: kTextPrimary, fontSize: 14),
                ),
                dense: true,
              ),
            ],
            if (_isEdit) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Aktif', style: TextStyle(color: kTextPrimary, fontSize: 14)),
                value: _isActive,
                activeColor: kSuccessColor,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
            // ── Shift (hanya untuk kasir) ──
            if (_role == 'kasir') ...[
              const SizedBox(height: 16),
              const Divider(color: kBorderColor),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Shift Kerja', style: TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addShift,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: kPrimaryBlue, padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ]),
              if (_shifts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kCardColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Belum ada shift. Kasir tidak bisa login tanpa shift aktif.',
                      style: TextStyle(color: kTextSecondary, fontSize: 11)),
                )
              else
                ..._shifts.map((s) => _ShiftCard(
                      shift: s,
                      onDelete: () => _removeShift(s),
                      onEdit: (name, start, end, is24) => _editShift(s, name, start, end, is24),
                    )),
              const SizedBox(height: 8),
            ],
            if (canEditPerms) ...[
              const SizedBox(height: 12),
              const Text('Hak Akses Menu:', style: TextStyle(color: kTextSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8, runSpacing: 4,
                children: _allMenuLabels.entries.map((entry) {
                  final label = entry.key;
                  final key = entry.value;
                  final checked = _permissions.contains(key);
                  return FilterChip(
                    selected: checked,
                    label: Text(label, style: TextStyle(fontSize: 11, color: checked ? Colors.white : kTextSecondary)),
                    selectedColor: kPrimaryBlue,
                    checkmarkColor: Colors.white,
                    backgroundColor: kCardColor,
                    side: BorderSide(color: checked ? kPrimaryBlue : kBorderColor),
                    onSelected: (v) {
                      setState(() {
                        if (v) { _permissions.add(key); } else { _permissions.remove(key); }
                      });
                    },
                  );
                }).toList(),
              ),
            ] else ...[
              // Tampilkan info + daftar hak akses (read-only)
              const SizedBox(height: 12),
              const Text('Hak Akses Menu:', style: TextStyle(color: kTextSecondary, fontSize: 12)),
              if (isSelfEdit && currentRole == 'admin')
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kCardColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, size: 16, color: kTextSecondary),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'Hak akses menu Anda hanya dapat diubah oleh Super Admin.',
                      style: TextStyle(color: kTextSecondary, fontSize: 11),
                    )),
                  ]),
                ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8, runSpacing: 4,
                children: _allMenuLabels.entries.map((entry) {
                  final label = entry.key;
                  final key = entry.value;
                  final checked = _permissions.contains(key);
                  return FilterChip(
                    selected: checked,
                    label: Text(label, style: TextStyle(fontSize: 11, color: checked ? Colors.white : kTextSecondary)),
                    selectedColor: checked ? kPrimaryBlue : kTextSecondary,
                    checkmarkColor: Colors.white,
                    backgroundColor: kCardColor,
                    side: BorderSide(color: checked ? kPrimaryBlue : kBorderColor),
                    onSelected: null, // read-only
                  );
                }).toList(),
              ),
            ],
          ]),
        ),
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan'),
        ),
      ],
    );
  }

  // ── Shift helpers ──────────────────────────────────────────────────────
  void _addShift() => _showShiftDialog();

  void _editShift(ShiftModel shift, String name, int start, int end, bool is24) {
    _showShiftDialog(shift: shift, name: name, start: start, end: end, is24: is24);
  }

  void _removeShift(ShiftModel shift) {
    setState(() => _shifts.removeWhere((s) => s.id == shift.id));
  }

  void _showShiftDialog({ShiftModel? shift, String name = '', int start = 8, int end = 16, bool is24 = false}) {
    final nameCtrl = TextEditingController(text: shift?.name ?? name);
    var startHour = shift?.startHour ?? start;
    var endHour = shift?.endHour ?? end;
    var is24Hour = shift?.is24Hour ?? is24;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          backgroundColor: kSurface,
          title: Text(shift != null ? 'Edit Shift' : 'Tambah Shift', style: const TextStyle(color: kTextPrimary)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Shift', hintText: 'Contoh: Shift Pagi'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: startHour,
                  decoration: const InputDecoration(labelText: 'Jam Mulai'),
                  dropdownColor: kCardColor,
                  items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2, '0')}:00'))),
                  onChanged: (v) => setInner(() => startHour = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: endHour,
                  decoration: const InputDecoration(labelText: 'Jam Selesai'),
                  dropdownColor: kCardColor,
                  items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2, '0')}:00'))),
                  onChanged: (v) => setInner(() => endHour = v!),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('24 Jam', style: TextStyle(color: kTextPrimary, fontSize: 13)),
              value: is24Hour,
              activeColor: kSuccessColor,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setInner(() => is24Hour = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            if (shift != null)
              TextButton(
                onPressed: () {
                  _removeShift(shift);
                  Navigator.pop(ctx);
                },
                child: const Text('Hapus', style: TextStyle(color: kErrorColor)),
              ),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                final newShift = ShiftModel(
                  id: shift?.id ?? '',
                  userId: widget.user?.id ?? '',
                  name: nameCtrl.text.isEmpty ? 'Shift' : nameCtrl.text,
                  startHour: startHour,
                  endHour: endHour,
                  is24Hour: is24Hour,
                  status: 'active',
                  createdAt: shift?.createdAt ?? now,
                  updatedAt: now,
                );
                setState(() {
                  if (shift != null) {
                    final idx = _shifts.indexWhere((s) => s.id == shift.id);
                    if (idx >= 0) _shifts[idx] = newShift;
                  } else {
                    _shifts.add(newShift);
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shift Card widget ───────────────────────────────────────────────────
class _ShiftCard extends StatelessWidget {
  final ShiftModel shift;
  final VoidCallback onDelete;
  final void Function(String name, int start, int end, bool is24) onEdit;
  const _ShiftCard({required this.shift, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(
            color: shift.isActive ? kSuccessColor : kTextSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shift.name, style: const TextStyle(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(shift.scheduleLabel, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 16, color: kTextSecondary),
          onPressed: () => onEdit(shift.name, shift.startHour, shift.endHour, shift.is24Hour),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 16, color: kErrorColor),
          onPressed: onDelete,
          padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        ),
      ]),
    );
  }
}

// ── Change Password Dialog ──────────────────────────────────────────────────
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});
  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final success = await context.read<UserProvider>().changePassword(_oldCtrl.text, _newCtrl.text);
    setState(() => _isLoading = false);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah'), backgroundColor: kSuccessColor));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<UserProvider>().error ?? 'Gagal mengubah password'),
          backgroundColor: kErrorColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil nama user yang sedang login dari AuthProvider
    final currentUser = context.read<AuthProvider>().user?.fullName ?? 'User';
    return AlertDialog(
      backgroundColor: kSurface,
      title: const Text('Ganti Password', style: TextStyle(color: kTextPrimary)),
      content: SizedBox(width: 350, child: Form(key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Info user yang sedang login
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimaryBlue.withAlpha(40)),
            ),
            child: Row(children: [
              const Icon(Icons.person_rounded, size: 16, color: kPrimaryBlue),
              const SizedBox(width: 8),
              Text('Ganti password untuk: $currentUser',
                  style: const TextStyle(color: kTextPrimary, fontSize: 13)),
            ]),
          ),
          TextFormField(controller: _oldCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Lama', prefixIcon: Icon(Icons.lock_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _newCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru', prefixIcon: Icon(Icons.lock_rounded)),
              validator: (v) => v == null || v.length < 6 ? 'Minimal 6 karakter' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _confirmCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru', prefixIcon: Icon(Icons.lock_rounded)),
              validator: (v) => v != _newCtrl.text ? 'Password tidak cocok' : null),
        ]),
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan'),
        ),
      ],
    );
  }
}
