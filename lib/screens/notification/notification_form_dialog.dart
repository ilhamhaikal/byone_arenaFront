import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/tv_notification_model.dart';
import '../../providers/notification_provider.dart';

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
  bool _isLoading = false;

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
      _priority = n.priority;
      _loopEnabled = n.loopEnabled;
      _targetAll = n.targetAll;
      _activeSessionsOnly = n.activeSessionsOnly;
    }
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
    setState(() => _isLoading = true);
    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'message': _messageCtrl.text.trim(),
      if (_imageUrlCtrl.text.trim().isNotEmpty)
        'imageUrl': _imageUrlCtrl.text.trim(),
      'priority': _priority,
      'loopEnabled': _loopEnabled,
      'loopInterval': int.tryParse(_intervalCtrl.text) ?? 30,
      'targetAll': _targetAll,
      'activeSessionsOnly': _activeSessionsOnly,
    };
    final p = context.read<NotificationProvider>();
    final ok = _isEdit ? await p.update(widget.notification!.id, data) : await p.create(data);
    setState(() => _isLoading = false);
    if (mounted && ok) Navigator.pop(context);
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
                  decoration: const InputDecoration(labelText: 'Judul *', prefixIcon: Icon(Icons.title)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageCtrl,
                  decoration: const InputDecoration(labelText: 'Pesan *', prefixIcon: Icon(Icons.message_outlined)),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlCtrl,
                  decoration: const InputDecoration(labelText: 'URL Gambar (opsional)', prefixIcon: Icon(Icons.image_outlined)),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(labelText: 'Prioritas', prefixIcon: Icon(Icons.flag_outlined)),
                  dropdownColor: kCardColor,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Rendah')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'high', child: Text('Tinggi')),
                  ],
                  onChanged: (v) => setState(() => _priority = v!),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Looping', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Tampilkan berulang', style: TextStyle(fontSize: 11)),
                  value: _loopEnabled,
                  onChanged: (v) => setState(() => _loopEnabled = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_loopEnabled)
                  TextFormField(
                    controller: _intervalCtrl,
                    decoration: const InputDecoration(labelText: 'Interval (detik)', prefixIcon: Icon(Icons.timer_outlined)),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Semua Konsol', style: TextStyle(fontSize: 14)),
                  value: _targetAll,
                  onChanged: (v) => setState(() => _targetAll = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Hanya Sesi Aktif', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Hanya kirim ke TV yang sedang dipakai', style: TextStyle(fontSize: 11)),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _save,
          icon: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_rounded, size: 16),
          label: Text(_isEdit ? 'Simpan' : 'Buat'),
        ),
      ],
    );
  }
}
