import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/capital_model.dart';
import '../../models/report_summary_model.dart';
import '../../widgets/payment_method_breakdown.dart';
import '../../providers/capital_provider.dart';
import '../../providers/promo_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import 'staff_report_view.dart';

String _fmtMinutes(int minutes) =>
    minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _staffMode = false;
  bool _refreshing = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 7));
    _endDate = now;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_staffMode) _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    try {
      context.read<CapitalProvider>().loadMonthly();
      context.read<PromoProvider>().loadReport(
            DateFormat('yyyy-MM-dd').format(_startDate),
            DateFormat('yyyy-MM-dd').format(_endDate),
          );
      await context.read<ReportProvider>().loadReport(
            startDate: DateFormat('yyyy-MM-dd').format(_startDate),
            endDate: DateFormat('yyyy-MM-dd').format(_endDate),
          );
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(primary: kPrimaryBlue)),
          child: child!),
    );
    if (range != null) {
      setState(() { _startDate = range.start; _endDate = range.end; });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy', 'id');
    final shortDateFmt = DateFormat('dd/MM', 'id');
    final compact = MediaQuery.sizeOf(context).width < 600;
    final role = context.watch<AuthProvider>().user?.role;
    final canViewStaff = role == 'admin' || role == 'superadmin';
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Laporan'),
        actions: [
          if (canViewStaff)
            compact
                ? IconButton(
                    tooltip: _staffMode
                        ? 'Tampilkan ringkasan'
                        : 'Tampilkan per petugas',
                    onPressed: () {
                      setState(() => _staffMode = !_staffMode);
                      if (!_staffMode) _load();
                    },
                    icon: Icon(
                      _staffMode
                          ? Icons.dashboard_rounded
                          : Icons.people_rounded,
                      color: kPrimaryBlue,
                    ),
                  )
                : TextButton.icon(
                    onPressed: () {
                      setState(() => _staffMode = !_staffMode);
                      if (!_staffMode) _load();
                    },
                    icon: Icon(
                      _staffMode
                          ? Icons.dashboard_rounded
                          : Icons.people_rounded,
                      size: 16,
                      color: kPrimaryBlue,
                    ),
                    label: Text(
                      _staffMode ? 'Ringkasan' : 'Per Petugas',
                      style: const TextStyle(
                          color: kPrimaryBlue, fontSize: 12),
                    ),
                  ),
          if (!_staffMode)
            TextButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range_rounded,
                  size: 16, color: kPrimaryBlue),
              label: Text(
                  compact
                      ? '${shortDateFmt.format(_startDate)}–${shortDateFmt.format(_endDate)}'
                      : '${dateFmt.format(_startDate)} – ${dateFmt.format(_endDate)}',
                  style: const TextStyle(color: kPrimaryBlue, fontSize: 12)),
            ),
          if (!_staffMode && !compact)
            IconButton(
              tooltip: 'Muat ulang laporan',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded,
                  color: kTextSecondary, size: 20),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _staffMode
          ? const StaffReportView()
          : Consumer<ReportProvider>(
        builder: (context, p, _) {
          if (p.isLoading && p.report == null) return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          if (p.error != null) return _buildError(p.error!, _load);
          final r = p.report;
          if (r == null) return const Center(
            child: Text('Pilih rentang tanggal', style: TextStyle(color: kTextSecondary)));
          return RefreshIndicator(
            color: kPrimaryBlue,
            backgroundColor: kSurface,
            onRefresh: _load,
            child: SingleChildScrollView(
              key: const PageStorageKey('report-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _RevenueSummaryCard(
                    revenue: r.revenue,
                    period: r.period,
                    transactions: r.transactions),
                const SizedBox(height: 16),
                _IncomeSourcesCard(revenue: r.revenue),
                const SizedBox(height: 16),
                _SectionHeader('Penjualan Member', Icons.card_membership_rounded,
                    subtitle:
                        'Pendapatan dari penjualan membership pada periode ini.'),
                const SizedBox(height: 10),
                _MembershipSalesCard(revenue: r.revenue),
                const SizedBox(height: 16),
                _SectionHeader('Diskon & Voucher', Icons.local_offer_rounded,
                    subtitle:
                        'Diskon otomatis langsung mengurangi transaksi. '
                        'Voucher dihitung dari jumlah pemakaian.'),
                const SizedBox(height: 10),
                _DiscountReportCard(
                    revenue: r.revenue,
                    transactions: r.transactions,
                    foodSales: r.foodSales),
                const SizedBox(height: 16),
                if (r.paymentMethods.isNotEmpty) ...[
                  _SectionHeader('Cara Pelanggan Membayar', Icons.payment_rounded,
                      subtitle: 'Berapa banyak uang masuk lewat Tunai dan QRIS.'),
                  const SizedBox(height: 10),
                  _PaymentMethodsCard(methods: r.paymentMethods),
                  const SizedBox(height: 24),
                ],
                _SectionHeader('Sesi & Durasi Bermain', Icons.timer_rounded,
                    subtitle: 'Berapa lama pelanggan bermain pada periode ini.'),
                const SizedBox(height: 10),
                _SessionsCard(r.sessions),
                const SizedBox(height: 16),
                const _PromoBonusCard(),
                const SizedBox(height: 24),
                _QuickStats(r),
                const SizedBox(height: 24),
                if (r.foodSales != null && r.foodSales!.totalOrders > 0) ...[
                  _SectionHeader('Penjualan Makanan & Minuman',
                      Icons.restaurant_rounded,
                      subtitle:
                          'Pendapatan, HPP bahan, dan laba bersih dari menu terjual.'),
                  const SizedBox(height: 10),
                  _FoodSalesCard(food: r.foodSales!),
                  if (r.foodSales!.topItems.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailAccordion(
                      title: 'Menu Terlaris (${r.foodSales!.topItems.length})',
                      subtitle: 'Menu paling banyak dipesan.',
                      children: r.foodSales!.topItems
                          .map((item) => _FoodItemTile(item))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
                _DetailAccordion(
                  title: 'Konsol Paling Sering Dipakai',
                  subtitle: 'Konsol mana yang paling banyak dimainkan.',
                  children: r.consoles.isEmpty
                      ? [_EmptyTile('Belum ada data')]
                      : r.consoles.map((c) => _ConsoleTile(c)).toList(),
                ),
                const SizedBox(height: 10),
                _DetailAccordion(
                  title: 'Penggunaan Voucher',
                  subtitle:
                      'Berapa kali voucher dipakai. Potongan harga sudah masuk transaksi.',
                  children: r.vouchers.isEmpty
                      ? [_EmptyTile('Belum ada penggunaan voucher')]
                      : r.vouchers.map((v) => _VoucherTile(v)).toList(),
                ),
                const SizedBox(height: 10),
                _DetailAccordion(
                  title: 'Rincian Per Hari',
                  subtitle: 'Pendapatan tiap tanggal dalam periode.',
                  children: r.dailyBreakdown.isEmpty
                      ? [_EmptyTile('Belum ada data')]
                      : r.dailyBreakdown.map((d) => _DailyTile(d)).toList(),
                ),
                const SizedBox(height: 24),
                // ── Modal awal & perbandingan bulanan ──
                const _MonthlyCapitalSection(),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String msg, VoidCallback r) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: kErrorColor),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: kTextSecondary)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: r, child: const Text('Coba Lagi')),
    ]));
}

