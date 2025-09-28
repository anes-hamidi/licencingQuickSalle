import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/license.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _searchController = TextEditingController();

  License? _generatedLicense;
  bool _isGenerating = false;
  bool _isLoading = false;
  bool _isCheckingLicense = false;

  String _selectedType = "1 Month";
  String? _selectedUserId;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  License? _userLicense;

  final List<String> _licenseTypes = [
    "1 Month",
    "6 Months",
    "1 Year",
    "Lifetime",
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('customers').get();
      _users = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      _filteredUsers = _users;
    } catch (e) {
      debugPrint("Error loading users: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

 
  Future<void> _checkUserLicense(String userId) async {
    setState(() {
      _isCheckingLicense = true;
      _userLicense = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("licenses")
          .where("assignedTo", isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _userLicense = License.fromFirestore(snapshot.docs.first);
      }
    } catch (e) {
      debugPrint("Error checking license: $e");
    } finally {
      setState(() => _isCheckingLicense = false);
    }
  }
Future<void> _generateLicense({bool isUpdate = false}) async {
  if (_selectedUserId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Please select a user")),
    );
    return;
  }

  setState(() => _isGenerating = true);

  try {
    final selectedUser =
        _users.firstWhere((user) => user['id'] == _selectedUserId);

    final docRef =
        FirebaseFirestore.instance.collection("licenses").doc(_selectedUserId);

    final existingDoc = await docRef.get();

    if (existingDoc.exists && !isUpdate) {
      // ⚠️ Block if trying to generate a new license when one already exists
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ This user already has a license."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final licenseKey = DateTime.now().millisecondsSinceEpoch.toString();
    final expiryDate = _selectedType == "1 Month"
        ? DateTime.now().add(const Duration(days: 30))
        : _selectedType == "6 Months"
            ? DateTime.now().add(const Duration(days: 180))
            : _selectedType == "1 Year"
                ? DateTime.now().add(const Duration(days: 365))
                : DateTime.now().add(const Duration(days: 365 * 100));

    final license = License(
      id: _selectedUserId!, // license id = selected user id
      name: selectedUser['name'],
      email: selectedUser['email'],
      phone: selectedUser['phone'],
      type: _selectedType,
      licenseKey: licenseKey,
      createdAt: DateTime.now(),
      expiryDate: expiryDate,
      isActive: true,
      assignedTo: _selectedUserId!,
    );

    // 🔹 Save/Update license
    await docRef.set(license.toJson());

    setState(() {
      _isGenerating = false;
      _generatedLicense = license;
      _userLicense = license; // update UI
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isUpdate
            ? "🔄 License updated successfully"
            : "✅ License generated successfully"),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    debugPrint("Error generating/updating license: $e");
    setState(() => _isGenerating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Error: $e")),
    );
  }
}


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = _selectedUserId != null
        ? _users.firstWhere((u) => u['id'] == _selectedUserId)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text("License Generator")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("Generate a License Key",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // 🔎 Search user
          
            // 👤 User dropdown
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedUserId,
                items: _filteredUsers.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['id'],
                    child: Text(user['name']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedUserId = val);
                  if (val != null) _checkUserLicense(val);
                },
                decoration: const InputDecoration(
                  labelText: "Select User",
                  border: OutlineInputBorder(),
                ),
              ),

            if (selectedUser != null) ...[
              const SizedBox(height: 20),
              Text("👤 ${selectedUser['name']}"),
              Text("📧 ${selectedUser['email']}"),
              Text("📞 ${selectedUser['phone']}"),
              const SizedBox(height: 10),

              if (_isCheckingLicense)
                const Center(child: CircularProgressIndicator())
              else if (_userLicense != null)
                Card(
                  color: Colors.blue.shade50,
                  child: ListTile(
                    title: const Text("📜 Existing License"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Key: ${_userLicense!.licenseKey}"),
                        Text("Type: ${_userLicense!.type}"),
                        Text(
                            "Status: ${_userLicense!.isActive ? "✅ Active" : "❌ Expired"}"),
                          Text("Expires: ${_userLicense!.expiryDate}"),
                      ],
                    ),
                  ),
                )
              else
                const Text("⚠️ No license found for this user."),
            ],

            const SizedBox(height: 20),

            // ⏳ License Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _licenseTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _selectedType = val ?? _selectedType),
              decoration: const InputDecoration(
                labelText: "License Type",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 🚀 Generate button
         // 🚀 Generate / Update button
if (_userLicense == null)
  ElevatedButton.icon(
    onPressed: _isGenerating ? null : () => _generateLicense(),
    icon: _isGenerating
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.vpn_key),
    label: Text(_isGenerating ? "Generating..." : "Generate License"),
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  )
else
  ElevatedButton.icon(
    onPressed: _isGenerating ? null : () => _generateLicense(isUpdate: true),
    icon: _isGenerating
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.update),
    label: Text(_isGenerating ? "Updating..." : "Update License"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  ),


            const SizedBox(height: 30),

            // 🎉 Success card
            if (_generatedLicense != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text("✅ License Generated Successfully!",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Key: ${_generatedLicense!.licenseKey}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: _generatedLicense!.licenseKey));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("License Key copied")),
                              );
                            },
                          ),
                        ],
                      ),
                      Text("Type: ${_generatedLicense!.type}"),
                      Text("User: ${selectedUser?['name']}"),
                      Text("Email: ${selectedUser?['email']}"),
                      Text("Phone: ${selectedUser?['phone']}"),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}