import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  }

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
    final expected = feeStats['expected'] ?? 0.0;
    final collected = feeStats['collected'] ?? 0.0;
    final pending = feeStats['pending'] ?? 0.0;
    
    // Avoid division by zero
    final safeExpected = expected == 0 ? 1.0 : expected; 

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to Fee Management
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FeeManagementScreen()), 
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Fee Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  if (expected == 0)
                    Text(
                      'No Data',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              SizedBox(height: 20),
              // Same chart content...
              SizedBox(
                height: 250, 
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: [
                          PieChartSectionData(
                            color: Colors.green,
                            value: collected,
                            // Hide title if value is small to avoid clutter
                            title: collected > 0 ? '${((collected / safeExpected) * 100).toStringAsFixed(1)}%' : '',
                            radius: 50,
                            titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.redAccent,
                            value: pending < 0 ? 0 : pending, // Handle overpayment edge case visually
                            title: pending > 0 ? '${((pending / safeExpected) * 100).toStringAsFixed(1)}%' : '',
                            radius: 50,
                            titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Expected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '₹${(expected / 1000).toStringAsFixed(1)}k',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIndicator(Colors.green, 'Collected', '₹${collected.toStringAsFixed(0)}'),
                  _buildIndicator(Colors.redAccent, 'Pending', '₹${pending.toStringAsFixed(0)}'),
                ],
              ),
            ],
          ),
        ),
      ),
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
