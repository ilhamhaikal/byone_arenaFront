import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/staff_report_model.dart';
import '../../providers/report_provider.dart';
import '../../providers/user_provider.dart';

/// Laporan pendapatan & login–logout per petugas.
class StaffReportView extends StatefulWidget {
  const StaffReportView({super.key});

  @override
  State<StaffReportView> createState() => _StaffReportViewState();
}

class _StaffReportViewState extends State<StaffReportView> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _userId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 7));
    _endDate = now;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadAll();
      _load();
    });
  }

  Future<void> _load() async {
    await context.read<ReportProvider>().loadStaffReport(
          startDate: DateFormat('yyyy-MM-dd').format(_startDate),
          endDate: DateFormat('yyyy-MM-dd').format(_endDate),
          userId: _userId,
        );
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kPrimaryBlue),
        ),
        child: child!,
      ),
    );
    if (range == null) return;
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy', 'id');
    final p = context.watch<ReportProvider>();
    final users = context.watch<UserProvider>().users;

    return RefreshIndicator(
      color: kPrimaryBlue,
      backgroundColor: kSurface,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _filterBar(dateFmt, users),
          const SizedBox(height: 14),
          if (p.isStaffLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: CircularProgressIndicator(color: kPrimaryBlue)),
            )
          else if (p.staffError != null)
            _error(p.staffError!)
          else if (p.staffReport == null)
            _empty('Belum ada data laporan')
          else ...[
            _summaryCard(p.staffReport!),
            const SizedBox(height: 14),
            ...p.staffReport!.staff.map((u) => _staffCard(u)),
            if (p.staffReport!.unknown != null) ...[
              const SizedBox(height: 10),
              _staffCard(p.staffReport!.unknown!, unknown: true),
            ],
          ],
        ],
      ),
    );
  }

  Widget _filterBar(DateFormat fmt, List users) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_rounded, size: 16),
            label: Text(
              '${fmt.format(_startDate)} – ${fmt.format(_endDate)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              value: _userId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Petugas',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Semua petugas'),
                ),
                ...users.map((u) => DropdownMenuItem<String?>(
                      value: u.id as String,
                      child: Text(
                        '${u.fullName} (${u.role})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: (v) {
                setState(() => _userId = v);
                _load();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(StaffReportModel report) {
    final f = NumberFormat('#,###', 'id');
    final all = [
      ...report.staff,
      if (report.unknown != null) report.unknown!,
    ];
    final total = all.fold<double>(0, (a, u) => a + u.totals.total);
    final trx = all.fold<int>(0, (a, u) => a + u.totals.totalTrx);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F0F2E), Color(0xFF0A0A14)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimaryBlue.withAlpha(30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: kPrimaryBlue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${report.staff.length} petugas • ${report.period.totalDays} hari',
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rp ${f.format(total.toInt())}',
                  style: const TextStyle(
                      color: kSuccessColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text('$trx transaksi',
                  style:
                      const TextStyle(color: kTextSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _staffCard(StaffReportUser user, {bool unknown = false}) {
    final f = NumberFormat('#,###', 'id');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: unknown ? kWarningColor.withAlpha(70) : kBorderColor),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        iconColor: kPrimaryBlue,
        collapsedIconColor: kTextSecondary,
        title: Text(
          user.fullName,
          style: const TextStyle(
              color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${user.username} • ${user.role}',
          style: const TextStyle(color: kTextSecondary, fontSize: 11),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Rp ${f.format(user.totals.total.toInt())}',
                style: const TextStyle(
                    color: kSuccessColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text('${user.totals.totalTrx} trx',
                style:
                    const TextStyle(color: kTextSecondary, fontSize: 10)),
          ],
        ),
        children: [
          if (user.days.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text('Tidak ada aktivitas',
                    style: TextStyle(color: kTextSecondary, fontSize: 11)),
              ),
            )
          else
            ...user.days.map((d) => _dayCard(d)),
        ],
      ),
    );
  }

  Widget _dayCard(StaffReportDay day) {
    final f = NumberFormat('#,###', 'id');
    final timeFmt = DateFormat('HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kDeepBlack.withAlpha(120),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_rounded,
                  size: 14, color: kTextSecondary),
              const SizedBox(width: 6),
              Text(day.date,
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('Rp ${f.format(day.revenue.total.toInt())}',
                  style: const TextStyle(
                      color: kSuccessColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
          if (day.sessions.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...day.sessions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.login_rounded,
                          size: 11, color: kPrimaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        '${timeFmt.format(s.loginAt.toLocal())} – '
                        '${s.logoutAt == null ? 'Belum logout' : timeFmt.format(s.logoutAt!.toLocal())}',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 10),
                      ),
                      const SizedBox(width: 6),
                      Text('(${(s.durationMinutes / 60).toStringAsFixed(1)} jam)',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 9)),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _moneyChip('Rental', day.revenue.rental, f),
              _moneyChip('Makanan', day.revenue.food, f),
              _moneyChip('Harian', day.revenue.dailyRental, f),
              _moneyChip('Member', day.revenue.membership, f),
              _moneyChip('Game', day.revenue.game, f),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moneyChip(String label, double value, NumberFormat f) {
    if (value <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: kPrimaryBlue.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kPrimaryBlue.withAlpha(40)),
      ),
      child: Text(
        '$label Rp ${f.format(value.toInt())}',
        style: const TextStyle(color: kTextSecondary, fontSize: 9),
      ),
    );
  }

  Widget _error(String message) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: kErrorColor, size: 40),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      );

  Widget _empty(String message) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(message,
              style: const TextStyle(color: kTextSecondary, fontSize: 12)),
        ),
      );
}
