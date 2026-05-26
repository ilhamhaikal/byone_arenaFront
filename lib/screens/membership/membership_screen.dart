import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import 'member_form_dialog.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});
  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm([CustomerModel? customer]) {
    showDialog(context: context, builder: (_) => MemberFormDialog(customer: customer));
  }

  Future<void> _confirmDelete(CustomerModel customer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text('Hapus pelanggan ${customer.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final success = await context.read<CustomerProvider>().delete(customer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Pelanggan berhasil dihapus' : 'Gagal menghapus'),
          backgroundColor: success ? kSuccessColor : kErrorColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Data Pelanggan'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: kGradientBlue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: kPrimaryBlue.withAlpha(80), blurRadius: 8)],
              ),
              child: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
            ),
            tooltip: 'Tambah Pelanggan',
            onPressed: _openForm,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search ──
          Container(
            color: const Color(0xFF0A0A0F),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: kTextPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari nama, nomor HP, atau email...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: kTextSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<CustomerProvider>().setSearch('');
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (v) => context.read<CustomerProvider>().setSearch(v),
            ),
          ),
          const Divider(height: 1, color: kBorderColor),
          // ── List ──
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, p, _) {
                if (p.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
                }
                if (p.customers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 56, color: kTextSecondary),
                        SizedBox(height: 16),
                        Text('Belum ada pelanggan',
                            style: TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                        SizedBox(height: 6),
                        Text('Tambahkan pelanggan baru untuk memulai',
                            style: TextStyle(color: kTextSecondary, fontSize: 13)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: kPrimaryBlue,
                  backgroundColor: kSurface,
                  onRefresh: p.loadAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: p.customers.length,
                    itemBuilder: (ctx, i) => _CustomerCard(
                      customer: p.customers[i],
                      onEdit: () => _openForm(p.customers[i]),
                      onDelete: () => _confirmDelete(p.customers[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({required this.customer, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13.5),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 3, color: kPrimaryBlue),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: kGradientBlue,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: kPrimaryBlue.withAlpha(80), blurRadius: 8)],
                    ),
                    child: Center(
                      child: Text(
                        customer.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name,
                            style: const TextStyle(
                                color: kTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 3),
                        Text(customer.phone,
                            style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                        if (customer.email != null && customer.email!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(customer.email!,
                              style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: kTextSecondary, size: 20),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 16, color: kPrimaryBlue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ])),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: kErrorColor),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: kErrorColor)),
                          ])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
