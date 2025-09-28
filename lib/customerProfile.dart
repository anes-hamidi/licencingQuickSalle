import 'package:flutter/material.dart';
import 'package:myapp/license.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerProfileScreen extends StatelessWidget {
  final Map<String, dynamic> customer;
  final License? license;
  final bool isTrial;
  final Map<String, dynamic>? trialData; // 🔥


  const CustomerProfileScreen({
    super.key,
    required this.customer,
    this.license,
    this.isTrial = false,
    this.trialData,

  });

  @override
  Widget build(BuildContext context) {
    // 🟢 Determine license/trial status like dashboard
    String statusText = "No License";
    Color statusColor = Colors.red;
    IconData statusIcon = Icons.do_not_disturb_on;
    String? expiryDateText;
    double? progress; // 0.0 to 1.0
    String? progressLabel;

    if (license != null) {
      final totalDays = license!.expiryDate
          .difference(license!.createdAt)
          .inDays;
      final remainingDays = license!.expiryDate
          .difference(DateTime.now())
          .inDays;

      if (license!.isActive && remainingDays > 0) {
        statusText = "Active";
        statusColor = Colors.green;
        statusIcon = Icons.verified_user;
        expiryDateText = "${license!.expiryDate.toLocal()}".split(' ')[0];
        progress = remainingDays / totalDays;
        progressLabel = "$remainingDays days left";
      } else {
        statusText = "Expired";
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        expiryDateText = "${license!.expiryDate.toLocal()}".split(' ')[0];
        progress = 0;
        progressLabel = "Expired";
      }
    } else if (isTrial) {
  statusText = "Free Trial";
  statusColor = Colors.orange;
  statusIcon = Icons.hourglass_empty;

  final trialDays = trialData != null ? trialData!['trialDays'] : 0;

  final startDateStr = trialData != null ? trialData!['startDate'] : null;
  final endDateStr = trialData != null ? trialData!['endDate'] : null;

  final startDate = startDateStr != null
      ? DateTime.parse(startDateStr)
      : DateTime.now();
  final endDate = endDateStr != null
      ? DateTime.parse(endDateStr)
      : startDate.add(Duration(days: trialDays));

  final remainingDays = endDate.difference(DateTime.now()).inDays;

  progress = remainingDays > 0 ? remainingDays / trialDays : 0;
  progressLabel =
      remainingDays > 0 ? "$remainingDays days left" : "Expired";

  expiryDateText = "${endDate.toLocal()}".split(' ')[0];
}


    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          customer['name'] ?? "Customer Profile",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 👤 Customer info
            Text("👤 Customer Info",
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Name: ${customer['name']}"),
            Text("Email: ${customer['email']}"),
            Text("Phone: ${customer['phone']}"),
            const Divider(height: 30),

            // 📜 License info
            Text("📜 License Info",
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Icon(statusIcon, color: statusColor),
                        ),
                        const SizedBox(width: 12),
                        Text(statusText,
                            style: GoogleFonts.inter(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (license != null) ...[
                      Text("Key: ${license?.licenseKey}",
                          style: GoogleFonts.inter(fontSize: 13)),
                      Text("Type: ${license?.type}",
                          style: GoogleFonts.inter(fontSize: 13)),
                      Text("Status: ${license?.isActive == true ? "Active" : "Expired"}",
                          style: GoogleFonts.inter(fontSize: 13)),
                      if (expiryDateText != null)
                        Text("Expires: $expiryDateText",
                            style: GoogleFonts.inter(fontSize: 13)),
                    ] else if (isTrial) ...[
                      Text("Trial version in use",
                          style: GoogleFonts.inter(fontSize: 13)),
                      if (trialData != null) ...[
                        Text("Start Date: ${trialData?['startDate'] ?? 'N/A'}", style: GoogleFonts.inter(fontSize: 13)),
                        Text("End Date: ${trialData?['endDate'] ?? 'N/A'}", style: GoogleFonts.inter(fontSize: 13)),
                      ] ,
                  ] else ...[
                    Text("⚠️ No license assigned",
                        style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.red)),
                    ],

                    if (progress != null) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: statusColor,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 8),
                      Text(progressLabel ?? "",
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey[700])),
                    ],
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
