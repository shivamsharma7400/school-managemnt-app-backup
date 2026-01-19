import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/services/fee_service.dart';
import '../../data/models/fee_record.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/payment_service.dart';

class FeeStatusScreen extends StatefulWidget {
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
      appBar: AppBar(title: Text('My Fees')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.indigo.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
        ),
        child: FutureBuilder<List<FeeRecord>>(
          future: _getFees(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
                  SizedBox(height: 16),
                  Text("No fee records found.", style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                ],
              ));
            }

            final fees = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: fees.length,
              itemBuilder: (context, index) {
                final fee = fees[index];
                final isPaid = fee.status == 'Paid';
                
                return Container(
                  margin: EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                    ],
                    gradient: LinearGradient(
                      colors: isPaid 
                         ? [Colors.green.shade400, Colors.teal.shade600]
                         : [Colors.white, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  ),
                  child: Theme(
                    data: isPaid ? ThemeData.dark() : ThemeData.light(),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Fee Status", style: TextStyle(fontSize: 12, color: isPaid ? Colors.white70 : Colors.grey)),
                                  SizedBox(height: 4),
                                  Text(
                                    fee.month.toUpperCase(), 
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isPaid ? Colors.white : Colors.indigo),
                                  ),
                                ],
                              ),
                              _buildStatusChip(fee.status, isPaid),
                            ],
                          ),
                          SizedBox(height: 24),
                          Divider(color: isPaid ? Colors.white24 : Colors.grey[200]),
                          SizedBox(height: 16),
                          _buildRow("Total Bill", "₹${fee.totalAmount}", isPaid: isPaid),
                          _buildRow("Already Paid", "₹${fee.paidAmount}", isPaid: isPaid),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               Text("Amount Due", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isPaid ? Colors.white : Colors.black87)),
                               Text(
                                 "₹${fee.dueAmount}", 
                                 style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isPaid ? Colors.white : Colors.redAccent)
                               ),
                            ],
                          ),
                          
                          if (fee.status == 'Due' || fee.status == 'Partial') ...[
                            SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () async {
                                    // Fetch user details first
                                    final userDoc = await FirebaseFirestore.instance.collection('users').doc(fee.userId).get();
                                    final userData = userDoc.data();
                                    final String phone = userData?['phone'] ?? '';
                                    final String email = userData?['email'] ?? '';
                                    
                                   _paymentService.openCheckout(
                                     feeId: fee.id,
                                     amount: fee.dueAmount, // Pay the due amount
                                     name: fee.studentName, 
                                     contact: phone, 
                                     email: email, 
                                     onResult: (success, msg) {
                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                       if (success) setState(() {}); // Refresh UI
                                     }
                                   );
                                },
                                child: Text("PAY NOW", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color, required bool isPaid}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isPaid ? Colors.white70 : Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isPaid ? Colors.white : Colors.black87),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isPaid) {
    Color bg;
    Color fg;
    
    if (isPaid) {
       bg = Colors.white;
       fg = Colors.teal;
    } else {
      switch (status) {
        case 'Due': bg = Colors.red.shade50; fg = Colors.red; break;
        case 'Partial': bg = Colors.orange.shade50; fg = Colors.deepOrange; break;
        default: bg = Colors.grey.shade100; fg = Colors.black;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20)
      ),
      child: Text(
        status.toUpperCase(), 
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)
      ),
    );
  }
  Future<List<FeeRecord>> _getFees(BuildContext context) async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (user != null && authService.classId != null) {
      // 1. Get Class Fee
      final classDoc = await FirebaseFirestore.instance.collection('classes').doc(authService.classId).get();
      final double monthlyFee = (classDoc.data()?['monthlyFee'] ?? 0).toDouble();

      // 2. Get Extra Charges (Just for breakdown display if needed, but total due is authoritative from user doc)
      final extraChargesSnapshot = await FirebaseFirestore.instance
          .collection('extra_fees')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      double extraTotal = 0;
      for (var doc in extraChargesSnapshot.docs) {
        extraTotal += (doc.data()['amount'] ?? 0).toDouble();
      }

      // 3. Get Current Due from User Profile (Source of Truth)
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final double currentDue = (userDoc.data()?['currentDue'] ?? 0).toDouble();


      final currentMonth = DateFormat('MMM yyyy').format(DateTime.now());
      
      return [
        FeeRecord(
          id: 'dynamic_current',
          userId: user.uid,
          studentName: user.displayName ?? 'Student', 
          classId: authService.classId!, 
          month: currentMonth, 
          // We show 'Total Amount' as the sum of monthly liabilities, 
          // but 'Due Amount' is what management set.
          totalAmount: monthlyFee + extraTotal, 
          dueAmount: currentDue,
          paidAmount: 0 
        )
      ];
    }
    return [];
  }
}
