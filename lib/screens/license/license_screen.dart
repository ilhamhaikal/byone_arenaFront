import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/app_theme.dart';
import '../../models/license_model.dart';
import '../../providers/license_provider.dart';
import '../../services/license_service.dart';
import '../../utils/app_dialog.dart';

/// Halaman Lisensi: status, impor file lisensi, ID server, dan riwayat.
class LicenseScreen extends StatefulWidget {
  /// Bila true dan lisensi sedang terkunci, buat kode QR otomatis saat layar
  /// dibuka. Dipakai sebagai layar gerbang setelah login.
  final bool autoStartOnline;

  const LicenseScreen({super.key, this.autoStartOnline = false});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  Timer? _autoPollTimer;
  bool _autoPollBusy = false;

  @override
  void dispose() {
    _autoPollTimer?.cancel();
    super.dispose();
  }

  void _startAutoPoll(int seconds) {
    _autoPollTimer?.cancel();
    _autoPollTimer = Timer.periodic(Duration(seconds: seconds), (_) async {
      if (!mounted || _autoPollBusy) return;
      _autoPollBusy = true;
      final provider = context.read<LicenseProvider>();
      final result = await provider.pollOnlineActivation();
      if (!mounted) return;
      _autoPollBusy = false;
      if (result == null) return;
      if (result.valid && result.state == 'activated') {
        _autoPollTimer?.cancel();
        await provider.loadStatus();
        await provider.loadHistory();
      } else if (result.state == 'rejected' || result.state == 'expired') {
        _autoPollTimer?.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<LicenseProvider>();
      await provider.loadStatus();
      await provider.loadHistory();
      if (!mounted) return;
      if (widget.autoStartOnline && (provider.status?.isBlocked ?? false)) {
        await _startOnline();
      }
    });
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'active':
        return kSuccessColor;
      case 'trial':
        return kPrimaryBlue;
      case 'expiring':
      case 'grace':
        return kWarningColor;
      default:
        return kErrorColor;
    }
  }

  IconData _stateIcon(String state) {
    switch (state) {
      case 'active':
        return Icons.verified_rounded;
      case 'trial':
        return Icons.science_rounded;
      case 'expiring':
        return Icons.hourglass_bottom_rounded;
      case 'grace':
        return Icons.timer_rounded;
      default:
        return Icons.gpp_bad_rounded;
    }
  }

  Future<void> _refresh() async {
    await context.read<LicenseProvider>().loadStatus();
    if (mounted) await context.read<LicenseProvider>().loadHistory();
  }