// ═══════════════════════════════════════════════════════════════════════════
// Bonus waktu gratis (promo)
// ═══════════════════════════════════════════════════════════════════════════
class _PromoBonusCard extends StatelessWidget {
  const _PromoBonusCard();

  @override
  Widget build(BuildContext context) {
    final report = context.watch<PromoProvider>().report;
    final minutes = report?.totalBonusMinutes ?? 0;
    final sessions = report?.sessionsWithBonus ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSuccessColor.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: kSuccessColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: kSuccessColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bonus Waktu Gratis',
                    style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  minutes > 0
                      ? '$minutes menit gratis dari $sessions sesi'
                      : 'Belum ada bonus diberikan pada periode ini',
                  style: const TextStyle(color: kTextSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${(minutes / 60).toStringAsFixed(minutes % 60 == 0 ? 0 : 1)} jam',
            style: const TextStyle(
                color: kSuccessColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Ringkasan (mudah dibaca orang awam)
// ═══════════════════════════════════════════════════════════════════════════
class _RevenueSummaryCard extends StatelessWidget {
  final ReportRevenue revenue;
  final ReportPeriod period;
  final ReportTransactions transactions;
  const _RevenueSummaryCard({
    required this.revenue,
    required this.period,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id');
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0F0F2E), Color(0xFF0A0A14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryBlue.withAlpha(25)),
        boxShadow: [
          BoxShadow(
              color: kPrimaryBlue.withAlpha(12),
              blurRadius: 30,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                gradient: kGradientGreen,
                borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.savings_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('TOTAL UANG MASUK',
                style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: kPrimaryBlue.withAlpha(25),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${period.totalDays} hari',
                style: const TextStyle(
                    color: kPrimaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 14),
        Text('Rp ${f.format(revenue.totalRevenue.toInt())}',
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: kTextPrimary,
                letterSpacing: -1)),
        const SizedBox(height: 4),
        Text(
            'Dari ${f.format(transactions.totalTransactions)} transaksi — total semua uang yang masuk pada periode ini.',
            style: const TextStyle(color: kTextSecondary, fontSize: 12)),
        const SizedBox(height: 16),
        Wrap(spacing: 22, runSpacing: 10, children: [
          _MiniStat('Nilai Awal (sebelum diskon)',
              'Rp ${f.format(revenue.totalBaseAmount.toInt())}', kTextPrimary),
          _MiniStat('Diskon Sesi',
              'Rp ${f.format(revenue.totalAutoDiscount.toInt())}', kWarningColor),
          _MiniStat('Voucher Dipakai',
              '${transactions.voucherTransactions}×', kAccentPurple),
        ]),
        const SizedBox(height: 8),
        const Text(
          'Diskon otomatis sudah dipotong dari total uang masuk. '
          'Voucher ditampilkan sebagai jumlah pemakaian.',
          style: TextStyle(color: kTextSecondary, fontSize: 10),
        ),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(color: kTextSecondary, fontSize: 10)),
        ],
      );
}

// ── Uang masuk dari sumber apa saja ────────────────────────────────────────
class _IncomeSourcesCard extends StatelessWidget {
  final ReportRevenue revenue;
  const _IncomeSourcesCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id');
    // Sisa dari total setelah dikurangi sumber lain = pendapatan sewa sesi.
    final double session = (revenue.totalRevenue -
            revenue.dailyRentalRevenue -
            revenue.membershipRevenue -
            revenue.foodSalesRevenue)
        .clamp(0.0, double.infinity)
        .toDouble();
    final total = revenue.totalRevenue;
    final items = <_SourceItem>[
      _SourceItem('Sewa Konsol (Sesi)', session, Icons.sports_esports_rounded,
          kGradientBlue),
      _SourceItem('Rental Harian', revenue.dailyRentalRevenue,
          Icons.home_rounded, kGradientPurple),
      _SourceItem('Membership', revenue.membershipRevenue,
          Icons.card_membership_rounded, kGradientPink),
      _SourceItem('Makanan & Minuman', revenue.foodSalesRevenue,
          Icons.restaurant_rounded, kGradientAmber),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                gradient: kGradientGreen,
                borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.pie_chart_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          const Text('Uang Masuk dari Mana?',
              style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 38),
          child: Text('Rincian sumber pendapatan pada periode ini.',
              style: TextStyle(color: kTextSecondary, fontSize: 11)),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _SourceRow(item: items[i], total: total, fmt: f),
        ],
      ]),
    );
  }
}

