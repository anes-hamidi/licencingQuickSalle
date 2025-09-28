import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/customerProfile.dart';
import 'package:myapp/license.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum SortBy { newest, expiryDate }
enum FilterBy { all, withLicense, withoutLicense, freeTrial }

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _customers = [];
  Map<dynamic, License> _licenses = {};
  SortBy _sortBy = SortBy.newest;
  FilterBy _filter = FilterBy.all;
  String _searchQuery = '';

  int _withLicense = 0;
  int _withoutLicense = 0;
  int _withFreeTrial = 0;

  Set<String> _freeTrialUserIds = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

    @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

Future<void> _fetchData() async {
  setState(() => _isLoading = true);
  try {
    final customersFuture = FirebaseFirestore.instance.collection('customers').get();
    final licensesFuture = FirebaseFirestore.instance.collection('licenses').get();
    final trialsFuture = FirebaseFirestore.instance
        .collection("licenses")
        .doc("free_trial")
        .collection("keys")
        .get();

    final results = await Future.wait([customersFuture, licensesFuture, trialsFuture]);

    final customersSnapshot = results[0] ;
    final licensesSnapshot = results[1] ;
    final trialSnapshot = results[2] ;

    // ✅ FIX: use doc.id, not doc['assignedTo']
    final licenses = {
      for (var doc in licensesSnapshot.docs)
        doc.id: License.fromFirestore(doc),
    };

    // ✅ FIX: use uid if exists, else fallback to doc.id
    final trialUserIds = trialSnapshot.docs
        .map((d) {
          final data = d.data();
          return data['uid'] ?? d.id;
        })
        .cast<String>()
        .toSet();

    List<Map<String, dynamic>> enrichedCustomers = [];
    int withLicense = 0, withoutLicense = 0, withFreeTrial = 0;
for (var doc in customersSnapshot.docs) {
  final data = doc.data();
  final id = doc.id;

  final license = licenses[id];
  final hasTrial = trialUserIds.contains(id);

  String statusText = "No License";
  Color statusColor = Colors.red;
  IconData statusIcon = Icons.do_not_disturb_on;
  String? formattedExpiryDate;

   if (license != null) {
      // License
       final daysLeft = license.expiryDate.difference(DateTime.now()).inDays;
        if (license.isActive && daysLeft > 0) {
          statusText = "Active";
          statusColor = Colors.green;
          statusIcon = Icons.verified_user;
        } else {
          statusText = "Expired";
          statusColor = Colors.red;
          statusIcon = Icons.error_outline;
        }
      withLicense++;
    }
    else  if (hasTrial) {
    statusText = "Free Trial";
    statusColor = Colors.orange;
    statusIcon = Icons.hourglass_empty;
    withFreeTrial++;
  }
   else {
    // No License
    statusText = "No License";
    statusColor = Colors.red;
    statusIcon = Icons.do_not_disturb_on;
    withoutLicense++;
  }


  enrichedCustomers.add({
    'id': id,
    ...data,
    'license': license,
    'hasTrial': hasTrial,
    'statusText': statusText,
    'statusColor': statusColor,
    'statusIcon': statusIcon,
    'formattedExpiryDate': formattedExpiryDate,
  });
}



    setState(() {
      _customers = enrichedCustomers;
      _licenses = licenses;
      _withLicense = withLicense;
      _withoutLicense = withoutLicense;
      _withFreeTrial = withFreeTrial;
      _freeTrialUserIds = trialUserIds;
      _isLoading = false;
    });
  } catch (e, st) {
    debugPrint("❌ Error fetching data: $e\n$st");
    setState(() => _isLoading = false);
  }
}


  void _sortCustomers() {
    List<Map<String, dynamic>> sortedCustomers = List.from(_customers);
    if (_sortBy == SortBy.newest) {
      sortedCustomers.sort((a, b) {
        final aLicense = _licenses[a['id']];
        final bLicense = _licenses[b['id']];
        if (aLicense == null && bLicense == null) return 0;
        if (aLicense == null) return 1;
        if (bLicense == null) return -1;
        return bLicense.createdAt.compareTo(aLicense.createdAt);
      });
    } else if (_sortBy == SortBy.expiryDate) {
      sortedCustomers.sort((a, b) {
        final aLicense = _licenses[a['id']];
        final bLicense = _licenses[b['id']];
        if (aLicense == null && bLicense == null) return 0;
        if (aLicense == null) return 1;
        if (bLicense == null) return -1;
        return aLicense.expiryDate.compareTo(bLicense.expiryDate);
      });
    }
    setState(() {
      _customers = sortedCustomers;
    });
  }

  Widget _buildStatCard(
    String label,
    int count,
    Color color,
    FilterBy filter,
  ) {
    final isSelected = _filter == filter;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _filter = (isSelected ? FilterBy.all : filter);
          });
        },
        child: Card(
          elevation: isSelected ? 4 : 2,
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: isSelected
                ? BorderSide(color: color, width: 1.5)
                : BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilterAndSearch() {
    List<Map<String, dynamic>> filteredCustomers = [];

    if (_filter == FilterBy.all) {
      filteredCustomers = _customers;
    } else {
      filteredCustomers = _customers.where((customer) {
        final id = customer['id'];
        final hasLicense = _licenses.containsKey(id);
        final hasTrial = _freeTrialUserIds.contains(id);

        if (_filter == FilterBy.withLicense) return hasLicense ;
        if (_filter == FilterBy.withoutLicense) return !hasLicense && !hasTrial;
        if (_filter == FilterBy.freeTrial) return hasTrial && !hasLicense;

        return true;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredCustomers = filteredCustomers.where((customer) {
        final name = customer['name'] as String;
        final email = customer['email'] as String;
        return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            email.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filteredCustomers;
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _applyFilterAndSearch();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Customer Dashboard", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          PopupMenuButton<SortBy>(
            onSelected: (sort) {
              setState(() => _sortBy = sort);
              _sortCustomers();
            },
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortBy.newest,
                child: Text("Sort by Newest"),
              ),
              const PopupMenuItem(
                value: SortBy.expiryDate,
                child: Text("Sort by Expiry Date"),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        _buildStatCard("License", _withLicense,
                            Colors.green,  FilterBy.withLicense),
                        const SizedBox(width: 12),
                        _buildStatCard("NoLicense", _withoutLicense,
                            Colors.red,  FilterBy.withoutLicense),
                        const SizedBox(width: 12),
                        _buildStatCard("Trial", _withFreeTrial,
                            Colors.orange,  FilterBy.freeTrial),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No Customers Found',
                                  style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              final license = _licenses[customer['id']];
                              final isTrial = _freeTrialUserIds.contains(customer['id']);

                              String statusText = "No License";
                              Color statusColor = Colors.red;
                              IconData statusIcon = Icons.do_not_disturb_on;

                              if (license != null) {
                                final daysLeft = license.expiryDate
                                    .difference(DateTime.now())
                                    .inDays;
                                 if (daysLeft <= 0 || !license.isActive) {
                                    statusText = "Expired";
                                    statusColor = Colors.red;
                                    statusIcon = Icons.error_outline;
                                  }
                                  else {
                                      statusText = "Active";
                                      statusColor = Colors.green;
                                      statusIcon = Icons.verified_user;
                                  }
                                }
                               else if (isTrial) {
                                statusText = "Free Trial";
                                statusColor = Colors.orange;
                                statusIcon = Icons.hourglass_empty;
                              }
                               else {
                                statusText = "No License";
                                statusColor = Colors.red;
                                statusIcon = Icons.do_not_disturb_on;
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                elevation: 2,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CustomerProfileScreen(
                                          customer: customer,
                                          license: license,
                                          isTrial: isTrial,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(15),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: statusColor.withOpacity(0.1),
                                          child: Icon(statusIcon, color: statusColor),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                customer['name'],
                                                style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                customer['email'],
                                                style: GoogleFonts.inter(
                                                    color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                             Chip(
                                              label: Text(
                                                statusText,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12
                                                ),
                                              ),
                                              backgroundColor: statusColor,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