  Future<void> _importFile() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'File Lisensi',
        extensions: ['lic', 'key', 'txt'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final text = decodeLicenseFile(bytes);
      if (!mounted) return;
      await _activate(text);
    } catch (e) {
      if (mounted) {
        await showErrorDialog('Gagal membaca file lisensi.\n$e');
      }
    }
  }

  Future<void> _startOnline() async {
    final provider = context.read<LicenseProvider>();
    final request = await provider.startOnlineActivation();
    if (!mounted) return;
    if (request == null) {
      await showErrorDialog(provider.error ?? 'Gagal membuat kode aktivasi.');
      return;
    }
    final activated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OnlineActivationDialog(request: request),
    );
    if (!mounted) return;
    await _refresh();
    // Dialog bisa ditutup sebelum vendor menyetujui. Polling tetap berjalan
    // di background agar lisensi langsung terpasang saat vendor menerbitkan.
    if (activated != true && (provider.status?.isBlocked ?? true)) {
      _startAutoPoll(request.pollAfterSeconds);
    }
  }

  Future<void> _pasteDialog() async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Tempel Kode Lisensi',
            style: TextStyle(color: kTextPrimary)),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tempel isi file lisensi (.lic) yang dikirim vendor.',
                style: TextStyle(color: kTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 6,
                style: const TextStyle(color: kTextPrimary, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'eyJ2IjoxLCJsaWNlbnNlSWQi...',
                  hintStyle: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
    if (!mounted || text == null || text.trim().isEmpty) return;
    await _activate(text);
  }

  Future<void> _activate(String licenseKey, {bool force = false}) async {
    final provider = context.read<LicenseProvider>();
    final result = await provider.activate(licenseKey, force: force);

    if (!mounted) return;

    if (result == null) {
      await showErrorDialog(provider.error ?? 'Gagal mengaktifkan lisensi');
      return;
    }

    // Perlu konfirmasi karena lisensi baru menurunkan masa berlaku/unit.
    if (result.requiresConfirmation) {
      final ok = await _confirmDowngrade(result.warnings);
      if (ok == true && mounted) {
        await _activate(licenseKey, force: true);
      }
      return;
    }

    if (result.activated && result.status != null) {
      await provider.loadHistory();
      if (!mounted) return;
      await _showSuccess(result.status!, result.warnings);
    }
  }

  Future<bool?> _confirmDowngrade(List<String> warnings) {
    final list = warnings.isEmpty
        ? const ['Lisensi baru mengubah masa berlaku atau jumlah unit.']
        : warnings;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kWarningColor),
            SizedBox(width: 8),
            Text('Konfirmasi Lisensi',
                style: TextStyle(color: kTextPrimary)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Periksa dulu sebelum melanjutkan:',
                style: TextStyle(color: kTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 10),
              for (final w in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(color: kWarningColor)),
                      Expanded(
                        child: Text(w,
                            style: const TextStyle(
                                color: kTextPrimary, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kWarningColor),
            child: const Text('Tetap Lanjutkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccess(
      LicenseStatusModel s, List<String> warnings) async {
    final rows = <(String, String)>[
      ('Paket', s.plan.isEmpty ? '-' : s.plan),
      ('Klien', s.customer.isEmpty ? '-' : s.customer),
      if (s.licenseId.isNotEmpty) ('ID Lisensi', s.licenseId),
      ('Unit', s.unitsLabel),
      ('Berlaku s/d', s.expiresLabel),
      ('Sisa Hari', '${s.daysLeft} hari'),
    ];

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: kSuccessColor),
            SizedBox(width: 8),
            Text('Lisensi Berhasil Diaktifkan',
                style: TextStyle(color: kTextPrimary, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSuccessColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kSuccessColor.withAlpha(60)),
                ),
                child: Text(
                  s.message,
                  style: const TextStyle(
                      color: kTextPrimary, fontSize: 12, height: 1.35),
                ),
              ),
              const SizedBox(height: 12),
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(label,
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 12)),
                      ),
                      Expanded(
                        child: Text(value,
                            style: const TextStyle(
                                color: kTextPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Catatan:',
                    style: TextStyle(color: kWarningColor, fontSize: 11)),
                const SizedBox(height: 4),
                for (final w in warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('• $w',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 11)),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyInstance(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID server disalin')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Lisensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kTextSecondary),
            tooltip: 'Muat ulang',
            onPressed: _refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<LicenseProvider>(
        builder: (context, p, _) {
          if (p.isLoading && p.status == null) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          final s = p.status;
          if (s == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gpp_bad_rounded,
                      size: 48, color: kErrorColor),
                  const SizedBox(height: 12),
                  Text(p.error ?? 'Status lisensi tidak tersedia',
                      style: const TextStyle(color: kTextSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _refresh, child: const Text('Coba Lagi')),
                ],
              ),
            );
          }

          final color = _stateColor(s.state);

          return RefreshIndicator(
            color: kPrimaryBlue,
            backgroundColor: kSurface,
            onRefresh: _refresh,
            child: ListView(
            key: const PageStorageKey('license-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                _StatusHero(
                  status: s,
                  color: color,
                  icon: _stateIcon(s.state),
                ),
                const SizedBox(height: 16),
                _DetailsCard(status: s, color: color),
                const SizedBox(height: 16),
                _InstanceCard(
                  instanceId: s.instanceId,
                  onCopy: () => _copyInstance(s.instanceId),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (p.isActivating || p.isStartingOnline)
                        ? null
                        : _startOnline,
                    icon: p.isStartingOnline
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: Text(p.isStartingOnline
                        ? 'Membuat kode…'
                        : 'Aktivasi Online (QR)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: p.isActivating ? null : _importFile,
                        icon: p.isActivating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.upload_file_rounded, size: 18),
                        label: Text(p.isActivating
                            ? 'Memproses…'
                            : 'Impor File Lisensi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentPurple,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: p.isActivating ? null : _pasteDialog,
                        icon: const Icon(Icons.content_paste_rounded,
                            size: 16),
                        label: const Text('Tempel Kode'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kTextPrimary,
                          side: BorderSide(
                              color: kTextSecondary.withAlpha(90)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'File lisensi dikirim vendor melalui WhatsApp/email. '
                  'Lisensi mengikat server ini, jadi simpan ID server di atas '
                  'untuk pengajuan lisensi baru atau perpanjangan.',
                  style: TextStyle(color: kTextSecondary, fontSize: 11),
                ),
                if (p.error != null) ...[
                  const SizedBox(height: 10),
                  Text(p.error!,
                      style: const TextStyle(
                          color: kErrorColor, fontSize: 12)),
                ],
                const SizedBox(height: 26),
                const Row(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 16, color: kTextSecondary),
                    SizedBox(width: 8),
                    Text('Riwayat Lisensi',
                        style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                if (p.history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: const Text('Belum ada riwayat lisensi.',
                        style: TextStyle(
                            color: kTextSecondary, fontSize: 12)),
                  )
                else
                  ...p.history.map((h) => _HistoryTile(row: h)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Kartu status utama ──────────────────────────────────────────────────────
class _StatusHero extends StatelessWidget {
  final LicenseStatusModel status;
  final Color color;
  final IconData icon;
  const _StatusHero(
      {required this.status, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(45), const Color(0xFF0A0A14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(110)),
        boxShadow: [
          BoxShadow(color: color.withAlpha(25), blurRadius: 24, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.stateLabel,
                        style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    Text(
                      status.plan.isEmpty ? '-' : status.plan,
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Text(
                  status.isTrial
                      ? '${status.trialDaysLeft} hari'
                      : '${status.daysLeft} hari',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(status.message,
              style: const TextStyle(
                  color: kTextPrimary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Unit terpakai',
                  style: TextStyle(color: kTextSecondary, fontSize: 11)),
              Text(status.unitsLabel,
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: status.isUnlimited ? 0 : status.unitRatio,
              minHeight: 8,
              backgroundColor: kBorderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                status.nearUnitLimit ? kWarningColor : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rincian lisensi ─────────────────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final LicenseStatusModel status;
  final Color color;
  const _DetailsCard({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Paket', status.plan.isEmpty ? '-' : status.plan),
      ('Klien', status.customer.isEmpty ? '-' : status.customer),
      if (status.licenseId.isNotEmpty) ('ID Lisensi', status.licenseId),
      ('Unit', status.unitsLabel),
      if (status.expiresAt != null) ('Berlaku s/d', status.expiresLabel),
      if (status.state == 'trial')
        ('Sisa Uji Coba', '${status.trialDaysLeft} hari')
      else if (status.expiresAt != null)
        ('Sisa Hari', '${status.daysLeft} hari'),
      ('Masa Tenggang', '${status.graceDays} hari'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 16, color: color),
              const SizedBox(width: 8),
              const Text('Rincian Lisensi',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(label,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12)),
                  ),
                  Expanded(
                    child: Text(value,
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          if (status.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final w in status.warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 13, color: kWarningColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(w,
                          style: const TextStyle(
                              color: kWarningColor, fontSize: 11)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── ID server ───────────────────────────────────────────────────────────────
class _InstanceCard extends StatelessWidget {
  final String instanceId;
  final VoidCallback onCopy;
  const _InstanceCard({required this.instanceId, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fingerprint_rounded, size: 16, color: kPrimaryBlue),
              SizedBox(width: 8),
              Text('ID Server',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Kirim ID ini ke vendor saat membeli atau memperpanjang lisensi.',
            style: TextStyle(color: kTextSecondary, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: kDeepBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: SelectableText(
                    instanceId.isEmpty ? '-' : instanceId,
                    style: const TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: instanceId.isEmpty ? null : onCopy,
                icon: const Icon(Icons.copy_rounded,
                    size: 18, color: kTextSecondary),
                tooltip: 'Salin ID server',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Riwayat ─────────────────────────────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final LicenseHistoryModel row;
  const _HistoryTile({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: row.isActive ? kSuccessColor.withAlpha(90) : kBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (row.isActive ? kSuccessColor : kTextSecondary)
                  .withAlpha(25),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.workspace_premium_rounded,
                size: 18,
                color: row.isActive ? kSuccessColor : kTextSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${row.plan.isEmpty ? '-' : row.plan} • ${row.unitsLabel}',
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (row.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kSuccessColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('AKTIF',
                            style: TextStyle(
                                color: kSuccessColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  row.customer.isEmpty ? '-' : row.customer,
                  style:
                      const TextStyle(color: kTextSecondary, fontSize: 11),
                ),
                Text(
                  'Aktif: ${row.activatedLabel}  •  s/d ${row.expiresLabel}',
                  style:
                      const TextStyle(color: kTextSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dialog aktivasi online (QR) ─────────────────────────────────────────────
class _OnlineActivationDialog extends StatefulWidget {
  final OnlineActivationStartModel request;
  const _OnlineActivationDialog({required this.request});

  @override
  State<_OnlineActivationDialog> createState() =>
      _OnlineActivationDialogState();
}

class _OnlineActivationDialogState extends State<_OnlineActivationDialog> {
  Timer? _timer;
  bool _polling = false;
  bool _done = false;
  String _message = 'Menunggu vendor menerbitkan lisensi…';
  OnlineActivationPollModel? _last;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      Duration(seconds: widget.request.pollAfterSeconds),
      (_) => _poll(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_polling || _done || !mounted) return;
    setState(() => _polling = true);
    final result = await context.read<LicenseProvider>().pollOnlineActivation();
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _polling = false;
        _message = 'Gagal memeriksa status. Mencoba lagi…';
      });
      return;
    }
    final terminal = result.state == 'rejected' || result.state == 'expired';
    final activated = result.valid && result.state == 'activated';
    if (activated) {
      _timer?.cancel();
      await context.read<LicenseProvider>().loadHistory();
    } else if (terminal) {
      _timer?.cancel();
    }
    if (!mounted) return;
    setState(() {
      _polling = false;
      _done = activated;
      _last = result;
      _message = result.message.isEmpty
          ? (activated ? 'Lisensi berhasil diaktifkan.' : 'Menunggu vendor…')
          : result.message;
    });
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.request.code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kode aktivasi disalin')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expires = widget.request.expiresAt?.toLocal();
    final color = _done ? kSuccessColor : kPrimaryBlue;
    return AlertDialog(
      backgroundColor: kSurface,
      title: Row(
        children: [
          Icon(_done ? Icons.check_circle_rounded : Icons.qr_code_2_rounded,
              color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_done ? 'Lisensi Aktif' : 'Aktivasi Online',
                style: const TextStyle(color: kTextPrimary)),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_done) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kSuccessColor.withAlpha(18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kSuccessColor.withAlpha(60)),
                  ),
                  child: Text(_message,
                      style: const TextStyle(
                          color: kTextPrimary, fontSize: 12, height: 1.4)),
                ),
                if (_last?.status != null) ...[
                  const SizedBox(height: 12),
                  for (final (label, value) in <(String, String)>[
                    (
                      'Paket',
                      _last!.status!.plan.isEmpty ? '-' : _last!.status!.plan
                    ),
                    (
                      'Klien',
                      _last!.status!.customer.isEmpty
                          ? '-'
                          : _last!.status!.customer
                    ),
                    if (_last!.status!.licenseId.isNotEmpty)
                      ('ID Lisensi', _last!.status!.licenseId),
                    ('Berlaku s/d', _last!.status!.expiresLabel),
                    ('Unit', _last!.status!.unitsLabel),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(label,
                                style: const TextStyle(
                                    color: kTextSecondary, fontSize: 12)),
                          ),
                          Expanded(
                            child: Text(value,
                                style: const TextStyle(
                                    color: kTextPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                ],
              ] else ...[
                const Text(
                  'Tunjukkan QR atau kode ini ke vendor. Setelah vendor '
                  'menerbitkan lisensi, aplikasi akan menerimanya otomatis.',
                  style: TextStyle(
                      color: kTextSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: widget.request.code,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        widget.request.code,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _copyCode,
                      tooltip: 'Salin kode',
                      icon: const Icon(Icons.copy_rounded,
                          size: 18, color: kTextSecondary),
                    ),
                  ],
                ),
                if (expires != null)
                  Text(
                    'Berlaku sampai ${DateFormat('dd MMM yyyy HH:mm', 'id').format(expires)}',
                    style: const TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Row(
                    children: [
                      if (_polling)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kPrimaryBlue),
                        )
                      else
                        const Icon(Icons.sync_rounded,
                            size: 14, color: kTextSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_message,
                            style: const TextStyle(
                                color: kTextSecondary,
                                fontSize: 11,
                                height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (!_done)
          TextButton(
            onPressed: _polling ? null : _poll,
            child: const Text('Cek Status'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _done),
          child: Text(_done ? 'Selesai' : 'Tutup'),
        ),
      ],
    );
  }
}