class _MembershipSalesCard extends StatelessWidget {
  final ReportRevenue revenue;
  const _MembershipSalesCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id');
    final count = revenue.membershipCount;
    final total = revenue.membershipRevenue;
    final avg = count > 0 ? total / count : 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SessStat('${f.format(count)}', 'Member Baru'),
          ),
          Expanded(
            child: _SessStat('Rp ${f.format(total.toInt())}', 'Pendapatan'),
          ),
          Expanded(
            child: _SessStat('Rp ${f.format(avg.toInt())}', 'Rata²/Member'),
          ),
        ],
      ),
    );
  }
}

class _DiscountReportCard extends StatelessWidget {
  final ReportRevenue revenue;
  final ReportTransactions transactions;
  final ReportFoodSales? foodSales;
  const _DiscountReportCard({
    required this.revenue,
    required this.transactions,
    this.foodSales,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id');
    final foodDisc = foodSales?.discountAmount ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: _DiscountStat(
                  label: 'Diskon Sesi',
                  value: 'Rp ${f.format(revenue.totalAutoDiscount.toInt())}',
                  color: kWarningColor,
                  icon: Icons.bolt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DiscountStat(
                  label: 'Diskon Makanan',
                  value: 'Rp ${f.format(foodDisc.toInt())}',
                  color: kSuccessColor,
                  icon: Icons.restaurant_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DiscountStat(
                  label: 'Voucher Dipakai',
                  value: '${transactions.voucherTransactions}×',
                  color: kAccentPurple,
                  icon: Icons.confirmation_number_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DiscountStat(
                  label: 'Total Diskon Otomatis',
                  value:
                      'Rp ${f.format((revenue.totalAutoDiscount + foodDisc).toInt())}',
                  color: kPrimaryBlue,
                  icon: Icons.savings_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Diskon sesi dan makanan sudah dipotong dari transaksi. '
            'Voucher ditampilkan sebagai jumlah pemakaian, bukan sebagai '
            'pendapatan negatif.',
            style: TextStyle(color: kTextSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DiscountStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _DiscountStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 10)),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceItem {
  final String label;
  final double amount;
  final IconData icon;
  final LinearGradient gradient;
  const _SourceItem(this.label, this.amount, this.icon, this.gradient);
}

class _SourceRow extends StatelessWidget {
  final _SourceItem item;
  final double total;
  final NumberFormat fmt;
  const _SourceRow(
      {required this.item, required this.total, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (item.amount / total).clamp(0.0, 1.0) : 0.0;
    final color = item.gradient.colors.last;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              gradient: item.gradient,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(item.icon, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(item.label,
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                Text('Rp ${fmt.format(item.amount.toInt())}',
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: kBorderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Text('${(pct * 100).round()}% dari total',
                  style:
                      const TextStyle(color: kTextSecondary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Detail yang bisa dibuka/tutup agar tampilan tetap ringkas ──────────────
class _DetailAccordion extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  const _DetailAccordion({
    required this.title,
    this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
  });
  @override
  State<_DetailAccordion> createState() => _DetailAccordionState();
}

class _DetailAccordionState extends State<_DetailAccordion> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor)),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(widget.subtitle!,
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 11)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_open ? 'Tutup' : 'Lihat',
                  style: const TextStyle(color: kPrimaryBlue, fontSize: 12)),
              Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: kPrimaryBlue),
            ]),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(children: widget.children),
          ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Quick Stats
// ═══════════════════════════════════════════════════════════════════════════
class _QuickStats extends StatelessWidget {
  final ReportSummaryModel r;
  const _QuickStats(this.r);

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id');
    return Column(children: [
      Row(children: [
        Expanded(child: _QStat(label: 'Sesi', value: '${f.format(r.sessions.totalSessions)}', icon: Icons.play_circle_rounded, g: kGradientBlue)),
        const SizedBox(width: 8),
        Expanded(child: _QStat(label: 'Durasi', value: _fmtMinutes(r.sessions.totalPlayMinutes), icon: Icons.timer_rounded, g: kGradientPurple)),
        const SizedBox(width: 8),
        Expanded(child: _QStat(label: 'Transaksi', value: '${f.format(r.transactions.totalTransactions)}', icon: Icons.receipt_long_rounded, g: kGradientAmber)),
        const SizedBox(width: 8),
        Expanded(child: _QStat(label: 'Voucher', value: '${f.format(r.transactions.voucherTransactions)}', icon: Icons.confirmation_number_rounded, g: kGradientPink)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _QStat(label: 'Rental Harian', value: '${f.format(r.revenue.dailyRentalCount)} rental', icon: Icons.home_rounded, g: kGradientBlue)),
        const SizedBox(width: 8),
        Expanded(child: _QStat(label: 'Rev. Harian', value: 'Rp ${f.format(r.revenue.dailyRentalRevenue.toInt())}', icon: Icons.monetization_on_rounded, g: kGradientGreen)),
        const SizedBox(width: 8),
        Expanded(child: _QStat(label: 'Membership', value: '${f.format(r.revenue.membershipCount)} member', icon: Icons.card_membership_rounded, g: kGradientPurple)),
        const SizedBox(width: 8),
        Expanded(child: _QStat(label: 'Rev. Member', value: 'Rp ${f.format(r.revenue.membershipRevenue.toInt())}', icon: Icons.monetization_on_rounded, g: kGradientGreen)),
      ]),
      if (r.revenue.foodSalesRevenue > 0 || (r.foodSales != null && r.foodSales!.totalOrders > 0)) ...[
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _QStat(
            label: 'Order Makanan',
            value: '${f.format(r.revenue.foodSalesCount)} order',
            icon: Icons.restaurant_rounded,
            g: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFF59E0B)]),
          )),
          const SizedBox(width: 8),
          Expanded(child: _QStat(
            label: 'Rev. Makanan',
            value: 'Rp ${f.format(r.revenue.foodSalesRevenue.toInt())}',
            icon: Icons.monetization_on_rounded,
            g: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
          )),
          const SizedBox(width: 8),
          Expanded(child: _QStat(
            label: 'Rata² Order',
            value: 'Rp ${f.format((r.foodSales?.averageOrderValue ?? 0).toInt())}',
            icon: Icons.trending_up_rounded,
            g: kGradientAmber,
          )),
          const SizedBox(width: 8),
          const Expanded(child: SizedBox.shrink()),
        ]),
      ],
    ]);
  }
}

