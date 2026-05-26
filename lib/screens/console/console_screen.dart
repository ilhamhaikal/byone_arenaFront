import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/console_model.dart';
import '../../providers/console_provider.dart';
import 'console_form_dialog.dart';

class ConsoleScreen extends StatefulWidget {
  const ConsoleScreen({super.key});

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  // Filter: 'all' | 'available' | 'in_use' | 'maintenance'
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsoleProvider>().loadAll();
    });
  }

  List<ConsoleModel> _filtered(List<ConsoleModel> all) {
    if (_filter == 'all') return all;
    return all.where((c) => c.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlack,
      appBar: AppBar(
        backgroundColor: kSecondaryColor,
        title: const Text('Manajemen Konsol',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kTextSecondary),
            onPressed: () => context.read<ConsoleProvider>().loadAll(),
          ),
        ],
      ),
      body: Consumer<ConsoleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.consoles.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (provider.error != null && provider.consoles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: kErrorColor, size: 48),
                  const SizedBox(height: 12),
                  Text(provider.error!,
                      style: const TextStyle(color: kErrorColor)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.loadAll();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final filtered = _filtered(provider.consoles);

          return Column(
            children: [
              // ─── Status summary bar ──────────────────────────────────────
              _SummaryBar(consoles: provider.consoles),

              // ─── Filter chips ────────────────────────────────────────────
              Container(
                color: kSecondaryColor,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                          label: 'Semua',
                          value: 'all',
                          current: _filter,
                          onTap: (v) => setState(() => _filter = v)),
                      const SizedBox(width: 8),
                      _FilterChip(
                          label: 'Tersedia',
                          value: 'available',
                          current: _filter,
                          onTap: (v) => setState(() => _filter = v)),
                      const SizedBox(width: 8),
                      _FilterChip(
                          label: 'Dalam Sesi',
                          value: 'in_use',
                          current: _filter,
                          onTap: (v) => setState(() => _filter = v)),
                      const SizedBox(width: 8),
                      _FilterChip(
                          label: 'Maintenance',
                          value: 'maintenance',
                          current: _filter,
                          onTap: (v) => setState(() => _filter = v)),
                    ],
                  ),
                ),
              ),

              // ─── Console list ────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('Tidak ada konsol ditemukan',
                            style: TextStyle(color: kTextSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _ConsoleCard(
                          console: filtered[i],
                          onEdit: () => _openForm(console: filtered[i]),
                          onDelete: () => _confirmDelete(filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: kPrimaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Konsol'),
      ),
    );
  }

  void _openForm({ConsoleModel? console}) {
    showDialog(
      context: context,
      builder: (_) => ConsoleFormDialog(console: console),
    );
  }

  void _confirmDelete(ConsoleModel console) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Konsol'),
        content: Text(
            'Hapus "${console.name}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok =
                  await context.read<ConsoleProvider>().delete(console.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Konsol dihapus' : 'Gagal menghapus'),
                  backgroundColor: ok ? kSuccessColor : kErrorColor,
                ));
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ─── Summary bar ────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final List<ConsoleModel> consoles;
  const _SummaryBar({required this.consoles});

  @override
  Widget build(BuildContext context) {
    final available = consoles.where((c) => c.isAvailable).length;
    final inUse = consoles.where((c) => c.isInUse).length;
    final maintenance = consoles.where((c) => c.isMaintenance).length;
    final total = consoles.length;

    return Container(
      color: kSecondaryColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _StatBadge(label: 'Total', count: total, color: kPrimaryBlue),
          const SizedBox(width: 12),
          _StatBadge(label: 'Tersedia', count: available, color: kSuccessColor),
          const SizedBox(width: 12),
          _StatBadge(label: 'Dalam Sesi', count: inUse, color: kWarningColor),
          const SizedBox(width: 12),
          _StatBadge(label: 'Maintenance', count: maintenance, color: kErrorColor),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Filter chip ─────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;
  const _FilterChip(
      {required this.label,
      required this.value,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kPrimaryBlue.withAlpha(40) : kCardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? kPrimaryBlue : kBorderColor, width: 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? kPrimaryBlue : kTextSecondary,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

// ─── Console card ────────────────────────────────────────────────────────────
class _ConsoleCard extends StatelessWidget {
  final ConsoleModel console;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ConsoleCard(
      {required this.console, required this.onEdit, required this.onDelete});

  Color get _statusColor {
    switch (console.status) {
      case 'available':
        return kSuccessColor;
      case 'in_use':
        return kWarningColor;
      case 'maintenance':
        return kErrorColor;
      default:
        return kTextSecondary;
    }
  }

  String get _statusLabel {
    switch (console.status) {
      case 'available':
        return 'Tersedia';
      case 'in_use':
        return 'Dalam Sesi';
      case 'maintenance':
        return 'Maintenance';
      default:
        return console.status;
    }
  }

  Color get _typeColor {
    switch (console.consoleType) {
      case 'PS5':
        return kPrimaryBlue;
      case 'PS4':
        return kAccentPurple;
      case 'PS3':
        return kNeonPink;
      case 'AndroidTV':
        return kSuccessColor;
      default:
        return kTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Console type icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _typeColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _typeColor.withAlpha(60)),
              ),
              child: Center(
                child: Text(console.consoleType,
                    style: TextStyle(
                        color: _typeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(console.name,
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Status badge
                      _Badge(label: _statusLabel, color: _statusColor),
                      const SizedBox(width: 8),
                      Text(fmt.format(console.pricePerHour) + '/jam',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 12)),
                    ],
                  ),
                  if (console.description != null &&
                      console.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(console.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12)),
                  ],
                  if (console.ipAddress != null &&
                      console.ipAddress!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.router_outlined,
                            size: 12, color: kTextSecondary),
                        const SizedBox(width: 4),
                        Text(console.ipAddress!,
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: kPrimaryBlue,
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: kErrorColor,
                  tooltip: 'Hapus',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(label,
          style:
              TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
