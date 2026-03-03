import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/services/fee_service.dart';
import '../../data/services/user_service.dart';
import '../common/widgets/modern_layout.dart';

class BudgetCalculationScreen extends StatefulWidget {
  @override
  _BudgetCalculationScreenState createState() => _BudgetCalculationScreenState();
}

class _BudgetCalculationScreenState extends State<BudgetCalculationScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  double _totalIncome = 0;
  double _totalExpense = 0;
  
  List<Map<String, dynamic>> _incomeBreakdown = [];
  List<Map<String, dynamic>> _expenseBreakdown = [];

  @override
  void initState() {
    super.initState();
    _calculateBudget();
  }

  Future<void> _calculateBudget() async {
    setState(() => _isLoading = true);
    
    try {
      final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);

      // 1. Calculate Income (Fee Payments)
      final incomeSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('type', isEqualTo: 'Fee Payment')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double incomeSum = 0;
      List<Map<String, dynamic>> incomeDetails = [];
      for (var doc in incomeSnapshot.docs) {
        final data = doc.data();
        final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
        incomeSum += amt;
        incomeDetails.add(data);
      }

      // 2. Calculate Expenses (Salaries)
      // This is a bit complex as we need to check subcollections of all staff
      final staffSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['teacher', 'driver', 'staff'])
          .get();

      double expenseSum = 0;
      List<Map<String, dynamic>> expenseDetails = [];

      for (var staffDoc in staffSnapshot.docs) {
        final historySnapshot = await staffDoc.reference
            .collection('salary_history')
            .where('type', isEqualTo: 'credit')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .get();

        for (var histDoc in historySnapshot.docs) {
          final hData = histDoc.data();
          final amt = (hData['amount'] as num?)?.toDouble() ?? 0.0;
          expenseSum += amt;
          expenseDetails.add({
            ...hData,
            'staffName': staffDoc.data()['name'] ?? 'Staff',
          });
        }
      }

      setState(() {
        _totalIncome = incomeSum;
        _totalExpense = expenseSum;
        _incomeBreakdown = incomeDetails;
        _expenseBreakdown = expenseDetails;
      });
    } catch (e) {
      print("Budget Calculation Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernLayout(
      title: 'School Budget Calculation',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildSummaryCards()),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _buildDetailsList()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finance Dashboard',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Automatic calculation of income and expenditures',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1));
                  _calculateBudget();
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1));
                  _calculateBudget();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final balance = _totalIncome - _totalExpense;
    return Column(
      children: [
        _buildStatCard('Total Income', '₹${_totalIncome.toStringAsFixed(0)}', Icons.trending_up, Colors.green),
        const SizedBox(height: 16),
        _buildStatCard('Total Expense', '₹${_totalExpense.toStringAsFixed(0)}', Icons.trending_down, Colors.red),
        const SizedBox(height: 16),
        _buildStatCard('Net Balance', '₹${balance.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.blue),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.indigo.shade100),
          ),
          child: Column(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.indigo, size: 32),
              const SizedBox(height: 12),
              Text(
                "AI Budget Insight",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 8),
              Text(
                "Income is ${balance >= 0 ? 'exceeding' : 'below'} expenses by ₹${balance.abs().toStringAsFixed(0)} this month.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.indigo.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
              Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              tabs: const [
                Tab(text: 'Incomes (Fees)'),
                Tab(text: 'Expenses (Salaries)'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(_incomeBreakdown, true),
                  _buildList(_expenseBreakdown, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool isIncome) {
    if (items.isEmpty) {
      return Center(
        child: Text("No data for this month", style: GoogleFonts.inter(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final item = items[index];
        final title = isIncome ? (item['studentName'] ?? 'Student') : (item['staffName'] ?? 'Staff');
        final sub = isIncome ? (item['description'] ?? 'Fee Payment') : (item['description'] ?? 'Salary Credit');
        final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
        final date = (item['date'] as Timestamp?)?.toDate() ?? DateTime.now();

        return Row(
          children: [
            CircleAvatar(
              backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  Text(sub, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${amt.toStringAsFixed(0)}",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red),
                ),
                Text(DateFormat('dd MMM').format(date), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        );
      },
    );
  }
}