class _QStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final LinearGradient g;
  const _QStat({required this.label, required this.value, required this.icon, required this.g});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(gradient: g, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 15)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 10)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sections
// ═══════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  const _SectionHeader(this.title, this.icon, {this.subtitle});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    gradient: kGradientBlue,
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(icon, color: Colors.white, size: 14)),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ]),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 38, top: 4),
              child: Text(subtitle!,
                  style: const TextStyle(
                      color: kTextSecondary, fontSize: 11)),
            ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Modal Awal & Perbandingan Bulanan
// ═══════════════════════════════════════════════════════════════════════════
class _MonthlyCapitalSection extends StatelessWidget {
  const _MonthlyCapitalSection();

  @override
  Widget build(BuildContext context) {
    final cap = context.watch<CapitalProvider>();
    final monthly = cap.monthly;
    if (monthly.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
            'Modal Awal & Perbandingan Bulanan', Icons.account_balance_wallet_rounded),
        const SizedBox(height: 10),
        // Terbaru dulu (backend mengirim ASC; balik untuk tampilan).
        ...monthly.reversed.map((m) => _MonthlyCapitalTile(m)),
      ],
    );
  }
}

class _MonthlyCapitalTile extends StatelessWidget {
  final MonthlyCapitalModel m;
  const _MonthlyCapitalTile(this.m);

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id');
    final up = m.percentChange >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.month,
              style: const TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              _chip('Modal Awal', 'Rp ${f.format(m.initialCapital.toInt())}',
                  kWarningColor),
              const SizedBox(width: 10),
              _chip('Pendapatan', 'Rp ${f.format(m.totalRevenue.toInt())}',
                  kSuccessColor),
              const SizedBox(width: 10),
              _chip('Makanan', 'Rp ${f.format(m.foodRevenue.toInt())}',
                  const Color(0xFFF97316)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 14,
                color: up ? kSuccessColor : kErrorColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${up ? '+' : ''}${m.percentChange.toStringAsFixed(1)}%',
                style: TextStyle(
                    color: up ? kSuccessColor : kErrorColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  m.reason,
                  style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, Color c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: c, fontSize: 11, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(color: kTextSecondary, fontSize: 9)),
        ],
      );
}

