import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/tv_notification_model.dart';
import '../../providers/notification_provider.dart';
import 'notification_form_dialog.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadAll();
    });
  }

  void _openForm([TvNotificationModel? n]) {
    showDialog(context: context, builder: (_) => NotificationFormDialog(notification: n)).then((_) {
      context.read<NotificationProvider>().loadAll();
    });
  }

  Future<void> _confirmDelete(TvNotificationModel n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Notifikasi'),
        content: Text('Hapus "${n.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<NotificationProvider>().delete(n.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Notifikasi Promosi'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: kGradientPink,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: kNeonPink.withAlpha(80), blurRadius: 8)],
              ),
              child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            ),
            onPressed: _openForm,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, p, _) {
          if (p.isLoading && p.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (p.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorderColor)),
                    child: const Icon(Icons.campaign_outlined, size: 36, color: kTextSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Belum ada notifikasi', style: TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: _openForm, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Buat Notifikasi')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: kPrimaryBlue,
            backgroundColor: kSurface,
            onRefresh: p.loadAll,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: p.notifications.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) return _LoopControl(p);
                final n = p.notifications[i - 1];
                return _NotificationCard(
                  notification: n,
                  onEdit: () => _openForm(n),
                  onDelete: () => _confirmDelete(n),
                  onToggle: () => p.toggle(n.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LoopControl extends StatelessWidget {
  final NotificationProvider p;
  const _LoopControl(this.p);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.isLoopRunning ? kSuccessColor.withAlpha(80) : kBorderColor),
      ),
      child: Row(
        children: [
          Icon(p.isLoopRunning ? Icons.loop_rounded : Icons.loop_rounded, color: p.isLoopRunning ? kSuccessColor : kTextSecondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(p.isLoopRunning ? 'Looping sedang berjalan' : 'Looping tidak aktif',
                style: TextStyle(color: p.isLoopRunning ? kSuccessColor : kTextSecondary, fontSize: 13)),
          ),
          OutlinedButton(
            onPressed: p.isLoopRunning ? p.stopLoop : p.startLoop,
            style: OutlinedButton.styleFrom(
              foregroundColor: p.isLoopRunning ? kErrorColor : kSuccessColor,
              side: BorderSide(color: (p.isLoopRunning ? kErrorColor : kSuccessColor).withAlpha(120)),
            ),
            child: Text(p.isLoopRunning ? 'Stop' : 'Mulai'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final TvNotificationModel notification;
  final VoidCallback onEdit, onDelete, onToggle;
  const _NotificationCard({required this.notification, required this.onEdit, required this.onDelete, required this.onToggle});

  Color get _priorityColor => notification.priority == 'high' ? kErrorColor : notification.priority == 'normal' ? kPrimaryBlue : kTextSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: notification.isActive ? _priorityColor.withAlpha(60) : kBorderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(notification.title,
                      style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _priorityColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _priorityColor.withAlpha(60)),
                  ),
                  child: Text(notification.priorityLabel,
                      style: TextStyle(color: _priorityColor, fontSize: 9, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (notification.isActive ? kSuccessColor : kErrorColor).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(notification.isActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(color: notification.isActive ? kSuccessColor : kErrorColor, fontSize: 9, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(notification.message,
                  style: const TextStyle(color: kTextSecondary, fontSize: 11),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
          if (notification.loopEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
              child: Row(
                children: [
                  const Icon(Icons.loop_rounded, size: 10, color: kTextSecondary),
                  const SizedBox(width: 3),
                  Text('Loop tiap ${notification.loopInterval}s',
                      style: const TextStyle(color: kTextSecondary, fontSize: 9)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                const Icon(Icons.tv_rounded, size: 10, color: kTextSecondary),
                const SizedBox(width: 3),
                Text(
                  notification.targetAll
                      ? 'Semua konsol'
                      : '${notification.targetConsoleIds.length} konsol',
                  style: const TextStyle(color: kTextSecondary, fontSize: 9),
                ),
                if (notification.activeSessionsOnly) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.play_circle_rounded, size: 10, color: kSuccessColor),
                  const SizedBox(width: 3),
                  const Text('Sesi aktif',
                      style: TextStyle(color: kSuccessColor, fontSize: 9)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: kDeepBlack, borderRadius: BorderRadius.circular(6), border: Border.all(color: kBorderColor)),
                    child: Icon(notification.isActive ? Icons.toggle_on : Icons.toggle_off, size: 14, color: notification.isActive ? _priorityColor : kTextSecondary),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: kDeepBlack, borderRadius: BorderRadius.circular(6), border: Border.all(color: kBorderColor)),
                    child: const Icon(Icons.edit_outlined, size: 14, color: kPrimaryBlue),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: kDeepBlack, borderRadius: BorderRadius.circular(6), border: Border.all(color: kBorderColor)),
                    child: const Icon(Icons.delete_outline, size: 14, color: kErrorColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
