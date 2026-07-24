import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/console_overview_model.dart';
import '../../models/tv_log_model.dart';
import '../../providers/console_provider.dart';
import '../../services/console_service.dart';

class TvLogScreen extends StatefulWidget {
  const TvLogScreen({super.key});

  @override
  State<TvLogScreen> createState() => _TvLogScreenState();
}

class _TvLogScreenState extends State<TvLogScreen> with WidgetsBindingObserver {
  // Interval polling auto-refresh. Cukup singkat agar sesi aktif (mis. durasi
  // berjalan) terlihat ter-update tanpa membebani backend.
  static const Duration _autoRefreshInterval = Duration(seconds: 5);

  final ConsoleService _service = ConsoleService();
  TvLogResponse? _response;
  bool _loading = false;
  String? _selectedConsoleId;
  DateTime _selectedDate = DateTime.now();

  Timer? _autoRefreshTimer;

  bool get _isViewingToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConsoles();
    });
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Hentikan polling saat aplikasi tidak aktif untuk menghemat resource,
    // dan lanjutkan kembali saat aplikasi aktif.
    if (state == AppLifecycleState.resumed) {
      _fetchLogs(silent: true);
      _restartAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  void _restartAutoRefresh() {
    _stopAutoRefresh();
    if (_selectedConsoleId == null || !_isViewingToday) return;
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      _fetchLogs(silent: true);
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> _loadConsoles() async {
    await context.read<ConsoleProvider>().loadOverview();
    if (mounted) setState(() {});
  }

  /// Mengambil log terbaru dari backend.
  /// [silent] = true dipakai untuk auto-refresh berkala agar tidak memicu
  /// indikator loading full-screen yang mengganggu (hanya update data diam-diam).
  Future<void> _fetchLogs({bool silent = false}) async {
    if (_selectedConsoleId == null) return;
    if (!silent) setState(() => _loading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final result = await _service.getTvLogs(_selectedConsoleId!, date: dateStr);
      if (mounted) setState(() => _response = result);
    } catch (_) {
      if (!silent && mounted) setState(() => _response = null);
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
    // Pastikan polling aktif/nonaktif sesuai konteks terkini (mis. tanggal berubah).
    _restartAutoRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final consoles = context.watch<ConsoleProvider>().overview;
    final dateFmt = DateFormat('dd MMM yyyy', 'id');
    final response = _response;
    final allLogs = response?.logs ?? [];
    final unauthorizedLogsRaw = response?.unauthorizedLogs ?? [];
    // UI section unauthorized HANYA untuk ON (sesuai dokumentasi: OFF selalu authorized)
    final unauthorizedLogs = unauthorizedLogsRaw.where((l) => l.action == 'on').toList();
    // Pisahkan: logs utama hanya yang authorized (hindari duplikasi dengan unauthorizedLogs)
    final authorizedLogs = allLogs.where((l) => !l.unauthorized).toList();
    final activeSession = response?.activeSession;
    final hasData = authorizedLogs.isNotEmpty || unauthorizedLogs.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kPrimaryBlue, kAccentPurple]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: kPrimaryBlue.withAlpha(50), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.tv_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                const Text('LOG AKTIVITAS TV',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                // Date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(primary: kPrimaryBlue),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _fetchLogs();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: kPrimaryBlue, size: 16),
                        const SizedBox(width: 8),
                        Text(dateFmt.format(_selectedDate),
                            style: const TextStyle(color: kTextPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Console dropdown + fetch
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedConsoleId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: kCardColor,
                      style: const TextStyle(color: kTextPrimary, fontSize: 14),
                      hint: const Text('Pilih Konsol', style: TextStyle(color: kTextSecondary)),
                      items: consoles.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(c.isAndroidTV ? Icons.tv_outlined : Icons.sports_esports,
                                  color: c.isInUse ? kSuccessColor : kTextSecondary, size: 16),
                              const SizedBox(width: 8),
                              Text(c.name.isEmpty ? c.consoleType : c.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _selectedConsoleId = v);
                        _fetchLogs();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _fetchLogs(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
            if (_selectedConsoleId != null && _isViewingToday) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: kSuccessColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Auto-refresh setiap ${_autoRefreshInterval.inSeconds} detik',
                    style: const TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            // ── Active Session Banner ─────────────────────────────────
            if (activeSession != null) _buildActiveSessionBanner(activeSession!),
            if (activeSession != null) const SizedBox(height: 16),
            // ── Log list ──────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
                  : _selectedConsoleId == null
                      ? const Center(
                          child: Text('Pilih konsol untuk melihat log aktivitas TV',
                              style: TextStyle(color: kTextSecondary, fontSize: 14)))
                      : !hasData
                          ? const Center(
                              child: Text('Tidak ada log untuk tanggal ini',
                                  style: TextStyle(color: kTextSecondary, fontSize: 14)))
                          : ListView(
                              children: [
                                _buildStatsHeader(response!),
                                // ── Unauthorized Section ──────────────
                                if (unauthorizedLogs.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildSectionHeader(
                                      '⚠️ UNAUTHORIZED (${unauthorizedLogs.length})',
                                      kErrorColor),
                                  const SizedBox(height: 6),
                                  ...unauthorizedLogs.map(_buildLogItem),
                                  // Tampilkan indikator jika total backend > yang ditampilkan
                                  if (response!.unauthorizedCount > unauthorizedLogs.length)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '+ ${response!.unauthorizedCount - unauthorizedLogs.length} lainnya tidak ditampilkan',
                                        style: const TextStyle(
                                            color: kTextSecondary, fontSize: 10, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                ],
                                // ── Authorized Section ────────────────
                                if (authorizedLogs.isNotEmpty) ...[
                                  _buildSectionHeader(
                                      'AKTIVITAS (${authorizedLogs.length})', kSuccessColor),
                                  const SizedBox(height: 6),
                                  ...authorizedLogs.map(_buildLogItem),
                                ],
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Session Banner ─────────────────────────────────────────────
  Widget _buildActiveSessionBanner(TvActiveSession session) {
    final fmtTime = DateFormat('HH:mm', 'id');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A2A), Color(0xFF0F2319)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSuccessColor.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: kSuccessColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSuccessColor.withAlpha(50)),
            ),
            child: const Icon(Icons.play_circle_filled_rounded,
                color: kSuccessColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SESI AKTIF',
                    style: TextStyle(
                        color: kSuccessColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                if (session.customerName != null)
                  Text(session.customerName!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    if (session.startTime != null) ...[
                      Text('Mulai ${fmtTime.format(session.startTime!)}',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 12)),
                      const SizedBox(width: 12),
                    ],
                    Text('${session.runningMinutes.toStringAsFixed(1)} mnt',
                        style: const TextStyle(
                            color: kSuccessColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    if (session.bookedMinutes > 0) ...[
                      const Text(' / ', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                      Text('${session.bookedMinutes} mnt',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kSuccessColor.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(session.status.toUpperCase(),
                style: const TextStyle(
                    color: kSuccessColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  // ── Stats Header ──────────────────────────────────────────────────────
  Widget _buildStatsHeader(TvLogResponse response) {
    // logs sudah mencakup semua entry (authorized + unauthorized), jadi totalLogs = logs.length
    final totalLogs = response.logs.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _statChip(Icons.flash_on_rounded, '${response.totalOnMinutes} mnt total',
              kPrimaryBlue),
          _statChip(Icons.check_circle_outline_rounded,
              '${response.authorizedMinutes} mnt live', kSuccessColor),
          _statChip(Icons.warning_amber_rounded,
              '${response.unauthorizedMinutes} mnt unauthorized', kErrorColor),
          _statChip(Icons.list_alt_rounded, '$totalLogs log',
              kTextSecondary),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Log Item ──────────────────────────────────────────────────────────
  Widget _buildLogItem(TvLogEntry log) {
    final fmt = DateFormat('HH:mm:ss', 'id');
    final isOn = log.action == 'on';
    // sleep dan screensaver disamakan dengan off (sesuai dokumentasi backend)
    final isOff = log.action == 'off' || log.action == 'sleep' || log.action == 'screensaver';
    final color = isOn ? kSuccessColor : kErrorColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor, width: 0.5),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Icon(
              isOn ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(log.actionLabel,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    // Duration badge
                    if (log.durationMinutes != null && log.durationMinutes! > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withAlpha(15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withAlpha(50)),
                        ),
                        child: Text('${log.durationMinutes} mnt',
                            style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                    if (log.unauthorized) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kErrorColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: kErrorColor.withAlpha(60)),
                        ),
                        child: const Text('UNAUTHORIZED',
                            style: TextStyle(
                                color: kErrorColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                if (log.consoleName != null) ...[
                  const SizedBox(height: 2),
                  Text(log.consoleName!,
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
          // Timestamp
          Text(fmt.format(log.timestamp),
              style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
