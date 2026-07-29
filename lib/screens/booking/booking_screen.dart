import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/console_provider.dart';
import '../../providers/customer_provider.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<BookingProvider>().loadAll();
    context.read<ConsoleProvider>().loadAll();
    context.read<CustomerProvider>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Booking / Reservasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kTextSecondary),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: kPrimaryBlue),
            onPressed: () => _openForm(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (_, p, __) {
          if (p.error != null) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 48, color: kErrorColor),
              const SizedBox(height: 8),
              Text(p.error!, style: const TextStyle(color: kErrorColor, fontSize: 13)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
            ]));
          }
          if (p.isLoading && p.bookings.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (p.bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 56, color: kTextSecondary),
                  SizedBox(height: 12),
                  Text('Belum ada booking',
                      style: TextStyle(color: kTextSecondary, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('Tekan + untuk membuat reservasi',
                      style: TextStyle(color: kTextSecondary, fontSize: 12)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: kPrimaryBlue,
            onRefresh: () async => _load(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: p.bookings.length,
              itemBuilder: (_, i) => _BookingCard(booking: p.bookings[i]),
            ),
          );
        },
      ),
    );
  }

  void _openForm() {
    showDialog(
      context: context,
      builder: (_) => const _BookingFormDialog(),
    ).then((_) => _load());
  }
}

// ─── Booking Card ───────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed':
        return kSuccessColor;
      case 'cancelled':
        return kErrorColor;
      case 'completed':
        return kPrimaryBlue;
      default:
        return kWarningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, d MMM yyyy', 'id')
        .format(DateTime.parse(booking.bookingDate));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor.withAlpha(80)),
              ),
              child: Text(booking.statusLabel,
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Text(date,
                style: const TextStyle(color: kTextSecondary, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.sports_esports_rounded,
                size: 16, color: kTextSecondary),
            const SizedBox(width: 6),
            Text(booking.consoleName ?? booking.consoleId,
                style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            if (booking.consoleType != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: kPrimaryBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(booking.consoleType!,
                    style: const TextStyle(
                        color: kPrimaryBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: kTextSecondary),
            const SizedBox(width: 6),
            Text(booking.customerName ?? 'Umum',
                style: const TextStyle(color: kTextSecondary, fontSize: 12)),
            const SizedBox(width: 14),
            const Icon(Icons.timer_rounded, size: 14, color: kTextSecondary),
            const SizedBox(width: 6),
            Text('${booking.timeSlot} • ${booking.durationLabel}',
                style: const TextStyle(color: kTextSecondary, fontSize: 12)),
          ]),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(booking.notes!,
                style: const TextStyle(
                    color: kTextSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
          ],
          if (booking.isPending) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _changeStatus(context, 'confirmed'),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Konfirmasi', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: kSuccessColor,
                      side: BorderSide(color: kSuccessColor.withAlpha(100))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _changeStatus(context, 'cancelled'),
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Batalkan', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: kErrorColor,
                      side: BorderSide(color: kErrorColor.withAlpha(100))),
                ),
              ),
            ]),
          ],
          if (booking.isConfirmed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _changeStatus(context, 'completed'),
                icon: const Icon(Icons.done_all, size: 14),
                label: const Text('Tandai Selesai', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryBlue,
                    side: BorderSide(color: kPrimaryBlue.withAlpha(100))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _changeStatus(BuildContext context, String status) async {
    final labels = {
      'confirmed': 'Konfirmasi',
      'cancelled': 'Batalkan',
      'completed': 'Selesaikan',
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${labels[status]} Booking?'),
        content: Text('${labels[status]} booking ${booking.consoleName ?? booking.consoleId}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(labels[status]!)),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final p = context.read<BookingProvider>();
      bool success = false;
      switch (status) {
        case 'confirmed':
          success = await p.confirm(booking.id);
          break;
        case 'cancelled':
          success = await p.cancel(booking.id);
          break;
        case 'completed':
          success = await p.complete(booking.id);
          break;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Berhasil' : p.error ?? 'Gagal'),
          backgroundColor: success ? kSuccessColor : kErrorColor,
        ));
      }
    }
  }
}

// ─── Booking Form Dialog ────────────────────────────────────────────────────
class _BookingFormDialog extends StatefulWidget {
  const _BookingFormDialog();
  @override
  State<_BookingFormDialog> createState() => _BookingFormDialogState();
}

class _BookingFormDialogState extends State<_BookingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _consoleId;
  String? _customerId;
  final _dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1))));
  final _hourCtrl = TextEditingController(text: '10');
  final _minuteCtrl = TextEditingController(text: '00');
  final _durationCtrl = TextEditingController(text: '60');
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_consoleId == null) return;
    setState(() => _loading = true);
    final ok = await context.read<BookingProvider>().create(
          consoleId: _consoleId!,
          customerId: _customerId,
          bookingDate: _dateCtrl.text.trim(),
          startHour: int.tryParse(_hourCtrl.text) ?? 10,
          startMinute: int.tryParse(_minuteCtrl.text) ?? 0,
          durationMinutes: int.tryParse(_durationCtrl.text) ?? 60,
          notes: _notesCtrl.text.trim(),
        );
    setState(() => _loading = false);
    if (mounted) {
      if (ok != null) {
        Navigator.pop(context);
      } else {
        final err = context.read<BookingProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err ?? 'Gagal membuat booking'),
          backgroundColor: kErrorColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final consoles = context.watch<ConsoleProvider>().consoles;
    final customers = context.watch<CustomerProvider>().customers;

    return AlertDialog(
      title: const Text('Buat Booking'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _consoleId,
                  decoration: const InputDecoration(labelText: 'Konsol'),
                  items: consoles.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      )).toList(),
                  onChanged: (v) => setState(() => _consoleId = v),
                  validator: (v) => v == null ? 'Pilih konsol' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _customerId,
                  decoration: const InputDecoration(labelText: 'Pelanggan (opsional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Umum (walk-in)')),
                    ...customers.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} (${c.phone})'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _customerId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateCtrl,
                  decoration: const InputDecoration(labelText: 'Tanggal (YYYY-MM-DD)'),
                  validator: (v) => v?.isEmpty == true ? 'Isi tanggal' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hourCtrl,
                      decoration: const InputDecoration(labelText: 'Jam (0-23)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _minuteCtrl,
                      decoration: const InputDecoration(labelText: 'Menit (0-59)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationCtrl,
                  decoration: const InputDecoration(labelText: 'Durasi (menit)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Simpan')),
      ],
    );
  }
}
