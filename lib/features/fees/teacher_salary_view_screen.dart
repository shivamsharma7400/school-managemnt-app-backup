import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';

class TeacherSalaryViewScreen extends StatelessWidget { // Standardize naming
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    if (user == null) return Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      appBar: AppBar(title: Text('My Salary & Payments')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(), // Stream specific doc
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("No data found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final salary = (data['monthlySalary'] as num?)?.toDouble() ?? 0.0;
          final due = (data['salaryDue'] as num?)?.toDouble() ?? 0.0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoCard(context, "Monthly Salary", salary, Colors.blue),
                SizedBox(height: 16),
                _buildInfoCard(context, "Total Due (Pending Payment)", due, Colors.green),
                Spacer(),
                Text(
                  "Note: Contact management for payment details.",
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, double amount, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.monetization_on, size: 48, color: color),
            SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 8),
            Text(
              "₹ ${amount.toStringAsFixed(0)}", 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)
            ),
          ],
        ),
      ),
    );
  }
}
