import 'package:flutter/foundation.dart';

class CompanyInfo {
  final String? id;
  final String userId;
  final String name;
  final String address;
  final String phone;
  final String? email;

  CompanyInfo({
    this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.phone,
    this.email,
  });

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'user_id': userId,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
} 