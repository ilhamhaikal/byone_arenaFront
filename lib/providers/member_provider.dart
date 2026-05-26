import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../services/mock_data.dart';

class MemberProvider extends ChangeNotifier {
  List<MemberModel> _members = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterType = '';
  int _nextId = 100;

  List<MemberModel> get members => _filteredMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<MemberModel> get _filteredMembers {
    var list = _members;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) =>
          m.fullName.toLowerCase().contains(q) ||
          m.memberCode.toLowerCase().contains(q) ||
          m.phone.contains(q)).toList();
    }
    if (_filterType.isNotEmpty) {
      list = list.where((m) => m.membershipType == _filterType).toList();
    }
    return list;
  }

  Future<void> loadMembers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _members = List.from(MockData.members);
    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String type) {
    _filterType = type;
    notifyListeners();
  }

  Future<MemberModel?> getMemberByCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _members.firstWhere(
          (m) => m.memberCode.toLowerCase() == code.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<bool> createMember(MemberModel member) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final created = MemberModel(
      id: _nextId++,
      memberCode: 'MBR-${_nextId.toString().padLeft(3, '0')}',
      fullName: member.fullName,
      phone: member.phone,
      email: member.email,
      membershipType: member.membershipType,
      totalPoints: 0,
      registeredAt: DateTime.now(),
      expiredAt: member.expiredAt,
      isActive: true,
    );
    _members.insert(0, created);
    notifyListeners();
    return true;
  }

  Future<bool> updateMember(int id, MemberModel member) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _members.indexWhere((m) => m.id == id);
    if (index != -1) {
      _members[index] = MemberModel(
        id: id,
        memberCode: _members[index].memberCode,
        fullName: member.fullName,
        phone: member.phone,
        email: member.email,
        membershipType: member.membershipType,
        totalPoints: _members[index].totalPoints,
        registeredAt: _members[index].registeredAt,
        expiredAt: member.expiredAt,
        isActive: member.isActive,
      );
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteMember(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _members.removeWhere((m) => m.id == id);
    notifyListeners();
    return true;
  }
}
