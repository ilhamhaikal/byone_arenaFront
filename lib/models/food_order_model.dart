import 'menu_model.dart';
import 'customer_model.dart';
import 'session_model.dart';

class FoodOrderItemModel {
  final String id;
  final String orderId;
  final String menuItemId;
  final MenuModel? menuItem;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final DateTime createdAt;

  FoodOrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    this.menuItem,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    required this.createdAt,
  });

  factory FoodOrderItemModel.fromJson(Map<String, dynamic> json) {
    return FoodOrderItemModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      menuItemId: json['menuItemId'] as String,
      menuItem: json['menuItem'] != null
          ? MenuModel.fromJson(json['menuItem'] as Map<String, dynamic>)
          : null,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class FoodOrderModel {
  final String id;
  final String orderNumber;
  final String sessionId;
  final SessionModel? session;
  final String? customerId;
  final CustomerModel? customer;
  final List<FoodOrderItemModel> items;
  final String? notes;
  final String status; // pending, preparing, served, cancelled
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodOrderModel({
    required this.id,
    required this.orderNumber,
    required this.sessionId,
    this.session,
    this.customerId,
    this.customer,
    required this.items,
    this.notes,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodOrderModel.fromJson(Map<String, dynamic> json) {
    return FoodOrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      sessionId: json['sessionId'] as String,
      session: json['session'] != null
          ? SessionModel.fromJson(json['session'] as Map<String, dynamic>)
          : null,
      customerId: json['customerId'] as String?,
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  FoodOrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
      status: json['status'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'preparing':
        return 'Disiapkan';
      case 'served':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  static const List<String> statusValues = [
    'pending',
    'preparing',
    'served',
    'cancelled',
  ];
}
