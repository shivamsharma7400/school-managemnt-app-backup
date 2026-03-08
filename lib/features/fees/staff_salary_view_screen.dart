import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import 'package:intl/intl.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/school_info_service.dart';
import '../../data/services/salary_pdf_service.dart';

class StaffSalaryViewScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    if (user == null) return Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Salary & Payments', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo.shade900,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return Center(child: Text("No data found."));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final salary = (data['monthlySalary'] as num?)?.toDouble() ?? 0.0;
          final due = (data['salaryDue'] as num?)?.toDouble() ?? 0.0;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildPremiumDashboard(salary, due),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverToBoxAdapter(
                  child: Text("Payment History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                ),
              ),
              _buildHistorySection(context, user.uid),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumDashboard(double salary, double due) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSummaryCard("Earnings", "₹$salary", Icons.trending_up, Colors.blue)),
              SizedBox(width: 16),
              Expanded(child: _buildSummaryCard("Pending Due", "₹$due", Icons.account_balance_wallet, Colors.red)),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo.shade800, Colors.indigo.shade600]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 8))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Received", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 4),
                    Text("₹${salary > due ? salary - due : 0.0}", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Icon(Icons.verified, color: Colors.white38, size: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          SizedBox(height: 4),
          Text(amount, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<UserService>(context).getStaffSalaryHistory(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(child: Text("No transaction history found.", style: TextStyle(color: Colors.grey))),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final tx = history[index];
              final isCredit = tx['type'] == 'credit';
              final DateTime? date = (tx['date'] as Timestamp?)?.toDate();
              final formattedDate = date != null ? "${date.day}/${date.month}/${date.year}" : "Recently";

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCredit ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCredit ? Icons.add_circle : Icons.payment,
                      color: isCredit ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(tx['description'] ?? (isCredit ? "Salary Credit" : "Payment Received"), style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$formattedDate • ${tx['method'] ?? 'System'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${isCredit ? '+' : '-'} ₹${tx['amount']}",
                        style: TextStyle(
                          color: isCredit ? Colors.green : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (!isCredit) ...[
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.download_for_offline, color: Colors.indigo.shade300),
                          onPressed: () => _downloadReceipt(context, tx),
                        )
                      ]
                    ],
                  ),
                ),
              );
            },
            childCount: history.length,
          ),
        );
      },
    );
  }

  void _downloadReceipt(BuildContext context, Map<String, dynamic> tx) async {
    try {
      final schoolInfo = await Provider.of<SchoolInfoService>(context, listen: false).getSchoolInfo();
      final authService = Provider.of<AuthService>(context, listen: false);
      final staffData = await Provider.of<UserService>(context, listen: false).getUserData(authService.user!.uid);

      if (schoolInfo == null || staffData == null) {
        throw Exception("Could not fetch required data for PDF");
      }

      // Fetch history for statement
      final historyStream = Provider.of<UserService>(context, listen: false).getStaffSalaryHistory(authService.user!.uid);
      final historyList = await historyStream.first;

      await SalaryPdfService.generateReceiptPdf(
        schoolInfo: schoolInfo,
        staffData: staffData,
        transaction: tx,
        history: historyList,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating receipt: $e")),
      );
    }
  }
}
