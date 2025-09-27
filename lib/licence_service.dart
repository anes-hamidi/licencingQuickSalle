// services/license_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseServices {
  static const String _licenseKey = "licenseKey";
  static const String _trialStartDateKey = "trialStartDate";
  static const int trialDays = 7;

  final _licenses = FirebaseFirestore.instance.collection("licenses");
  final _freeTrial = FirebaseFirestore.instance
      .collection("licenses")
      .doc("free_trial")
      .collection("keys");

  DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  // 🔹 Local license
  Future<void> saveLicenseLocally(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_licenseKey, key);
  }

  Future<String?> getSavedLicense() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_licenseKey);
  }

  Future<void> clearLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_licenseKey);
  }

  // 🔹 Local trial
  Future<void> startTrial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_trialStartDateKey)) {
      await prefs.setString(_trialStartDateKey, DateTime.now().toIso8601String());
    }
  }


  // 🔹 Trial (server + fallback)
  
  
  // 🔹 License validation
  Future<bool> validateLicense(String key) async {
    if (key.isEmpty) return false;
    try {
      final snapshot = await _licenses.doc(key).get();
      if (!snapshot.exists) return false;

      final data = snapshot.data();
      if (data == null) return false;

      final expiryDate = _parseDate(data["expiryDate"]);
      if (expiryDate == null) return false;

      final isActive = data["isActive"] == true;
      final isExpired = DateTime.now().isAfter(expiryDate);

      return isActive && !isExpired;
    } catch (e, st) {
      debugPrint("⚠️ validateLicense error: $e\n$st");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLicenseByUserId(String userId) async {
    try {
      final licenseQuery = await _licenses.where("userId", isEqualTo: userId).limit(1).get();
      final trialQuery = await _freeTrial.where("userId", isEqualTo: userId).limit(1).get();

      if (licenseQuery.docs.isEmpty && trialQuery.docs.isEmpty) return null;

      final licenseDoc = licenseQuery.docs.isNotEmpty ? licenseQuery.docs.first : null;
      final trialDoc = trialQuery.docs.isNotEmpty ? trialQuery.docs.first : null;

      return {
        if (trialDoc != null) ...trialDoc.data(),
        if (licenseDoc != null) ...licenseDoc.data(),
        "id": trialDoc?.id ?? licenseDoc?.id,
      };
    } catch (e, st) {
      debugPrint("⚠️ getLicenseByUserId error: $e\n$st");
      return null;
    }
  }

}
