import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/services/fee_service.dart';
import '../../data/models/fee_record.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/payment_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/receipt_service.dart';

class FeeStatusScreen extends StatefulWidget {
  const FeeStatusScreen({super.key});

  @override
  _FeeStatusScreenState createState() => _FeeStatusScreenState();
}

class _FeeStatusScreenState extends State<FeeStatusScreen> {
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _paymentService.initialize();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fee Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<FeeRecord>>(
        future: _getFees(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final fees = snapshot.data!;
          // For simplicity, we assume there's one primary fee record for the student (based on currentDue)
          final primaryFee = fees.first;
          final bool isSettled = primaryFee.dueAmount == 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (isSettled) _buildSettledView(primaryFee) else _buildDueView(primaryFee),
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Payment History",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPaymentHistory(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No fee records found.", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSettledView(FeeRecord fee) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green.shade100, width: 4),
          ),
          child: const Icon(Icons.check_circle, size: 60, color: Colors.green),
        ),
        const SizedBox(height: 24),
        const Text(
          "Payment Fully Settled!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 8),
        Text(
          "You have no outstanding balance for ${fee.month}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDueView(FeeRecord fee) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PENDING BALANCE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(fee.month, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              _buildStatusChip('Due', false),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                const Text("Amount Due", style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  "₹${fee.dueAmount.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          _buildDetailRow("Monthly School Fee", "₹${fee.totalAmount.toStringAsFixed(0)}"),
          _buildDetailRow("Previously Paid", "₹${fee.paidAmount.toStringAsFixed(0)}"),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _handlePayment(fee),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("PAY NOW", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: valueColor ?? Colors.black87)),
      ],
    );
  }

  Widget _buildStatusChip(String status, bool isPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isPaid ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user == null) return const SizedBox();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<FeeService>(context).getUserTransactions(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No payment history found", style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          );
        }

        final transactions = snapshot.data!;
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final txn = transactions[index];
            final date = (txn['date'] as dynamic)?.toDate() ?? DateTime.now();
            final amount = (txn['amount'] as num?)?.toDouble() ?? 0.0;
            final type = txn['type'] ?? 'Payment';
            final isPayment = type == 'Fee Payment' || type == 'Monthly Fee';

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPayment ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPayment ? Icons.arrow_downward : Icons.priority_high,
                        color: isPayment ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy • h:mm a').format(date),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          if (txn['description'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                txn['description'],
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        Text(
                          '₹${amount.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isPayment ? Colors.green[700] : Colors.black87,
                          ),
                        ),
                        if (isPayment)
                          IconButton(
                            icon: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                            onPressed: () => ReceiptService().generateAndShowReceipt(context, txn),
                            tooltip: 'View Receipt',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handlePayment(FeeRecord fee) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(fee.userId).get();
    final userData = userDoc.data();
    final String phone = userData?['phone'] ?? '';
    final String email = userData?['email'] ?? '';

    _paymentService.openCheckout(
      feeId: fee.id,
      amount: fee.dueAmount,
      name: fee.studentName, 
      contact: phone, 
      email: email,
      classId: fee.classId,
      userId: fee.userId,
      schoolName: AppStrings.appName,
      onResult: (success, msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          if (success) setState(() {});
        }
      }
    );
  }

  Future<List<FeeRecord>> _getFees(BuildContext context) async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (user != null && authService.classId != null) {
      final classDoc = await FirebaseFirestore.instance.collection('classes').doc(authService.classId).get();
      final double monthlyFee = (classDoc.data()?['monthlyFee'] ?? 0).toDouble();

      final extraChargesSnapshot = await FirebaseFirestore.instance
          .collection('extra_fees')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      double extraTotal = 0;
      for (var doc in extraChargesSnapshot.docs) {
        extraTotal += (doc.data()['amount'] ?? 0).toDouble();
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final double currentDue = (userDoc.data()?['currentDue'] ?? 0).toDouble();

      final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
      
      return [
        FeeRecord(
          id: 'dynamic_current',
          userId: user.uid,
          studentName: user.displayName ?? 'Student', 
          classId: authService.classId!, 
          month: currentMonth, 
          totalAmount: monthlyFee + extraTotal, 
          dueAmount: currentDue,
          paidAmount: (monthlyFee + extraTotal) - currentDue
        )
      ];
    }
    return [];
  }
}
