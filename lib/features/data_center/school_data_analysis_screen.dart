import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/fee_service.dart';
import '../../data/services/user_service.dart';
import '../../data/models/fee_record.dart';
import '../fees/fee_management_screen.dart';
import '../../data/services/school_info_service.dart';

class SchoolDataAnalysisScreen extends StatefulWidget {
  @override
  _SchoolDataAnalysisScreenState createState() => _SchoolDataAnalysisScreenState();
}

class _SchoolDataAnalysisScreenState extends State<SchoolDataAnalysisScreen> {
  String selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  bool _isLoading = false;
  Map<String, double> feeStats = {
    'expected': 0,
    'collected': 0,
    'pending': 0,
    'totalGlobalDue': 0,
  };
  List<double> _monthlyNetProfits = [];
  List<double> _monthlyIncomes = [];
  List<double> _monthlyExpenses = [];
  List<String> _monthsLabels = [];

  String _currentSession = '';

  @override
  void initState() {
    super.initState();
    _currentSession = _calculateCurrentSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  String _calculateCurrentSession() {
    final now = DateTime.now();
    final year = now.month < 4 ? now.year - 1 : now.year;
    final nextYearShort = (year + 1).toString().substring(2);
    return '$year-$nextYearShort';
  }

  Future<void> _loadData() async {
    await _loadFeeData();
    await _loadSessionData();
    await _loadMonthlyRevenueTrend();
  }

  Future<void> _loadMonthlyRevenueTrend() async {
    setState(() => _isLoading = true);
    try {
      DateTime now = DateTime.now();
      DateTime rangeStart = DateTime(now.year, now.month - 5, 1);
      DateTime rangeEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // 1. Fetch all transactions for the 6-month range in ONE query
      final transactionsFuture = FirebaseFirestore.instance
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd))
          .get();

      // 2. Fetch staff list ONCE
      final staffQueryFuture = FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['teacher', 'driver', 'staff'])
          .get();

      final results = await Future.wait([transactionsFuture, staffQueryFuture]);
      final transactionsSnapshot = results[0] as QuerySnapshot;
      final staffSnapshot = results[1] as QuerySnapshot;

