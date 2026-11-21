import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/console_model.dart';
import '../../models/tv_notification_model.dart';
import '../../providers/console_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_dialog.dart';

class NotificationFormDialog extends StatefulWidget {
  final TvNotificationModel? notification;
  const NotificationFormDialog({super.key, this.notification});

  @override
  State<NotificationFormDialog> createState() => _NotificationFormDialogState();
}

class _NotificationFormDialogState extends State<NotificationFormDialog> {
  final _form = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _intervalCtrl = TextEditingController(text: '30');
  String _priority = 'normal';
  bool _loopEnabled = false;
  bool _targetAll = true;
  bool _activeSessionsOnly = false;
  bool _autoShow = false;
  bool _isLoading = false;

  // Target konsol spesifik. Sebelumnya form hanya punya switch "Semua
  // Konsol" tanpa cara memilih konsol, sehingga mematikan switch menghasilkan
  // notifikasi yang tidak pernah terkirim ke TV mana pun.
  final Set<String> _targetConsoleIds = {};
  List<ConsoleModel> _consoles = const [];
  bool _consolesLoading = false;
  String? _consolesError;
  String? _targetError;

  bool get _isEdit => widget.notification != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final n = widget.notification!;
      _titleCtrl.text = n.title;
      _messageCtrl.text = n.message;
      _imageUrlCtrl.text = n.imageUrl ?? '';
      _intervalCtrl.text = n.loopInterval.toString();
      // DB lama mengizinkan priority 'urgent' yang tidak ada di dropdown.
      // Normalisasi agar form tidak crash karena item tidak ditemukan.
      _priority = const ['low', 'normal', 'high'].contains(n.priority)
          ? n.priority
          : 'normal';
      _autoShow = n.autoShow;
      _loopEnabled = n.autoShow ? n.loopEnabled : false;
      _targetAll = n.targetAll;
      _activeSessionsOnly = n.activeSessionsOnly;
      _targetConsoleIds.addAll(n.targetConsoleIds);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConsoles());
  }

  Future<void> _loadConsoles() async {
    final cp = context.read<ConsoleProvider>();
    if (cp.consoles.isNotEmpty) {
      setState(() {
        _consoles = cp.consoles;
        _pruneDeletedConsoleTargets();
      });
      return;
    }
    setState(() => _consolesLoading = true);
    await cp.loadAll();
    if (!mounted) return;
    setState(() {
      _consoles = cp.consoles;
      _consolesError = cp.error;
      _consolesLoading = false;
      _pruneDeletedConsoleTargets();
    });
  }

  /// Target konsol yang sudah dihapus tidak boleh tersisa — kalau tersisa,
  /// request update akan ditolak backend karena UUID-nya tidak valid.
  void _pruneDeletedConsoleTargets() {
    // Saat daftar gagal dimuat, jangan hapus target: daftar kosong belum
    // tentu berarti konsolnya benar-benar sudah dihapus.
    if (_consolesError != null) return;
    final validIds = _consoles.map((c) => c.id).toSet();
    _targetConsoleIds.removeWhere((id) => !validIds.contains(id));
    if (_targetConsoleIds.isNotEmpty) _targetError = null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _imageUrlCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_targetAll && _targetConsoleIds.isEmpty) {
      setState(() => _targetError = 'Pilih minimal satu konsol tujuan');
      return;
    }
    setState(() {
      _isLoading = true;
      _targetError = null;
    });
    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'message': _messageCtrl.text.trim(),
      if (_imageUrlCtrl.text.trim().isNotEmpty)
        'imageUrl': _imageUrlCtrl.text.trim(),
      'priority': _priority,
      'loopEnabled': _autoShow && _loopEnabled,
      'loopInterval': int.tryParse(_intervalCtrl.text.trim()) ?? 30,
      'targetAll': _targetAll,
      'activeSessionsOnly': _activeSessionsOnly,
      'autoShow': _autoShow,
      if (!_targetAll) 'consoleIds': _targetConsoleIds.toList(),
    };
    final p = context.read<NotificationProvider>();
    final ok = _isEdit
        ? await p.update(widget.notification!.id, data)
        : await p.create(data);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      Navigator.pop(context);
      showSuccessDialog(
        _isEdit ? 'Notifikasi berhasil diperbarui.' : 'Notifikasi berhasil dibuat.',
        title: _isEdit ? 'Notifikasi Diperbarui' : 'Notifikasi Dibuat',
      );
    } else {
      showErrorDialog(p.error ?? 'Gagal menyimpan notifikasi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Notifikasi' : 'Buat Notifikasi'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  maxLength: 100,
                  decoration: const InputDecoration(
                      labelText: 'Judul *', prefixIcon: Icon(Icons.title)),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return 'Wajib diisi';
                    if (text.length < 2) return 'Minimal 2 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _messageCtrl,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                      labelText: 'Pesan *',
                      prefixIcon: Icon(Icons.message_outlined)),
                  maxLines: 3,
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return 'Wajib diisi';
                    if (text.length < 2) return 'Minimal 2 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _imageUrlCtrl,
                  decoration: const InputDecoration(
                      labelText: 'URL Gambar (opsional)',
                      prefixIcon: Icon(Icons.image_outlined)),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final uri = Uri.tryParse(text);
                    if (uri == null ||
                        !(uri.isScheme('http') || uri.isScheme('https'))) {
                      return 'Gunakan URL http/https yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                      labelText: 'Prioritas',
                      prefixIcon: Icon(Icons.flag_outlined)),
                  dropdownColor: kCardColor,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Rendah')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'high', child: Text('Tinggi')),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? 'normal'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Tampilkan Otomatis',
                      style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                    'Jika mati, pesan hanya muncul saat tombol Tampilkan ditekan',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _autoShow,
                  onChanged: (v) => setState(() {
                    _autoShow = v;
                    if (!v) _loopEnabled = false;
                  }),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_autoShow)
                  SwitchListTile(
                    title:
                        const Text('Looping', style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                        'Tampilkan berulang selama notifikasi aktif',
                        style: TextStyle(fontSize: 11)),
                    value: _loopEnabled,
                    onChanged: (v) => setState(() => _loopEnabled = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                if (_autoShow && _loopEnabled)
                  TextFormField(
                    controller: _intervalCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Interval (detik)',
                        prefixIcon: Icon(Icons.timer_outlined)),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null) return 'Harus berupa angka';
                      if (n < 5) return 'Minimal 5 detik';
                      if (n > 3600) return 'Maksimal 3600 detik';
                      return null;
                    },
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Semua Konsol',
                      style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                      'Kirim ke seluruh TV, termasuk yang sedang idle',
                      style: TextStyle(fontSize: 11)),
                  value: _targetAll,
                  onChanged: (v) => setState(() {
                    _targetAll = v;
                    _targetError = null;
                  }),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_targetAll) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Pilih konsol tujuan *',
                        style: TextStyle(
                            fontSize: 12,
                            color: _targetError == null
                                ? kTextSecondary
                                : kErrorColor)),
                  ),
                  const SizedBox(height: 6),
                  if (_consolesLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  else if (_consolesError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Gagal memuat daftar konsol: $_consolesError',
                        style: const TextStyle(
                            fontSize: 11, color: kErrorColor),
                      ),
                    )
                  else if (_consoles.isEmpty)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Belum ada konsol terdaftar.',
                        style: TextStyle(
                            fontSize: 11, color: kTextSecondary),
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _consoles
                            .map((c) => FilterChip(
                                  label: Text(c.name,
                                      style: const TextStyle(fontSize: 11)),
                                  selected:
                                      _targetConsoleIds.contains(c.id),
                                  onSelected: (selected) => setState(() {
                                    if (selected) {
                                      _targetConsoleIds.add(c.id);
                                    } else {
                                      _targetConsoleIds.remove(c.id);
                                    }
                                    _targetError = null;
                                  }),
                                ))
                            .toList(),
                      ),
                    ),
                  if (_targetError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_targetError!,
                            style: const TextStyle(
                                fontSize: 11, color: kErrorColor)),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                SwitchListTile(
                  title: const Text('Hanya Sesi Aktif',
                      style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                      'Lewati TV yang tidak sedang dipakai sesi rental',
                      style: TextStyle(fontSize: 11)),
                  value: _activeSessionsOnly,
                  onChanged: (v) => setState(() => _activeSessionsOnly = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _save,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_rounded, size: 16),
          label: Text(_isEdit ? 'Simpan' : 'Buat'),
        ),
      ],
    );
  }
}
