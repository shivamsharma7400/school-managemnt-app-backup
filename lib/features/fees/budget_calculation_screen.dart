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

      // 1. Fetch all relevant transactions for the month
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double incomeSum = 0;
      double expenseSum = 0;
      List<Map<String, dynamic>> incomeDetails = [];
      List<Map<String, dynamic>> expenseDetails = [];

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final type = data['type']?.toString() ?? '';
        final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;

        if (type == 'Fee Payment' || type == 'Manual Income') {
          incomeSum += amt;
          incomeDetails.add({...data, 'id': doc.id});
        } else if (type == 'Manual Expense') {
          expenseSum += amt;
          expenseDetails.add({...data, 'id': doc.id, 'staffName': 'Manual Entry'});
        }
      }

      // 2. Calculate Expenses from Salaries
      final staffSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['teacher', 'driver', 'staff'])
          .get();

      for (var staffDoc in staffSnapshot.docs) {
        // Fetch credits and filter date in memory to bypass composite index requirement
        final historySnapshot = await staffDoc.reference
            .collection('salary_history')
            .where('type', isEqualTo: 'credit')
            .get();

        for (var histDoc in historySnapshot.docs) {
          final hData = histDoc.data();
          final date = (hData['date'] as Timestamp?)?.toDate();
          if (date != null && date.isAfter(startOfMonth) && date.isBefore(endOfMonth)) {
            final amt = (hData['amount'] as num?)?.toDouble() ?? 0.0;
            expenseSum += amt;
            expenseDetails.add({
              ...hData,
              'id': histDoc.id,
              'staffName': staffDoc.data()['name'] ?? 'Staff',
            });
          }
        }
      }

      // Sort details by date descending
      incomeDetails.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));
      expenseDetails.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));

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
      title: 'School Budget Analysis',
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else ...[
                _buildSummaryGrid(),
                const SizedBox(height: 24),
                Expanded(child: _buildDetailsSection()),
              ],
            ],
          ),
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
              'Financial Center',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            Text(
              'Real-time budget tracking and records',
              style: GoogleFonts.inter(color: Colors.blueGrey.shade500, fontSize: 15),
            ),
          ],
        ),
        Row(
          children: [
            _buildEntryButton('Add Income', Icons.add_circle_outline, [const Color(0xFF0D9488), const Color(0xFF2DD4BF)], true),
            const SizedBox(width: 12),
            _buildEntryButton('Add Expense', Icons.remove_circle_outline, [const Color(0xFFE11D48), const Color(0xFFFB7185)], false),
            const SizedBox(width: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  _buildMonthNavButton(Icons.chevron_left, () {
                    setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1));
                    _calculateBudget();
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      DateFormat('MMMM yyyy').format(_selectedDate),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B)),
                    ),
                  ),
                  _buildMonthNavButton(Icons.chevron_right, () {
                    setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1));
                    _calculateBudget();
                  }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEntryButton(String label, IconData icon, List<Color> gradient, bool isIncome) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEntryDialog(isIncome),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEntryDialog(bool isIncome) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController remarkController = TextEditingController();
    DateTime entryDate = DateTime.now();
    bool useCurrentDate = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20)),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (isIncome ? Colors.teal : Colors.pink).withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isIncome ? Colors.teal : Colors.pink,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isIncome ? Icons.add_chart : Icons.receipt_long,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isIncome ? 'Record Income' : 'Record Expense',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                isIncome ? 'Add extra revenue to budget' : 'Add manual cost to budget',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.blueGrey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: Colors.blueGrey.shade300,
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDialogLabel('Amount'),
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: _buildInputDecoration('₹ Enter amount', Icons.currency_rupee),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildDialogLabel('Remarks'),
                        TextField(
                          controller: remarkController,
                          style: GoogleFonts.inter(fontSize: 16),
                          maxLines: 2,
                          decoration: _buildInputDecoration('Reason for transaction', Icons.notes),
                        ),
                        const SizedBox(height: 32),
                        
                        // Date Selector Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Transaction Date',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          DateFormat('EEEE, dd MMMM yyyy').format(entryDate),
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey.shade400),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    activeColor: Colors.indigo,
                                    value: useCurrentDate,
                                    onChanged: (val) {
                                      setDialogState(() => useCurrentDate = val);
                                      if (val) setDialogState(() => entryDate = DateTime.now());
                                    },
                                  ),
                                ],
                              ),
                              if (!useCurrentDate) ...[
                                const Divider(height: 24),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: entryDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setDialogState(() => entryDate = picked);
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_month, color: Colors.indigo, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Change Date',
                                        style: GoogleFonts.inter(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  side: BorderSide(color: Colors.blueGrey.shade100),
                                ),
                                child: Text('Discard', style: GoogleFonts.outfit(color: Colors.blueGrey.shade600, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isIncome 
                                      ? [const Color(0xFF0D9488), const Color(0xFF2DD4BF)] 
                                      : [const Color(0xFFE11D48), const Color(0xFFFB7185)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isIncome ? Colors.teal : Colors.pink).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final amount = double.tryParse(amountController.text) ?? 0;
                                    if (amount <= 0) return;

                                    await FirebaseFirestore.instance.collection('transactions').add({
                                      'amount': amount,
                                      'description': remarkController.text,
                                      'date': Timestamp.fromDate(entryDate),
                                      'type': isIncome ? 'Manual Income' : 'Manual Expense',
                                      'category': 'manual',
                                    });
                                    Navigator.pop(context);
                                    _calculateBudget();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: Text(
                                    'Save Transaction',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.blueGrey.shade300,
          letterSpacing: 1,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.blueGrey.shade300, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.indigo, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildMonthNavButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.indigo, size: 24),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    final balance = _totalIncome - _totalExpense;
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Revenue', '₹${_totalIncome.toStringAsFixed(0)}', Icons.arrow_downward, Colors.teal)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Total Expenses', '₹${_totalExpense.toStringAsFixed(0)}', Icons.arrow_upward, Colors.pink)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Net Profit', '₹${balance.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.indigo)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade50),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.blueGrey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Container(
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // Slate 100
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.indigo,
                  unselectedLabelColor: Colors.blueGrey.shade500,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Revenues (Fees)'),
                    Tab(text: 'Expenses (Salaries)'),
                  ],
                ),
              ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats, size: 48, color: Colors.blueGrey.shade200),
            const SizedBox(height: 16),
            Text("No transactions record found", style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final title = isIncome ? (item['studentName'] ?? 'Student') : (item['staffName'] ?? 'Staff');
        final sub = isIncome ? (item['description'] ?? 'Fee Payment') : (item['description'] ?? 'Salary Credit');
        final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
        final date = (item['date'] is Timestamp) ? (item['date'] as Timestamp).toDate() : DateTime.now();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueGrey.shade50),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isIncome ? Colors.teal : Colors.pink).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.keyboard_double_arrow_down : Icons.keyboard_double_arrow_up,
                  size: 20,
                  color: isIncome ? Colors.teal : Colors.pink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B))),
                    Text(sub, style: GoogleFonts.inter(fontSize: 13, color: Colors.blueGrey.shade500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isIncome ? '+' : '-'} ₹${amt.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18, 
                      color: isIncome ? Colors.teal : Colors.pink
                    ),
                  ),
                  Text(DateFormat('dd MMM, yyyy').format(date), style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey.shade400)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