class _SessionsCard extends StatelessWidget {
  final ReportSessions s;
  const _SessionsCard(this.s);
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _SessStat('${s.totalSessions}', 'Sesi'),
      _SessStat(_fmtMinutes(s.totalPlayMinutes), 'Durasi'),
      _SessStat('${s.totalPlayHours.toStringAsFixed(1)}h', 'Jam'),
      _SessStat('${s.averageMinutes}m', 'Rata²'),
    ]),
  );
}

class _SessStat extends StatelessWidget {
  final String v, l;
  const _SessStat(this.v, this.l);
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(v, style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
    Text(l, style: const TextStyle(color: kTextSecondary, fontSize: 10)),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// Tiles
// ═══════════════════════════════════════════════════════════════════════════
Widget _EmptyTile(String msg) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderColor)),
  child: Text(msg, style: const TextStyle(color: kTextSecondary, fontSize: 12), textAlign: TextAlign.center),
);

class _ConsoleTile extends StatelessWidget {
  final ReportConsoleUsage c;
  const _ConsoleTile(this.c);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderColor)),
    child: Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(gradient: _typeGrad(c.consoleType), borderRadius: BorderRadius.circular(5)), child: Text(c.consoleType, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
      const SizedBox(width: 10),
      Expanded(child: Text(c.consoleName, style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
      Text('${c.totalSessions} sesi', style: const TextStyle(color: kTextSecondary, fontSize: 11)),
      const SizedBox(width: 10),
      Text(_fmtMinutes(c.totalMinutes), style: const TextStyle(color: kTextSecondary, fontSize: 11)),
    ]),
  );

  LinearGradient _typeGrad(String t) { switch (t) { case 'PS5': return kGradientPurple; case 'PS3': return kGradientPink; case 'Switch': return kGradientPink; default: return kGradientBlue; } }
}

