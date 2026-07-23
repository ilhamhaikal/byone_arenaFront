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

class _TvLogScreenState extends State<TvLogScreen> {
  final ConsoleService _service = ConsoleService();
  TvLogResponse? _response;
  bool _loading = false;
  String? _selectedConsoleId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConsoles();
    });
  }

  Future<void> _loadConsoles() async {
    await context.read<ConsoleProvider>().loadOverview();
    if (mounted) setState(() {});
  }

  Future<void> _fetchLogs() async {
    if (_selectedConsoleId == null) return;
    setState(() => _loading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _response = await _service.getTvLogs(_selectedConsoleId!, date: dateStr);
    } catch (_) {
      _response = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final consoles = context.watch<ConsoleProvider>().overview;
    final dateFmt = DateFormat('dd MMM yyyy', 'id');
    final response = _response;
    final logs = response?.logs ?? [];
    final unauthorizedLogs = response?.unauthorizedLogs ?? [];
    final activeSession = response?.activeSession;
    final hasData = logs.isNotEmpty || unauthorizedLogs.isNotEmpty;

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
                  onPressed: _fetchLogs,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
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
                                  const SizedBox(height: 12),
                                ],
                                // ── Authorized Section ────────────────
                                if (logs.isNotEmpty) ...[
                                  _buildSectionHeader(
                                      'AKTIVITAS (${logs.length})', kSuccessColor),
                                  const SizedBox(height: 6),
                                  ...logs.map(_buildLogItem),
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
    final totalLogs = response.logs.length + response.unauthorizedLogs.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _statChip(Icons.flash_on_rounded, '${response.totalOnMinutes} mnt',
              kPrimaryBlue),
          const SizedBox(width: 10),
          _statChip(Icons.warning_amber_rounded,
              '${response.unauthorizedCount} unauthorized', kErrorColor),
          const Spacer(),
          Text('$totalLogs log',
              style: const TextStyle(color: kTextSecondary, fontSize: 12)),
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
    final isOff = log.action == 'off';
    final color = isOn
        ? kSuccessColor
        : isOff
            ? kErrorColor
            : kWarningColor;
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
              isOn
                  ? Icons.power_settings_new_rounded
                  : Icons.power_off_rounded,
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
