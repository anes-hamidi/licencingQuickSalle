import 'package:cloud_firestore/cloud_firestore.dart';

class License {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String type;
  final String licenseKey;
  final DateTime createdAt;
  final DateTime expiryDate;
  final bool isActive;
  final String assignedTo; // userId who owns the license

  License({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.type,
    required this.licenseKey,
    required this.createdAt,
    required this.expiryDate,
    required this.isActive,
    required this.assignedTo,
  });

  factory License.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return License(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      type: data['type'] ?? '',
      licenseKey: data['licenseKey'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? false,
      assignedTo: data['assignedTo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'type': type,
      'licenseKey': licenseKey,
      'createdAt': createdAt,
      'expiryDate': expiryDate,
      'isActive': isActive,
      'assignedTo': assignedTo,
    };
  }
}

enum LicenseStatus {
  activeLicense,
  trialActive,
  expired,
  none,
}

class LicenseStatusResult {
  final LicenseStatus status;
  final int? trialDaysRemaining;
  final DateTime? expiryDate;
  final String? licenseKey;

  const LicenseStatusResult({
    required this.status,
    this.trialDaysRemaining,
    this.expiryDate,
    this.licenseKey,
  });

  bool get hasAccess =>
      status == LicenseStatus.activeLicense ||
      status == LicenseStatus.trialActive;
}
