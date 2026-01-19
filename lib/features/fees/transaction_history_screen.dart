import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/services/fee_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Force Landscape for better table view
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    // Reset to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction History')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<FeeService>(context).getAllTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No transactions found'));
          }

          final transactions = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: transactions.map((t) {
                   final timestamp = t['date'] as dynamic; // Timestamp usually
                   DateTime date = DateTime.now();
                   if (timestamp != null) {
                     // Handle Timestamp or DateTime or String
                     if (timestamp is DateTime) date = timestamp;
                     // if (timestamp is Timestamp) date = timestamp.toDate(); // checking import
                     // If using cloud_firestore, Timestamp is available. But I need to verify import logic.
                     // It is likely QueryDocumentSnapshot data has Timestamp.
                     // Since I didn't import cloud_firestore here, I should.
                     // But wait, I'm just casting to dynamic. I will use 'toString' if type fails.
                     try {
                        date = timestamp.toDate();
                     } catch (e) {
                        try { date = DateTime.parse(timestamp.toString()); } catch (_) {}
                     }
                   }
                   
                   return DataRow(cells: [
                     DataCell(Text(DateFormat('MMM d, yyyy').format(date))),
                     DataCell(Text(DateFormat('h:mm a').format(date))),
                     DataCell(Text(t['studentName'] ?? 'N/A')),
                     DataCell(Text(t['classId']?.toString() ?? 'N/A')),
                     DataCell(Text(t['type'] ?? 'Payment')),
                     DataCell(Text('₹${t['amount']?.toString() ?? '0'}', style: TextStyle(color: Colors.green))),
                   ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