class _VoucherTile extends StatelessWidget {
  final ReportVoucherUsage v;
  const _VoucherTile(this.v);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderColor)),
      child: Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(gradient: kGradientPurple, borderRadius: BorderRadius.circular(5)), child: Text(v.voucherCode, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        const SizedBox(width: 10),
        Expanded(child: Text(v.voucherName, style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
        Text('${v.usageCount}× dipakai',
            style: const TextStyle(color: kAccentPurple, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _DailyTile extends StatelessWidget {
  final ReportDailyItem d;
  const _DailyTile(this.d);
  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id');
    final date = DateFormat('EEEE, d MMM', 'id').format(DateTime.parse(d.date));
    final hasRental = d.dailyRentals > 0 || d.rentalRevenue > 0;
    final hasMember = d.memberships > 0 || d.membershipRevenue > 0;
    final hasFood = d.foodOrders > 0 || d.foodRevenue > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(date, style: const TextStyle(color: kTextPrimary, fontSize: 12))),
            if (d.sessions > 0) ...[
              Text('${d.sessions} sesi', style: const TextStyle(color: kTextSecondary, fontSize: 11)),
              const SizedBox(width: 8),
              Text(_fmtMinutes(d.playMinutes), style: const TextStyle(color: kTextSecondary, fontSize: 11)),
            ],
            const SizedBox(width: 8),
            Text('Rp ${f.format(d.revenue.toInt())}', style: const TextStyle(color: kSuccessColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          if (hasRental || hasMember || hasFood) ...[
            const SizedBox(height: 4),
            Row(children: [
              if (hasRental) ...[
                const Icon(Icons.home_rounded, size: 10, color: kPrimaryBlue),
                const SizedBox(width: 4),
                Text('${d.dailyRentals} rental • Rp ${f.format(d.rentalRevenue.toInt())}',
                    style: const TextStyle(color: kPrimaryBlue, fontSize: 10)),
              ],
              if (hasRental && hasMember) const SizedBox(width: 12),
              if (hasMember) ...[
                const Icon(Icons.card_membership_rounded, size: 10, color: kAccentPurple),
                const SizedBox(width: 4),
                Text('${d.memberships} member • Rp ${f.format(d.membershipRevenue.toInt())}',
                    style: const TextStyle(color: kAccentPurple, fontSize: 10)),
              ],
              if ((hasRental || hasMember) && hasFood) const SizedBox(width: 12),
              if (hasFood) ...[
                const Icon(Icons.restaurant_rounded, size: 10, color: Color(0xFFF97316)),
                const SizedBox(width: 4),
                Text('${d.foodOrders} order • Rp ${f.format(d.foodRevenue.toInt())}',
                    style: const TextStyle(color: Color(0xFFF97316), fontSize: 10)),
              ],
            ]),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Food Sales
// ═══════════════════════════════════════════════════════════════════════════
class _FoodSalesCard extends StatelessWidget {
  final ReportFoodSales food;
  const _FoodSalesCard({required this.food});

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _SessStat('Rp ${f.format(food.totalRevenue.toInt())}', 'Penjualan'),
          _SessStat('Rp ${f.format(food.totalHpp.toInt())}', 'HPP Bahan'),
          _SessStat('Rp ${f.format(food.netRevenue.toInt())}', 'Laba Bersih'),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _SessStat('${f.format(food.totalOrders)}', 'Order'),
          _SessStat('Rp ${f.format(food.averageOrderValue.toInt())}', 'Rata²/Order'),
          _SessStat('Rp ${f.format(food.discountAmount.toInt())}', 'Diskon'),
        ]),
        const SizedBox(height: 8),
        Text(
          'Pendapatan bersih = penjualan setelah diskon - HPP bahan. '
          'HPP diambil dari resep bahan yang dipakai menu.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kTextSecondary, fontSize: 10),
        ),
      ]),
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  final List<ReportPaymentMethod> methods;
  const _PaymentMethodsCard({required this.methods});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorderColor)),
        child: PaymentMethodBreakdown(methods: methods),
      );
}

class _FoodItemTile extends StatelessWidget {
  final ReportFoodItem item;
  const _FoodItemTile(this.item);

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'makanan': return 'Makanan';
      case 'minuman': return 'Minuman';
      case 'snack': return 'Snack';
      default: return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id');
    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 38),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor.withAlpha(80)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFF59E0B)]),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(_categoryLabel(item.category),
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.itemName,
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 1),
              Text(
                'HPP/pcs Rp ${f.format(item.hppPerUnit.toInt())} • '
                'Jual/pcs Rp ${f.format(item.revenuePerUnit.toInt())} • '
                'Laba/pcs Rp ${f.format(item.profitPerUnit.toInt())}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kTextSecondary, fontSize: 9),
              ),
            ],
          ),
        ),
        Text('${item.quantitySold}×',
            style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rp ${f.format(item.revenue.toInt())}',
                style: const TextStyle(color: kSuccessColor, fontSize: 12, fontWeight: FontWeight.w600)),
            Text('Bersih: Rp ${f.format(item.netRevenue.toInt())}',
                style: const TextStyle(color: kTextSecondary, fontSize: 10)),
          ],
        ),
      ]),
    );
  }
}
