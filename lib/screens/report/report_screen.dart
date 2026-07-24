import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/report_summary_model.dart';
import '../../providers/report_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 7));
    _endDate = now;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<ReportProvider>().loadReport(
          startDate: DateFormat('yyyy-MM-dd').format(_startDate),
          endDate: DateFormat('yyyy-MM-dd').format(_endDate),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Laporan'),
        actions: [
          TextButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_rounded, size: 16, color: kPrimaryBlue),
            label: Text('${dateFmt.format(_startDate)} – ${dateFmt.format(_endDate)}',
                style: const TextStyle(color: kPrimaryBlue, fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, p, _) {
          if (p.isLoading) return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          if (p.error != null) return _buildError(p.error!, _load);
          final r = p.report;
          if (r == null) return const Center(
            child: Text('Pilih rentang tanggal', style: TextStyle(color: kTextSecondary)));
          return RefreshIndicator(
            color: kPrimaryBlue,
            backgroundColor: kSurface,
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _RevenueHero(revenue: r.revenue, period: r.period),
                const SizedBox(height: 16),
                _QuickStats(r),
                const SizedBox(height: 24),
                _SectionHeader('Sesi & Durasi', Icons.timer_rounded),
                const SizedBox(height: 10),
                _SessionsCard(r.sessions),
                const SizedBox(height: 24),
                _SectionHeader('Penggunaan Konsol', Icons.sports_esports_rounded),
                const SizedBox(height: 10),
                if (r.consoles.isEmpty) _EmptyTile('Belum ada data')
                else ...r.consoles.map((c) => _ConsoleTile(c)),
                const SizedBox(height: 24),
                _SectionHeader('Voucher Terpakai', Icons.confirmation_number_rounded),
                const SizedBox(height: 10),
                if (r.vouchers.isEmpty) _EmptyTile('Belum ada penggunaan voucher')
                else ...r.vouchers.map((v) => _VoucherTile(v)),
                // ── Food Sales section ──
                if (r.foodSales != null && r.foodSales!.totalOrders > 0) ...[
                  const SizedBox(height: 24),
                  _SectionHeader('Pendapatan Makanan/Minuman/Snack', Icons.restaurant_rounded),
                  const SizedBox(height: 10),
                  _FoodSalesCard(food: r.foodSales!),
                  if (r.foodSales!.topItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 38, bottom: 4),
                      child: Text('Item Terlaris',
                          style: TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    ...r.foodSales!.topItems.map((item) => _FoodItemTile(item)),
                  ],
                ],
                const SizedBox(height: 24),
                _SectionHeader('Rincian Harian', Icons.calendar_today_rounded),
                const SizedBox(height: 10),
                if (r.dailyBreakdown.isEmpty) _EmptyTile('Belum ada data')
                else ...r.dailyBreakdown.map((d) => _DailyTile(d)),
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
// Revenue Hero
// ═══════════════════════════════════════════════════════════════════════════
class _RevenueHero extends StatelessWidget {
  final ReportRevenue revenue;
  final ReportPeriod period;
  const _RevenueHero({required this.revenue, required this.period});

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F0F2E), Color(0xFF0A0A14)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryBlue.withAlpha(25)),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withAlpha(12), blurRadius: 30, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Rp ${f.format(revenue.totalRevenue.toInt())}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kTextPrimary, letterSpacing: -1)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(gradient: kGradientBlue, borderRadius: BorderRadius.circular(20)),
            child: Text('${period.totalDays} hari', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 2),
        const Text('PENDAPATAN BERSIH', style: TextStyle(color: kTextSecondary, fontSize: 11, letterSpacing: 2)),
        const SizedBox(height: 16),
        Row(children: [
          _HeroChip('Kotor', 'Rp ${f.format(revenue.totalBaseAmount.toInt())}'),
          const SizedBox(width: 20),
          _HeroChip('Diskon', '-Rp ${f.format((revenue.totalDiscount + revenue.totalAutoDiscount).toInt())}'),
          const SizedBox(width: 20),
          _HeroChip('Voucher', '-Rp ${f.format(revenue.voucherDiscount.toInt())}'),
        ]),
        if (revenue.dailyRentalRevenue > 0 || revenue.membershipRevenue > 0 || revenue.foodSalesRevenue > 0) ...[
          const SizedBox(height: 12),
          Row(children: [
            if (revenue.dailyRentalRevenue > 0) ...[
              _HeroChip('Rental Harian', 'Rp ${f.format(revenue.dailyRentalRevenue.toInt())} (${revenue.dailyRentalCount})'),
              const SizedBox(width: 20),
            ],
            if (revenue.membershipRevenue > 0) ...[
              _HeroChip('Membership', 'Rp ${f.format(revenue.membershipRevenue.toInt())} (${revenue.membershipCount})'),
              const SizedBox(width: 20),
            ],
            if (revenue.foodSalesRevenue > 0)
              _HeroChip('Makanan', 'Rp ${f.format(revenue.foodSalesRevenue.toInt())} (${revenue.foodSalesCount})'),
          ]),
        ],
      ]),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label, value;
  const _HeroChip(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
    Text(value, style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
    Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 10)),
  ]);
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
        Expanded(child: _QStat(label: 'Durasi', value: '${r.sessions.totalPlayMinutes ~/ 60}h ${r.sessions.totalPlayMinutes % 60}m', icon: Icons.timer_rounded, g: kGradientPurple)),
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
  const _SectionHeader(this.title, this.icon);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 28, height: 28, decoration: BoxDecoration(gradient: kGradientBlue, borderRadius: BorderRadius.circular(7)), child: Icon(icon, color: Colors.white, size: 14)),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
  ]);
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
      _SessStat('${s.totalPlayMinutes ~/ 60}h ${s.totalPlayMinutes % 60}m', 'Durasi'),
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
      Text('${c.totalMinutes ~/ 60}h ${c.totalMinutes % 60}m', style: const TextStyle(color: kTextSecondary, fontSize: 11)),
    ]),
  );

  LinearGradient _typeGrad(String t) { switch (t) { case 'PS5': return kGradientPurple; case 'PS3': return kGradientPink; case 'Switch': return kGradientPink; default: return kGradientBlue; } }
}

class _VoucherTile extends StatelessWidget {
  final ReportVoucherUsage v;
  const _VoucherTile(this.v);
  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###', 'id');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderColor)),
      child: Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(gradient: kGradientPurple, borderRadius: BorderRadius.circular(5)), child: Text(v.voucherCode, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        const SizedBox(width: 10),
        Expanded(child: Text(v.voucherName, style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
        Text('${v.usageCount}×', style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        const SizedBox(width: 10),
        Text('Rp ${f.format(v.totalDiscount.toInt())}', style: const TextStyle(color: kSuccessColor, fontSize: 12, fontWeight: FontWeight.w600)),
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
              Text('${d.playMinutes ~/ 60}h ${d.playMinutes % 60}m', style: const TextStyle(color: kTextSecondary, fontSize: 11)),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SessStat('Rp ${f.format(food.totalRevenue.toInt())}', 'Total'),
          _SessStat('${f.format(food.totalOrders)}', 'Order'),
          _SessStat('Rp ${f.format(food.averageOrderValue.toInt())}', 'Rata²/Order'),
        ],
      ),
    );
  }
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
        Expanded(child: Text(item.itemName,
            style: const TextStyle(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w500))),
        Text('${item.quantitySold}×',
            style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        const SizedBox(width: 10),
        Text('Rp ${f.format(item.revenue.toInt())}',
            style: const TextStyle(color: kSuccessColor, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
