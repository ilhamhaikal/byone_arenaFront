import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/membership_settings_provider.dart';

class MemberFormDialog extends StatefulWidget {
  final CustomerModel? customer;

  const MemberFormDialog({super.key, this.customer});

  @override
  State<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  bool _isMember = false;
  bool _isLoading = false;
  bool _isSellingMembership = false;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _isMember = c?.isMember ?? false;
    // Load global membership price
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MembershipSettingsProvider>().loadPrice();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sellMembership() async {
    final settingsP = context.read<MembershipSettingsProvider>();
    final price = settingsP.price;

    // Konfirmasi sebelum jual
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Penjualan Membership'),
        content: Text(
            'Jual membership ke ${widget.customer!.name}?\n\n'
            'Harga: Rp ${price.toInt()}\n'
            'Status: Lifetime (selamanya)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kAccentPurple),
            child: const Text('Ya, Jual'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSellingMembership = true);
    final provider = context.read<CustomerProvider>();
    final result = await provider.sellMembership(widget.customer!.id);
    setState(() => _isSellingMembership = false);
    if (mounted) {
      if (result != null) {
        setState(() => _isMember = result.isMember);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Membership berhasil dijual!'),
          backgroundColor: kSuccessColor,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.error ?? 'Gagal menjual membership'),
          backgroundColor: kErrorColor,
        ));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = context.read<CustomerProvider>();
    if (_isEdit) {
      final ok = await provider.update(widget.customer!.id, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      });
      setState(() => _isLoading = false);
      if (mounted) {
        if (ok) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pelanggan berhasil diperbarui'),
            backgroundColor: kSuccessColor,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(provider.error ?? 'Gagal menyimpan'),
            backgroundColor: kErrorColor,
          ));
        }
      }
    } else {
      // ── Konfirmasi jika jual membership ──
      if (_isMember) {
        final settingsP = context.read<MembershipSettingsProvider>();
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Konfirmasi Penjualan Membership'),
            content: Text(
                'Tambah ${_nameCtrl.text.trim()} sebagai Member?\n\n'
                'Harga: Rp ${settingsP.price.toInt()}\n'
                'Status: Lifetime (selamanya)'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: kAccentPurple),
                child: const Text('Ya, Jual'),
              ),
            ],
          ),
        );
        if (confirm != true) {
          setState(() => _isLoading = false);
          return; // batal, tetap di form
        }
      }

      setState(() => _isLoading = true);

      // ── Create customer baru ──
      final newCustomer = await provider.create(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        isMember: _isMember,
      );

      setState(() => _isLoading = false);
      if (!mounted) return;

      if (newCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.error ?? 'Gagal menyimpan'),
          backgroundColor: kErrorColor,
        ));
        return;
      }

      Navigator.pop(context);

      // Reload list agar data dari server terbaru (hindari race condition)
      provider.loadAll();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isMember
            ? '${newCustomer.name} terdaftar sebagai Member!'
            : '${newCustomer.name} berhasil ditambahkan'),
        backgroundColor: kSuccessColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan'),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v == null || v.trim().length < 2
                      ? 'Nama minimal 2 karakter'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                      labelText: 'No. Telepon',
                      prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().length < 8
                      ? 'Nomor telepon minimal 8 karakter'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Email (opsional)',
                      prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                ),
                // ── Membership section ──
                const SizedBox(height: 16),
                Consumer<MembershipSettingsProvider>(
                  builder: (ctx, settingsP, _) {
                    final globalPrice = settingsP.price;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              const Icon(Icons.card_membership_rounded,
                                  size: 18, color: kAccentPurple),
                              const SizedBox(width: 8),
                              const Text('Membership',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: kTextPrimary)),
                              const Spacer(),
                              if (globalPrice > 0)
                                Text(
                                  'Rp ${globalPrice.toInt()}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: kNeonPink),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // ── Mode CREATE: toggle is_member ──
                          if (!_isEdit) ...[
                            const Text(
                              'Aktifkan jika customer langsung bayar membership.',
                              style: TextStyle(fontSize: 11, color: kTextSecondary),
                            ),
                            const SizedBox(height: 4),
                            Material(
                              color: Colors.transparent,
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Jadikan Member',
                                    style: TextStyle(fontSize: 13, color: kTextPrimary)),
                                subtitle: Text(
                                  _isMember
                                      ? 'Backend akan auto-charge dari harga settings'
                                      : 'Customer biasa (non-member)',
                                  style: const TextStyle(fontSize: 11, color: kTextSecondary),
                                ),
                                value: _isMember,
                                activeColor: kAccentPurple,
                                onChanged: (v) => setState(() => _isMember = v),
                              ),
                            ),
                          ],
                          // ── Mode EDIT: status member + tombol jual ──
                          if (_isEdit) ...[
                            if (_isMember)
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 16, color: kSuccessColor),
                                  SizedBox(width: 6),
                                  Text('Sudah Member (lifetime)',
                                      style: TextStyle(
                                          color: kSuccessColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ],
                              )
                            else ...[
                              const Text(
                                'Customer ini belum member.',
                                style: TextStyle(fontSize: 11, color: kTextSecondary),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isSellingMembership ? null : _sellMembership,
                                  icon: _isSellingMembership
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.sell_rounded, size: 18),
                                  label: Text(_isSellingMembership
                                      ? 'Memproses...'
                                      : 'Jual Membership'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kAccentPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}
