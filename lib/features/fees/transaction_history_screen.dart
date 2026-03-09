import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/fee_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/receipt_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Provider.of<FeeService>(context).getAllTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final transactions = snapshot.data!
                    .where((t) => 
                        t['type'] != 'Fine' &&
                        t['type'] != 'Monthly Fee' &&
                        (t['studentName'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                if (transactions.isEmpty) {
                  return _buildEmptyState(message: "No transactions match your search.");
                }

                // Group by month
                final grouped = _groupTransactions(transactions);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return _buildDesktopTable(grouped);
                    } else {
                      return _buildMobileList(grouped);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: "Search by student name...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              }) 
            : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState({String message = "No transactions found"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactions(List<Map<String, dynamic>> data) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var t in data) {
      final date = _parseDate(t['date']);
      final key = DateFormat('MMMM yyyy').format(date);
      if (grouped[key] == null) grouped[key] = [];
      grouped[key]!.add(t);
    }
    return grouped;
  }

  DateTime _parseDate(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    try {
      return DateTime.parse(timestamp.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  Widget _buildMobileList(Map<String, List<Map<String, dynamic>>> grouped) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        String monthKey = grouped.keys.elementAt(index);
        List<Map<String, dynamic>> items = grouped[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthHeader(monthKey),
            ...items.map((t) => _buildTransactionCard(t)),
          ],
        );
      },
    );
  }

  Widget _buildMonthHeader(String month) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
      ),
      child: Text(
        month.toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> t) {
    final date = _parseDate(t['date']);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: const Icon(Icons.payment, color: Colors.green),
        ),
        title: Text(
          t['studentName'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Class: ${t['classId'] ?? 'N/A'} • ${DateFormat('h:mm a').format(date)}"),
            Text(DateFormat('MMM d, yyyy').format(date), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "₹${t['amount'] ?? '0'}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.receipt_long, color: Colors.indigo, size: 22),
              onPressed: () => ReceiptService().generateAndShowReceipt(context, t),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(Map<String, List<Map<String, dynamic>>> grouped) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.keys.map((month) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  month,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                    columns: const [
                      DataColumn(label: Text('Date & Time')),
                      DataColumn(label: Text('Student Name')),
                      DataColumn(label: Text('Class')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Receipt')),
                    ],
                    rows: grouped[month]!.map((t) {
                      final date = _parseDate(t['date']);
                      return DataRow(cells: [
                        DataCell(Text("${DateFormat('MMM d').format(date)}, ${DateFormat('h:mm a').format(date)}")),
                        DataCell(Text(t['studentName'] ?? 'N/A')),
                        DataCell(Text(t['classId']?.toString() ?? 'N/A')),
                        DataCell(Text(t['type'] ?? 'Payment')),
                        DataCell(
                          Text(
                            '₹${t['amount'] ?? '0'}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.receipt_long, color: Colors.indigo),
                            onPressed: () => ReceiptService().generateAndShowReceipt(context, t),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
