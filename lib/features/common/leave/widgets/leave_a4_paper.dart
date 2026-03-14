import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/leave_request.dart';
import '../../../../data/services/school_info_service.dart';

class LeaveA4Paper extends StatelessWidget {
  final LeaveRequest leave;
  final bool showHeader;
  final bool showFooter;

  const LeaveA4Paper({
    super.key,
    required this.leave,
    this.showHeader = true,
    this.showFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Provider.of<SchoolInfoService>(context, listen: false).getSchoolInfo(),
      builder: (context, snapshot) {
        final schoolInfo = snapshot.data ?? {};
        final schoolName = schoolInfo['name'] ?? 'VEENA PUBLIC SCHOOL';
        final schoolAddress = schoolInfo['address'] ?? 'KHIDDI, RAJOUN, BANKA (BIHAR) -813107';
        final schoolContact = schoolInfo['contact'] ?? '+91- 9263101520';

        return AspectRatio(
          aspectRatio: 1 / 1.414, // A4 aspect ratio
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader) ...[
                    Center(
                      child: Column(
                        children: [
                          Text(
                            schoolName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            schoolAddress,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, color: Colors.black87),
                          ),
                          Text(
                            "Contact: $schoolContact",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, color: Colors.black),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: Colors.black,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "LEAVE APPLICATION",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // Date and Recipient
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("To,"),
                      Text("Date: ${DateFormat('dd MMM yyyy').format(leave.appliedOn)}"),
                    ],
                  ),
                  const Text("The Principal,"),
                  Text("$schoolName,"),
                  Text(schoolAddress.split(',').first + "."),
                  
                  const SizedBox(height: 30),
                  
                  Text(
                    "Subject: Application for Leave from ${DateFormat('dd MMM').format(leave.startDate)} to ${DateFormat('dd MMM yyyy').format(leave.endDate)}.",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 25),
                  
                  const Text("Respected Sir/Madam,"),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      leave.reason,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  const Text("Yours Obediently,"),
                  Text(
                    leave.userName.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("Role: ${leave.userRole.toUpperCase()}"),

                  const SizedBox(height: 40),

                  if (showFooter) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSignatureBox("Applicant's Sign", null),
                        _buildSignatureBox(
                          "Principal's Sign & Seal",
                          leave.signatureUrl,
                          stampUrl: leave.stampUrl,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignatureBox(String label, String? signUrl, {String? stampUrl}) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 60,
              width: 120,
              decoration: BoxDecoration(
                border: signUrl == null && stampUrl == null
                    ? const Border(bottom: BorderSide(color: Colors.black26))
                    : null,
              ),
              child: signUrl != null
                  ? Image.network(
                      signUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.draw, color: Colors.grey),
                    )
                  : null,
            ),
            if (stampUrl != null)
              Positioned(
                right: -10,
                bottom: -10,
                child: Opacity(
                  opacity: 0.8,
                  child: Image.network(
                    stampUrl,
                    width: 60,
                    height: 60,
                    errorBuilder: (_, __, ___) => const Icon(Icons.verified, color: Colors.blue, size: 40),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
