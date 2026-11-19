import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/license_model.dart';
import '../../providers/license_provider.dart';
import '../../services/license_service.dart';
import '../../utils/app_dialog.dart';

/// Halaman Lisensi: status, impor file lisensi, ID server, dan riwayat.
class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LicenseProvider>().loadStatus();
      context.read<LicenseProvider>().loadHistory();
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
                Row(
                  children: const [
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
                  '${row.customer.isEmpty ? '-' : row.customer}',
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
