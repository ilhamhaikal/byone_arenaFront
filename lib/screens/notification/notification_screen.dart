import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/permissions.dart';
import '../../models/tv_notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_dialog.dart';
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
    showDialog(
      context: context,
      builder: (_) => NotificationFormDialog(notification: n),
    );
  }

  Future<void> _toggle(TvNotificationModel n) async {
    final p = context.read<NotificationProvider>();
    final ok = await p.toggle(n.id);
    if (!mounted) return;
    if (!ok) {
      showErrorDialog(p.error ?? 'Gagal mengubah status notifikasi');
    }
  }

  Future<void> _show(TvNotificationModel n) async {
    final p = context.read<NotificationProvider>();
    final ok = await p.show(n.id);
    if (!mounted) return;
    if (ok) {
      showSuccessDialog(
        'Notifikasi "${n.title}" sedang ditampilkan di TV.',
        title: 'Notifikasi Dikirim',
      );
    } else {
      showErrorDialog(p.error ?? 'Gagal menampilkan notifikasi');
    }
  }

  Future<void> _startLoop() async {
    final p = context.read<NotificationProvider>();
    final ok = await p.startLoop();
    if (!mounted) return;
    if (ok) {
      showSuccessDialog('Looping notifikasi dimulai.');
    } else {
      showErrorDialog(p.error ?? 'Gagal memulai looping notifikasi');
    }
  }

  Future<void> _stopLoop() async {
    final p = context.read<NotificationProvider>();
    final ok = await p.stopLoop();
    if (!mounted) return;
    if (ok) {
      showSuccessDialog('Looping notifikasi dihentikan.');
    } else {
      showErrorDialog(p.error ?? 'Gagal menghentikan looping notifikasi');
    }
  }

  Future<void> _confirmDelete(TvNotificationModel n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Notifikasi'),
        content: Text('Hapus "${n.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final p = context.read<NotificationProvider>();
    final deleted = await p.delete(n.id);
    if (!mounted) return;
    if (deleted) {
      showSuccessDialog(
        'Notifikasi "${n.title}" berhasil dihapus.',
        title: 'Notifikasi Dihapus',
      );
    } else {
      showErrorDialog(p.error ?? 'Gagal menghapus notifikasi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canWrite = canWriteMenu(user, 'notif');
    final canDelete = canDeleteMenu(user, 'notif');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Notifikasi Promosi'),
        actions: [
          if (canWrite)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: kGradientPink,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: kNeonPink.withAlpha(80), blurRadius: 8)
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    size: 16, color: Colors.white),
              ),
              onPressed: _openForm,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, p, _) {
          if (p.isLoading && p.notifications.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (p.notifications.isEmpty) {
            if (p.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 42, color: kErrorColor),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        p.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: p.loadAll,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorderColor)),
                    child: const Icon(Icons.campaign_outlined,
                        size: 36, color: kTextSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Belum ada notifikasi',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  if (canWrite) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        onPressed: _openForm,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Buat Notifikasi')),
                  ],
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
                if (i == 0) {
                  return _LoopControl(
                    p,
                    canWrite: canWrite,
                    onStart: _startLoop,
                    onStop: _stopLoop,
                  );
                }
                final n = p.notifications[i - 1];
                final busy = p.isPending(n.id);
                return _NotificationCard(
                  notification: n,
                  busy: busy,
                  onEdit: canWrite && !busy ? () => _openForm(n) : null,
                  onDelete:
                      canDelete && !busy ? () => _confirmDelete(n) : null,
                  onToggle: canWrite && !busy ? () => _toggle(n) : null,
                  onShow: canWrite && !busy ? () => _show(n) : null,
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
  final bool canWrite;
  final VoidCallback onStart;
  final VoidCallback onStop;
  const _LoopControl(
    this.p, {
    required this.canWrite,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final running = p.isLoopRunning;
    final count = p.activeLoopCount;
    // Server bisa saja belum melaporkan jumlah (mis. endpoint status gagal);
    // daftar lokal dipakai sebagai fallback supaya tombol Mulai tetap bisa
    // dipakai ketika jelas ada notifikasi loop yang aktif.
    final hasCandidate = count > 0 || p.hasLoopCandidate;
    final canStart = canWrite && !p.loopBusy && hasCandidate;
    final statusText = running
        ? 'Looping berjalan • $count notifikasi'
        : hasCandidate
            ? '$count notifikasi siap di-loop'
            : 'Belum ada notifikasi looping aktif';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: running ? kSuccessColor.withAlpha(80) : kBorderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.loop_rounded,
              color: running ? kSuccessColor : kTextSecondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                  color: running ? kSuccessColor : kTextSecondary,
                  fontSize: 13),
            ),
          ),
          if (p.loopBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            OutlinedButton(
              onPressed: !canWrite
                  ? null
                  : running
                      ? onStop
                      : (canStart ? onStart : null),
              style: OutlinedButton.styleFrom(
                foregroundColor: running ? kErrorColor : kSuccessColor,
                side: BorderSide(
                    color: (running ? kErrorColor : kSuccessColor)
                        .withAlpha(120)),
              ),
              child: Text(running ? 'Stop' : 'Mulai'),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final TvNotificationModel notification;
  final bool busy;
  final VoidCallback? onEdit, onDelete, onToggle, onShow;
  const _NotificationCard({
    required this.notification,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onShow,
  });

  Color get _priorityColor => notification.priority == 'high'
      ? kErrorColor
      : notification.priority == 'normal'
          ? kPrimaryBlue
          : kTextSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: notification.isActive
                ? _priorityColor.withAlpha(60)
                : kBorderColor),
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
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _priorityColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _priorityColor.withAlpha(60)),
                  ),
                  child: Text(notification.priorityLabel,
                      style: TextStyle(
                          color: _priorityColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (notification.isActive ? kSuccessColor : kErrorColor)
                        .withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(notification.isActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                          color: notification.isActive
                              ? kSuccessColor
                              : kErrorColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
          if (notification.loopEnabled && notification.autoShow)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
              child: Row(
                children: [
                  const Icon(Icons.loop_rounded,
                      size: 10, color: kTextSecondary),
                  const SizedBox(width: 3),
                  Text('Loop tiap ${notification.loopInterval}s',
                      style:
                          const TextStyle(color: kTextSecondary, fontSize: 9)),
                ],
              ),
            ),
          if (notification.loopEnabled && !notification.autoShow)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 2),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 10, color: kWarningColor),
                  SizedBox(width: 3),
                  Text('Loop tidak berlaku untuk notifikasi manual',
                      style: TextStyle(color: kWarningColor, fontSize: 9)),
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
                  const Icon(Icons.play_circle_rounded,
                      size: 10, color: kSuccessColor),
                  const SizedBox(width: 3),
                  const Text('Sesi aktif',
                      style: TextStyle(color: kSuccessColor, fontSize: 9)),
                ],
                if (!notification.autoShow) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.campaign_rounded,
                      size: 10, color: kWarningColor),
                  const SizedBox(width: 3),
                  const Text('Manual',
                      style: TextStyle(color: kWarningColor, fontSize: 9)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(4),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                if (onShow != null)
                  Tooltip(
                    message: notification.isActive
                        ? 'Tampilkan sekarang di TV'
                        : 'Aktifkan notifikasi terlebih dahulu',
                    child: InkWell(
                      onTap: notification.isActive ? onShow : null,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: kDeepBlack,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: (notification.isActive
                                      ? kSuccessColor
                                      : kTextSecondary)
                                  .withAlpha(90)),
                        ),
                        child: Icon(Icons.campaign_rounded,
                            size: 14,
                            color: notification.isActive
                                ? kSuccessColor
                                : kTextSecondary),
                      ),
                    ),
                  ),
                if (onShow != null && onToggle != null)
                  const SizedBox(width: 4),
                if (onToggle != null)
                  InkWell(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: kDeepBlack,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: kBorderColor)),
                      child: Icon(
                          notification.isActive
                              ? Icons.toggle_on
                              : Icons.toggle_off,
                          size: 14,
                          color: notification.isActive
                              ? _priorityColor
                              : kTextSecondary),
                    ),
                  ),
                if (onToggle != null && onEdit != null)
                  const SizedBox(width: 4),
                if (onEdit != null)
                  InkWell(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: kDeepBlack,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: kBorderColor)),
                      child: const Icon(Icons.edit_outlined,
                          size: 14, color: kPrimaryBlue),
                    ),
                  ),
                if (onEdit != null && onDelete != null)
                  const SizedBox(width: 4),
                if (onDelete != null)
                  InkWell(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: kDeepBlack,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: kBorderColor)),
                      child: const Icon(Icons.delete_outline,
                          size: 14, color: kErrorColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