      // 3. Fetch salary histories in PARALLEL for all staff
      final salaryFutures = staffSnapshot.docs.map((staffDoc) => staffDoc.reference
          .collection('salary_history')
          .where('type', isEqualTo: 'credit')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd))
          .get());
      
      final salarySnapshots = await Future.wait(salaryFutures);

      // 4. Process all data and group by month in-memory
      List<double> profits = List.filled(6, 0.0);
      List<double> incomes = List.filled(6, 0.0);
      List<double> expenses = List.filled(6, 0.0);
      List<String> labels = List.filled(6, '');

      for (int i = 0; i < 6; i++) {
        DateTime monthDate = DateTime(now.year, now.month - (5 - i), 1);
        labels[i] = DateFormat('MMM').format(monthDate);
        
        final mStart = DateTime(monthDate.year, monthDate.month, 1);
        final mEnd = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);

        // Filter transactions for this month from the big snapshot
        for (var doc in transactionsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp).toDate();
          if (date.isAfter(mStart.subtract(const Duration(seconds: 1))) && date.isBefore(mEnd.add(const Duration(seconds: 1)))) {
             final type = data['type']?.toString() ?? '';
             final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
             if (type == 'Fee Payment' || type == 'Manual Income') {
               incomes[i] += amt;
             } else if (type == 'Manual Expense') {
               expenses[i] += amt;
             }
          }
        }

        // Add salaries for this month from parallel snapshots
        for (var sSnap in salarySnapshots) {
          for (var histDoc in sSnap.docs) {
            final hData = histDoc.data();
            final date = (hData['date'] as Timestamp).toDate();
             if (date.isAfter(mStart.subtract(const Duration(seconds: 1))) && date.isBefore(mEnd.add(const Duration(seconds: 1)))) {
               expenses[i] += (hData['amount'] as num?)?.toDouble() ?? 0.0;
             }
          }
        }
        profits[i] = incomes[i] - expenses[i];
      }

      setState(() {
        _monthlyNetProfits = profits;
        _monthlyIncomes = incomes;
        _monthlyExpenses = expenses;
        _monthsLabels = labels;
      });
    } catch (e) {
      print('Error loading trend data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _getMaxY() {
    if (_monthlyIncomes.isEmpty) return 10000;
    double maxIncome = _monthlyIncomes.reduce((a, b) => a > b ? a : b);
    double maxExpense = _monthlyExpenses.reduce((a, b) => a > b ? a : b);
    double max = maxIncome > maxExpense ? maxIncome : maxExpense;
    return max > 0 ? max * 1.2 : 10000;
  }

  double _getMinY() => 0; // Starting from 0 for Income vs Expense comparison

  Future<void> _loadSessionData() async {
     // You need to import SchoolInfoService
     // import '../../data/services/school_info_service.dart';
     try {
       final schoolService = Provider.of<SchoolInfoService>(context, listen: false);
       final data = await schoolService.getSchoolInfo();
       if (data != null && data['currentSession'] != null) {
         setState(() {
           _currentSession = data['currentSession'];
         });
       }
     } catch (e) {
       print('Error loading session: $e');
     }
  }

  Future<void> _startNextSession() async {
    // Logic to increment session
    // e.g. 2025-26 -> 2026-27
    try {
      final parts = _currentSession.split('-');
      if (parts.length == 2) {
        final startYear = int.parse(parts[0]);
        final nextSession = '${startYear + 1}-${(startYear + 2).toString().substring(2)}';
        
        // Promote all students first
        final userService = Provider.of<UserService>(context, listen: false);
        await userService.promoteAllStudents(_currentSession);

        await Provider.of<SchoolInfoService>(context, listen: false).updateSchoolInfo({
          'currentSession': nextSession
        });

        setState(() {
          _currentSession = nextSession;
        });
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New Session $nextSession Started!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error starting next session: $e');
    }
  }

  void _showSessionManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
             gradient: LinearGradient(
               colors: [Colors.indigo.shade900, Colors.deepPurple.shade900],
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
             ),
             borderRadius: BorderRadius.circular(20),
             boxShadow: [
               BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
             ],
             border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month, size: 50, color: Colors.white70),
              SizedBox(height: 16),
              Text(
                'Current Session',
                style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1.2),
              ),
              SizedBox(height: 8),
              Text(
                _currentSession,
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))]
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startNextSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo.shade900,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Start Next Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  // ... (existing code)

  Future<void> _loadFeeData() async {
    setState(() => _isLoading = true);
    try {
      final feeService = Provider.of<FeeService>(context, listen: false);
      
      // Auto-select latest processed month
      final processedMonths = await feeService.getProcessedFeeMonths(_currentSession);
      if (processedMonths.isNotEmpty) {
         selectedMonth = processedMonths.last;
      }

      final stats = await feeService.getMonthFeeStats(selectedMonth);
      
      setState(() {
        feeStats = stats;
      });
    } catch (e) {
      print('Error loading fee data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ... (build method)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('School Data Analysis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade900, Colors.deepPurple.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: InkWell(
              onTap: _showSessionManagementDialog,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.indigo.shade900),
                      const SizedBox(width: 6),
                      Text(
                        _currentSession.isEmpty ? 'Session' : _currentSession,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFeeData,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildFeeStatusCard(),
                const SizedBox(height: 24),
                _buildPreviousSection(),
              ],
            ),
          ),
    );
  }

  // ... (existing methods)

  Widget _buildPreviousSection() {
    final totalDue = feeStats['totalGlobalDue'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previous',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildInfoCard('Total Due', '₹${(totalDue/1000).toStringAsFixed(1)}k', Colors.red)),
            const SizedBox(width: 16),
            Expanded(child: _buildInfoCard('Fine Collected', 'Coming Soon', Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.attach_money, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Month Analysis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        // Simple Dropdown for Month - For now just displaying current month
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                selectedMonth,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeStatusCard() {
    if (_monthlyNetProfits.isEmpty) return const Center(child: CircularProgressIndicator());

    final latestIncome = _monthlyIncomes.last;
    final latestExpense = _monthlyExpenses.last;
    final latestNet = _monthlyNetProfits.last;
    final isLoss = latestNet < 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Analytics',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cash flow & net balance overview',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.analytics_rounded, color: Colors.indigo.shade700, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Summary Stats Section
            Row(
              children: [
                _buildSummaryStatCard(
                  'Income',
                  '₹${(latestIncome / 1000).toStringAsFixed(1)}k',
                  const Color(0xFF10B981),
                  Icons.arrow_upward_rounded,
                ),
                const SizedBox(width: 16),
                _buildSummaryStatCard(
                  'Expense',
                  '₹${(latestExpense / 1000).toStringAsFixed(1)}k',
                  const Color(0xFFEF4444),
                  Icons.arrow_downward_rounded,
                ),
                const SizedBox(width: 16),
                _buildSummaryStatCard(
                  isLoss ? 'Net Loss' : 'Net Profit',
                  '₹${(latestNet.abs() / 1000).toStringAsFixed(1)}k',
                  isLoss ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                  isLoss ? Icons.warning_rounded : Icons.account_balance_wallet_rounded,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Chart Section
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: _getMaxY(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      tooltipMargin: 10,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final income = _monthlyIncomes[groupIndex];
                        final expense = _monthlyExpenses[groupIndex];
                        final net = _monthlyNetProfits[groupIndex];
                        final isLoss = net < 0;

                        return BarTooltipItem(
                          '${_monthsLabels[groupIndex]}\n',
                          GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: 'Income: ',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                            TextSpan(
                              text: '₹${income.toStringAsFixed(0)}\n',
                              style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            TextSpan(
                              text: 'Expense: ',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                            TextSpan(
                              text: '₹${expense.toStringAsFixed(0)}\n',
                              style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const TextSpan(text: '----------------\n'),
                            TextSpan(
                              text: isLoss ? 'Net Loss: ' : 'Net Profit: ',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            TextSpan(
                              text: '₹${net.abs().toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: isLoss ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < _monthsLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                _monthsLabels[index],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey.shade300,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _monthlyIncomes.asMap().entries.map((entry) {
                    final index = entry.key;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        // Income Bar
                        BarChartRodData(
                          toY: _monthlyIncomes[index],
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF34D399)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 12,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        // Expense Bar
                        BarChartRodData(
                          toY: _monthlyExpenses[index],
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 12,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Legend Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Income', const Color(0xFF10B981)),
                const SizedBox(width: 24),
                _buildLegendItem('Expense', const Color(0xFFEF4444)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(Color color, String text, String value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
             Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getCurrentSession() {
    final now = DateTime.now();
    // Assuming session starts in April
    final year = now.month < 4 ? now.year - 1 : now.year;
    final nextYearShort = (year + 1).toString().substring(2);
    return '$year-$nextYearShort';
  }
}
