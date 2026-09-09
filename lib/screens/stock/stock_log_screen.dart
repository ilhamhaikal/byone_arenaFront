import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/ingredient_model.dart';
import '../../providers/capital_provider.dart';
import '../../services/ingredient_service.dart';

class StockLogScreen extends StatefulWidget {
  const StockLogScreen({super.key});
  @override
  State<StockLogScreen> createState() => _StockLogScreenState();
}

class _StockLogScreenState extends State<StockLogScreen> {
  final IngredientService _service = IngredientService();
  late DateTime _startDate;
  late DateTime _endDate;
  List<StockLogEntryModel> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1); // awal bulan berjalan
    _endDate = now;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cap = context.read<CapitalProvider>();
    unawaited(cap.loadEntries(
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
    ));
    try {
      final rows = await _service.getStockLog(
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
      );
      if (mounted) setState(() => _entries = rows);
    } catch (_) {
      if (mounted) setState(() => _entries = []);
    } finally {
      if (mounted) setState(() => _loading = false);
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
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
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
        title: const Text('Laporan Stok'),
        actions: [
          TextButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_rounded,
                size: 16, color: kPrimaryBlue),
            label: Text(
                '${dateFmt.format(_startDate)} – ${dateFmt.format(_endDate)}',
                style: const TextStyle(color: kPrimaryBlue, fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Modal awal (pembukuan beli bahan) ─────────────────────
          _CapitalSection(
            onDelete: (id) => context.read<CapitalProvider>().deleteEntry(id),
          ),
          const Divider(color: kBorderColor, height: 1),
          // ── Log stok ──────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimaryBlue))
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 48, color: kTextSecondary),
                            const SizedBox(height: 12),
                            const Text('Tidak ada log stok pada rentang ini',
                                style: TextStyle(color: kTextSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: _pickRange,
                                child: const Text('Ganti Rentang')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: kPrimaryBlue,
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (ctx, i) =>
                              _StockLogTile(entry: _entries[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CapitalSection extends StatelessWidget {
  final void Function(String id) onDelete;
  const _CapitalSection({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'id');
    final dateFmt = DateFormat('dd MMM yyyy', 'id');
    return Consumer<CapitalProvider>(
      builder: (context, cap, _) {
        final entries = cap.entries;
        final total = entries.fold<double>(0, (s, e) => s + e.amount);
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: const BoxDecoration(color: kSurface),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 16, color: kWarningColor),
                  const SizedBox(width: 6),
                  const Text('Modal Awal (Pembelian Bahan)',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (entries.isNotEmpty)
                    Text('Total Rp ${fmt.format(total.toInt())}',
                        style: const TextStyle(
                            color: kWarningColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              if (entries.isEmpty)
                const Text('Belum ada catatan modal pada rentang ini',
                    style: TextStyle(color: kTextSecondary, fontSize: 12))
              else
                ...entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rp ${fmt.format(e.amount.toInt())}',
                                  style: const TextStyle(
                                      color: kTextPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${dateFmt.format(e.entryDate)}'
                                  '${e.notes != null && e.notes!.isNotEmpty ? ' • ${e.notes}' : ''}',
                                  style: const TextStyle(
                                      color: kTextSecondary, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Hapus',
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: kErrorColor),
                            onPressed: () => onDelete(e.id),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _StockLogTile extends StatelessWidget {
  final StockLogEntryModel entry;
  const _StockLogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###.##', 'id');
    final dateFmt = DateFormat('dd MMM yyyy', 'id');
    final isIng = entry.isIngredient;
    final consumed = entry.remaining <= 0;
    final expired = !consumed &&
        entry.expiresAt.isNotEmpty &&
        (DateTime.tryParse(entry.expiresAt) ?? DateTime.now())
            .isBefore(DateTime.now());
    final statusColor =
        consumed ? kTextSecondary : (expired ? kErrorColor : kSuccessColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isIng ? kWarningColor : kPrimaryBlue).withAlpha(25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: (isIng ? kWarningColor : kPrimaryBlue).withAlpha(60)),
            ),
            child: Text(
              isIng ? 'Bahan' : 'Menu',
              style: TextStyle(
                  color: isIng ? kWarningColor : kPrimaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.itemName,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(
                  'Tambah ${fmt.format(entry.quantity)}${entry.unit.isNotEmpty ? ' ${entry.unit}' : ''} • '
                  '${dateFmt.format(DateTime.tryParse(entry.addedAt) ?? DateTime.now())}',
                  style: const TextStyle(color: kTextSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(consumed ? 'Terpakai' : 'Sisa ${fmt.format(entry.remaining)}',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              if (!consumed && entry.expiresAt.isNotEmpty)
                Text(
                  'Kadaluarsa ${dateFmt.format(DateTime.tryParse(entry.expiresAt) ?? DateTime.now())}',
                  style: TextStyle(color: statusColor, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
