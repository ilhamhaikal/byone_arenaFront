import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/console_model.dart';
import '../../providers/console_provider.dart';
import '../../services/api_service.dart';
import '../../services/device_pairing_service.dart';
import '../../utils/app_dialog.dart';

/// Dialog pairing TV: admin mengetik kode 6 digit yang tampil di layar TV,
/// lalu memilih konsol yang akan dihubungkan.
///
/// Mengembalikan `true` lewat Navigator.pop bila berhasil.
class ConnectTvDialog extends StatefulWidget {
  /// Bila dibuka dari kartu konsol tertentu, konsol itu langsung terpilih.
  final String? initialConsoleId;

  const ConnectTvDialog({super.key, this.initialConsoleId});

  @override
  State<ConnectTvDialog> createState() => _ConnectTvDialogState();
}

class _ConnectTvDialogState extends State<ConnectTvDialog> {
  final _codeCtrl = TextEditingController();
  final _service = DevicePairingService();

  String? _consoleId;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _consoleId = widget.initialConsoleId;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String get _cleanCode => _codeCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _connect() async {
    if (_cleanCode.length != 6) {
      setState(() => _error = 'Kode harus 6 digit, sesuai yang tampil di TV');
      return;
    }
    if (_consoleId == null) {
      setState(() => _error = 'Pilih konsol terlebih dahulu');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final provider = context.read<ConsoleProvider>();
    final consoleName = provider.consoles
            .where((c) => c.id == _consoleId)
            .map((c) => c.name)
            .firstOrNull ??
        'konsol';

    try {
      await _service.bindByCode(code: _cleanCode, consoleId: _consoleId!);
      if (!mounted) return;
      Navigator.pop(context, true);
      await provider.loadAll();
      await showSuccessDialog('TV berhasil dihubungkan ke $consoleName');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unbind(ConsoleModel console) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Lepaskan TV',
            style: TextStyle(color: kTextPrimary)),
        content: Text(
            'Lepaskan TV dari ${console.name}?\n\n'
            'TV tersebut akan menampilkan kode pairing baru.',
            style: const TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Lepaskan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.unbindConsole(console.id);
      if (!mounted) return;
      final provider = context.read<ConsoleProvider>();
      await provider.loadAll();
      if (mounted) {
        setState(() => _loading = false);
        await showSuccessDialog('TV dilepas dari ${console.name}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final consoles = context.watch<ConsoleProvider>().consoles;
    final selected =
        consoles.where((c) => c.id == _consoleId).firstOrNull;

    return AlertDialog(
      backgroundColor: kSurface,
      title: const Row(
        children: [
          Icon(Icons.cast_connected_rounded, color: kAccentPurple, size: 22),
          SizedBox(width: 10),
          Text('Hubungkan TV', style: TextStyle(color: kTextPrimary)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kAccentPurple.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kAccentPurple.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: kAccentPurple),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lihat kode 6 digit di layar TV, lalu ketik di bawah ini.',
                      style: TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 14,
              ),
              decoration: const InputDecoration(
                labelText: 'Kode Pairing',
                hintText: '000000',
                hintStyle: TextStyle(letterSpacing: 8, fontSize: 24),
                counterText: '',
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _connect(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue:
                  consoles.any((c) => c.id == _consoleId) ? _consoleId : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Hubungkan ke Konsol'),
              items: consoles.map((c) {
                final bound = c.deviceId != null;
                return DropdownMenuItem<String>(
                  value: c.id,
                  child: Row(
                    children: [
                      Icon(
                        bound
                            ? Icons.tv_rounded
                            : Icons.tv_off_outlined,
                        size: 16,
                        color: bound ? kSuccessColor : kTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${c.name}${bound ? ' — sudah ada TV' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: bound ? kSuccessColor : kTextPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _loading
                  ? null
                  : (v) => setState(() {
                        _consoleId = v;
                        _error = null;
                      }),
            ),
            if (selected != null && selected.deviceId != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _loading ? null : () => _unbind(selected),
                  icon: const Icon(Icons.link_off_rounded,
                      size: 16, color: kErrorColor),
                  label: const Text('Lepaskan TV dari konsol ini',
                      style: TextStyle(color: kErrorColor, fontSize: 12)),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: kErrorColor, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _connect,
          icon: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.link_rounded, size: 16),
          label: Text(_loading ? 'Menghubungkan…' : 'Hubungkan'),
          style: ElevatedButton.styleFrom(backgroundColor: kAccentPurple),
        ),
      ],
    );
  }
}
