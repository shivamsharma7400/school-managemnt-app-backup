import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/class_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/fee_service.dart';
import '../../data/models/class_model.dart';
import 'package:intl/intl.dart';
import '../../data/services/school_info_service.dart';
import '../../data/models/bus_destination.dart';
import '../../data/services/bus_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/utils/migration_util.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

class FeeManagementScreen extends StatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<ClassModel> _classes = [];
  String? _selectedClassId;
  bool _isAutoPilotEnabled = false;
  int _autoPilotDay = 1;
  bool _isFineAutoPilotEnabled = false;
  int _fineAutoPilotDay = 10;
  double _fineAmount = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadAutoPilotSettings();
  }

  Future<void> _loadAutoPilotSettings() async {
    final schoolService = Provider.of<SchoolInfoService>(context, listen: false);
    final data = await schoolService.getSchoolInfo();
    if (data != null && mounted) {
      setState(() {
        _isAutoPilotEnabled = data['feeAutoPilotEnabled'] == true;
        _autoPilotDay = (data['feeAutoPilotDay'] as num?)?.toInt() ?? 1;
        _isFineAutoPilotEnabled = data['fineAutoPilotEnabled'] == true;
        _fineAutoPilotDay = (data['fineAutoPilotDay'] as num?)?.toInt() ?? 10;
        _fineAmount = (data['fineAutoPilotAmount'] as num?)?.toDouble() ?? 0.0;
      });
      if (_isAutoPilotEnabled || _isFineAutoPilotEnabled) {
        _checkAndAutoProcessFees();
      }
    }
  }

  Future<void> _checkAndAutoProcessFees() async {
    final now = DateTime.now();
    // Fetch current session
    String currentSession = '2025-26';
    try {
      final schoolService = Provider.of<SchoolInfoService>(context, listen: false);
      final data = await schoolService.getSchoolInfo();
      if (data != null && data['currentSession'] != null) {
        currentSession = data['currentSession'];
      }
    } catch (e) {}

    final feeService = Provider.of<FeeService>(context, listen: false);
    final currentMonthName = DateFormat('MMMM').format(now);
    final year = _calculateYearForMonth(currentMonthName, currentSession);
    final fullMonthName = "$currentMonthName $year";

    // 1. Check Fee Auto Pilot
    if (_isAutoPilotEnabled == true && now.day >= _autoPilotDay) {
      try {
        final processedMonths = await feeService.getProcessedFeeMonths(currentSession);
        if (!processedMonths.contains(fullMonthName) && _isProcessing != true) {
          setState(() => _isProcessing = true);
          await _processFees(context, fullMonthName, currentSession);
          setState(() => _isProcessing = false);
        }
      } catch (e) {
        print('Error in fee auto process check: $e');
      }
    }

    // 2. Check Fine Auto Pilot
    if (_isFineAutoPilotEnabled == true && now.day >= _fineAutoPilotDay && _fineAmount > 0) {
      try {
        final processedFineMonths = await feeService.getProcessedFineMonths(currentSession);
        if (!processedFineMonths.contains(fullMonthName) && _isProcessing != true) {
          setState(() => _isProcessing = true);
          await _applyAutoFines(context, fullMonthName, currentSession);
          setState(() => _isProcessing = false);
        }
      } catch (e) {
        print('Error in fine auto process check: $e');
      }
    }
  }

  Future<void> _applyAutoFines(BuildContext context, String monthName, String session) async {
    try {
      await Provider.of<FeeService>(context, listen: false).applyAutoFinesToAllDueStudents(
        amount: _fineAmount,
        monthName: monthName,
        session: session,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange[800],
            content: Text('Successfully applied late fines for $monthName'),
          ),
        );
      }
    } catch (e) {
      print('Error applying auto fines: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClassModel>>(
      stream: Provider.of<ClassService>(context).getAllClasses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        _classes = snapshot.data!;
        _classes.sort((a, b) {
          final indexA = AppConstants.schoolClasses.indexOf(a.name);
          final indexB = AppConstants.schoolClasses.indexOf(b.name);
          if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
          return a.name.compareTo(b.name);
        });

        if (_tabController == null || _tabController!.length != _classes.length) {
          _tabController = TabController(length: _classes.length, vsync: this);
          _tabController!.addListener(() {
            setState(() {
              _selectedClassId = _classes[_tabController!.index].id;
            });
          });
          if (_classes.isNotEmpty && _selectedClassId == null) {
            _selectedClassId = _classes[0].id;
          }
        }

        final currentClass = _selectedClassId != null 
            ? _classes.firstWhere((c) => c.id == _selectedClassId)
            : null;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(context, currentClass),
            ],
            body: _selectedClassId == null
                ? const Center(child: Text("No classes found", style: TextStyle(fontSize: 18, color: Colors.grey)))
                : Stack(
                    children: [
                      Column(
                        children: [
                          _buildClassTabs(),
                          Expanded(
                            child: _ResponsiveStudentView(
                              classId: _selectedClassId!,
                              classModel: currentClass!,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildBottomTools(context, currentClass),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ClassModel? classModel) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.indigo[900],
      elevation: 0,
      actions: [
        if (classModel != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showProcessMonthDialog(context),
              icon: const Icon(Icons.history_edu, color: Colors.white),
              tooltip: 'Process Monthly Fees',
            ),
          ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => _showAutoPilotSettings(context),
            icon: Icon(
              _isAutoPilotEnabled == true ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              color: _isAutoPilotEnabled == true ? Colors.amber : Colors.white60,
            ),
            tooltip: 'Auto Pilot Settings',
          ),
        ),
        if (classModel != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _generateDueListPDF(context, classModel),
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
              label: const Text('Due List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo[900]!, Colors.blue[800]!, Colors.blue[600]!],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fee Management',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classModel != null ? '${classModel.name} Monthly Summary' : 'Quick Statistics',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Spacer(),
                  _buildSummaryCards(classModel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ClassModel? classModel) {
    if (classModel == null) return const SizedBox.shrink();
    
    // We'll use StreamBuilders to get real-time stats for the class and bus destinations
    return StreamBuilder<List<BusDestination>>(
      stream: Provider.of<BusService>(context, listen: false).getDestinations(),
      builder: (context, destSnapshot) {
        final destinations = destSnapshot.data ?? [];
        
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Provider.of<UserService>(context, listen: false).getStudentsByClass(classModel.id),
          builder: (context, snapshot) {
            double totalExpected = 0;
            double totalDue = 0;
            double totalMonthlyPending = 0;

            if (snapshot.hasData) {
              for (var s in snapshot.data!) {
                // Calculate individual expected fee
                final feeConfig = s['feeConfig'] as Map<String, dynamic>? ?? {};
                double studentExpected = 0.0;
                
                if (feeConfig['Coaching Fee'] != false) studentExpected += classModel.coachingFee;
                if (feeConfig['Bus Fee'] != false) {
                  final busStopId = s['busStopId']?.toString();
                  final stop = destinations.firstWhere(
                    (d) => d.id == busStopId,
                    orElse: () => BusDestination(id: '', name: '', lat: 0, lng: 0, fee: classModel.busFee),
                  );
                  studentExpected += stop.fee;
                }
                if (feeConfig['Hostel Fee'] != false) studentExpected += classModel.hostelFee;
                
                classModel.otherFees.forEach((key, value) {
                  if (feeConfig[key] != false) studentExpected += value;
                });

                totalExpected += studentExpected;
                
                final double currentDue = (s['currentDue'] as num?)?.toDouble() ?? 0.0;
                totalDue += currentDue;

                // Calculate Monthly Pending for Collected Calculation
                final double monthlyPending = (currentDue < studentExpected) ? currentDue : studentExpected;
                totalMonthlyPending += monthlyPending;
              }
            }

            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _summaryCard('Expected', '₹${totalExpected.toInt()}', Icons.trending_up, Colors.blue),
                    const SizedBox(width: 12),
                    _summaryCard('Pending', '₹${totalDue.toInt()}', Icons.error_outline, Colors.orange),
                    const SizedBox(width: 12),
                    _summaryCard('Collected', '₹${(totalExpected - totalMonthlyPending).clamp(0, double.infinity).toInt()}', Icons.check_circle_outline, Colors.green),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassTabs() {
    return Container(
      height: 60,
      width: double.infinity,
      color: Colors.white,
      alignment: Alignment.center, // Center the tabs
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.center, // Center tabs for all devices
        indicatorColor: Colors.blue[800],
        indicatorWeight: 3,
        labelColor: Colors.blue[800],
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: _classes.map((c) => Tab(text: 'Class ${c.name}')).toList(),
      ),
    );
  }

  Widget _buildBottomTools(BuildContext context, ClassModel? classModel) {
    if (classModel == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _toolButton(context, 'Define', Icons.settings_suggest, Colors.indigo, () => _showDefineDialog(context, classModel)),
            _toolButton(context, 'Collect', Icons.account_balance_wallet, Colors.green, () => _showPaymentDialog(context, classModel)),
            _toolButton(context, 'Fine', Icons.gavel, Colors.orange, () => _showFineDialog(context, classModel)),
          ],
        ),
      ),
    );
  }

  Widget _toolButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _showProcessMonthDialog(BuildContext context) async {
    // 1. Fetch Current Session
    String currentSession = '2025-26'; // Fallback
    try {
      final schoolService = Provider.of<SchoolInfoService>(context, listen: false);
      final data = await schoolService.getSchoolInfo();
      if (data != null && data['currentSession'] != null) {
        currentSession = data['currentSession'];
      }
    } catch (e) {
      print('Error loading session: $e');
    }

    // Fetch processed months
    List<String> processedMonths = [];
    try {
      processedMonths = await Provider.of<FeeService>(context, listen: false).getProcessedFeeMonths(currentSession);
    } catch (e) {
      print('Error loading processed months: $e');
    }


    String? selectedMonth;
    final months = [
      'April', 'May', 'June', 'July', 'August', 'September', 
      'October', 'November', 'December', 'January', 'February', 'March'
    ];

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.history_edu, color: Colors.indigo),
              const SizedBox(width: 10),
              const Text('Process Monthly Fees'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("1. Session (Auto-selected)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                  ),
                  child: Text(
                    currentSession,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Text("2. Select Month to Process", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: months.map((month) {
                    final year = _calculateYearForMonth(month, currentSession);
                    final fullMonthName = "$month $year";
                    final isProcessed = processedMonths.contains(fullMonthName);
                    final isSelected = selectedMonth == month;

                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(month),
                          if (isProcessed) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check, size: 14, color: Colors.white),
                          ]
                        ],
                      ),
                      selected: isSelected || isProcessed,
                      selectedColor: isProcessed ? Colors.green : Colors.indigo,
                      backgroundColor: isProcessed ? Colors.green.withOpacity(0.5) : null,
                      disabledColor: Colors.green.shade200,
                      labelStyle: TextStyle(
                        color: (isSelected || isProcessed) ? Colors.white : Colors.black
                      ),
                      onSelected: isProcessed ? null : (selected) {
                         setState(() => selectedMonth = selected ? month : null);
                      },
                    );
                  }).toList(),
                ),
                if (selectedMonth != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Processing for: $selectedMonth ${_calculateYearForMonth(selectedMonth!, currentSession)}",
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.green[700]),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('This will add monthly charges to ALL students in ALL classes.', 
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: selectedMonth == null ? null : () async {
                final year = _calculateYearForMonth(selectedMonth!, currentSession);
                final fullMonthName = "$selectedMonth $year";

                Navigator.pop(context); // Close dialog
                _processFees(context, fullMonthName, currentSession);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Process All'),
            ),
          ],
        ),
      ),
    );
  }


  String _calculateYearForMonth(String month, String session) {
    // Session format: 2025-26
    // Months [April...Dec] -> 2025
    // Months [Jan...March] -> 2026
    try {
      final parts = session.split('-');
      final startYear = int.parse(parts[0]);
      final nextYear = int.parse(parts[0]) + 1; // logical next year, not just from string suffix
      
      const nextYearMonths = ['January', 'February', 'March'];
      if (nextYearMonths.contains(month)) {
        return nextYear.toString();
      } else {
        return startYear.toString();
      }
    } catch (e) {
      return DateTime.now().year.toString(); // Fallback
    }
  }

  Future<void> _processFees(BuildContext context, String monthName, String session) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 15),
            const Text('Processing fees for ALL classes...'),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
    
    try {
      await Provider.of<FeeService>(context, listen: false).processMonthlyFeesForAllClasses(monthName, session);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Successfully processed fees for all classes for $monthName'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  void _showDefineDialog(BuildContext context, ClassModel classModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DefineFeeSheet(classModel: classModel),
    );
  }

  void _showPaymentDialog(BuildContext context, ClassModel classModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CashPaymentSheet(classModel: classModel),
    );
  }

  void _showFineDialog(BuildContext context, ClassModel classModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ApplyFineSheet(classModel: classModel),
    );
  }

  void _showAutoPilotSettings(BuildContext context) {
    final fineAmountController = TextEditingController(text: _fineAmount > 0 ? _fineAmount.toString() : '');
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber),
              const SizedBox(width: 10),
              const Text('Auto Pilot Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fee Auto Pilot Section
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Fee Auto Pilot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Process monthly fees automatically', style: TextStyle(fontSize: 11)),
                        value: _isAutoPilotEnabled == true,
                        activeThumbColor: Colors.indigo,
                        onChanged: (val) {
                          setDialogState(() => _isAutoPilotEnabled = val);
                        },
                      ),
                      if (_isAutoPilotEnabled == true) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: DropdownButtonFormField<int>(
                            initialValue: _autoPilotDay,
                            decoration: const InputDecoration(
                              labelText: 'Processing Day',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: List.generate(31, (i) => i + 1).map((day) {
                              return DropdownMenuItem(value: day, child: Text("Day $day"));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => _autoPilotDay = val);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Fine Auto Pilot Section
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Fine Auto Pilot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Apply late fines to outstanding dues', style: TextStyle(fontSize: 11)),
                        value: _isFineAutoPilotEnabled == true,
                        activeThumbColor: Colors.orange,
                        onChanged: (val) {
                          setDialogState(() => _isFineAutoPilotEnabled = val);
                        },
                      ),
                      if (_isFineAutoPilotEnabled == true) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: DropdownButtonFormField<int>(
                            initialValue: _fineAutoPilotDay,
                            decoration: const InputDecoration(
                              labelText: 'Fine Apply Day',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: List.generate(31, (i) => i + 1).map((day) {
                              return DropdownMenuItem(value: day, child: Text("Day $day"));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => _fineAutoPilotDay = val);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: fineAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Fine Amount (₹)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Settings will be applied for all classes automatically.',
                  style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(fineAmountController.text) ?? 0;
                final schoolService = Provider.of<SchoolInfoService>(context, listen: false);
                await schoolService.updateSchoolInfo({
                  'feeAutoPilotEnabled': _isAutoPilotEnabled,
                  'feeAutoPilotDay': _autoPilotDay,
                  'fineAutoPilotEnabled': _isFineAutoPilotEnabled,
                  'fineAutoPilotDay': _fineAutoPilotDay,
                  'fineAutoPilotAmount': amount,
                });
                if (mounted) {
                  setState(() {
                  _fineAmount = amount;
                });
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All Auto Pilot settings saved'), backgroundColor: Colors.indigo),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateDueListPDF(BuildContext context, ClassModel classModel) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Generating Due List PDF...'), duration: Duration(seconds: 2)),
    );

    try {
      final schoolService = Provider.of<SchoolInfoService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);
      final busService = Provider.of<BusService>(context, listen: false);
      
      final schoolInfo = await schoolService.getSchoolInfo();
      final students = await userService.getStudentsByClass(classModel.id).first;
      final destinations = await busService.getDestinations().first;
      
      final schoolName = schoolInfo?['name'] ?? 'VEENA PUBLIC SCHOOL';
      final schoolAddress = schoolInfo?['address'] ?? 'Village - Koni, Post - Koni, Dist - Bilaspur (C.G.)';
      final now = DateTime.now();
      final monthName = DateFormat('MMMM').format(now);
      final year = now.year.toString();

      List<Map<String, dynamic>> studentDataList = [];

      for (var s in students) {
        final feeConfig = s['feeConfig'] as Map<String, dynamic>? ?? {};
        double monthlyTotal = 0.0;
        
        if (feeConfig['Coaching Fee'] != false) monthlyTotal += classModel.coachingFee;
        
        if (feeConfig['Bus Fee'] != false) {
          final busStopId = s['busStopId']?.toString();
          final stop = destinations.firstWhere(
            (d) => d.id == busStopId,
            orElse: () => BusDestination(id: '', name: '', lat: 0, lng: 0, fee: classModel.busFee),
          );
          monthlyTotal += stop.fee;
        }
        
        if (feeConfig['Hostel Fee'] != false) monthlyTotal += classModel.hostelFee;
        
        for (var entry in classModel.otherFees.entries) {
          if (feeConfig[entry.key] != false) monthlyTotal += entry.value;
        }

        final double currentDue = (s['currentDue'] as num?)?.toDouble() ?? 0.0;
        
        double thisMonthDue = monthlyTotal;
        if (currentDue < monthlyTotal) {
          thisMonthDue = currentDue;
        }
        double previousMonthDue = (currentDue - thisMonthDue).clamp(0, double.infinity);

        studentDataList.add({
          'name': s['name'] ?? 'Unknown',
          'admNo': s['admNo'] ?? 'N/A',
          'phone': s['phone'] ?? 'N/A',
          'prevDue': previousMonthDue,
          'thisMonthDue': thisMonthDue,
          'totalDue': currentDue,
        });
      }

      // Sort by total due (descending)
      studentDataList.sort((a, b) => (b['totalDue'] as double).compareTo(a['totalDue'] as double));

      // Load Logo
      Uint8List logoData;
      try {
        logoData = (await rootBundle.load('assets/logos/logo.png')).buffer.asUint8List();
      } catch (e) {
        logoData = Uint8List(0); // Fallback to empty
      }
      final logoImage = logoData.isNotEmpty ? pw.MemoryImage(logoData) : null;

      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
             return pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoImage != null)
                          pw.Container(
                            width: 60,
                            height: 60,
                            margin: const pw.EdgeInsets.only(right: 15),
                            child: pw.Image(logoImage),
                          ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(schoolName.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.SizedBox(height: 2),
                            pw.Text(schoolAddress, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(thickness: 1, color: PdfColors.blue100),
                    pw.SizedBox(height: 10),
                    pw.Text('DUE LIST - ${classModel.name.toUpperCase()}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                    pw.Text('(Till $monthName - $year)', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                    pw.SizedBox(height: 15),
                  ],
                );
          },
          build: (pw.Context context) {
            return [
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                headers: ['Name', 'ADM.no', 'Mobile no', 'Prev Due', 'This Month Due', 'Total Due', 'Remark/Follow up'],
                data: studentDataList.map((s) => [
                  s['name'],
                  s['admNo'],
                  s['phone'],
                  'Rs. ${s['prevDue'].toInt()}',
                  'Rs. ${s['thisMonthDue'].toInt()}',
                  'Rs. ${s['totalDue'].toInt()}',
                  '', // Remarks placeholder
                ]).toList(),
              ),
            ];
          },
          footer: (pw.Context context) {
            return pw.Padding(
                padding: const pw.EdgeInsets.only(top: 20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Report Generated on: ${DateFormat('dd-MMM-yyyy').format(now)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              );
          }
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Due_List_${classModel.name}_$monthName.pdf',
      );

    } catch (e) {
      print('PDF Generation Error: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Error generating PDF: $e')),
      );
    }
  }
}

class _ResponsiveStudentView extends StatelessWidget {
  final String classId;
  final ClassModel classModel;

  const _ResponsiveStudentView({required this.classId, required this.classModel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusDestination>>(
      stream: Provider.of<BusService>(context, listen: false).getDestinations(),
      builder: (context, destSnapshot) {
        final destinations = destSnapshot.data ?? [];
        
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Provider.of<UserService>(context).getStudentsByClass(classId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final students = snapshot.data!;
            if (students.isEmpty) {
              return const Center(child: Text("No students in this class", style: TextStyle(color: Colors.grey)));
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return _buildExcelView(context, students, destinations, constraints.maxWidth);
                } else {
                  return _buildListView(students, destinations);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildExcelView(BuildContext context, List<Map<String, dynamic>> students, List<BusDestination> destinations, double availableWidth) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: availableWidth),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
            dataRowMinHeight: 60,
            dataRowMaxHeight: 60,
            columnSpacing: 40, // Increased spacing for better readability
            columns: [
              const DataColumn(label: Text('Adm.no', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Coaching', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Bus', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Hostel', style: TextStyle(fontWeight: FontWeight.bold))),
              ...classModel.otherFees.keys.map((k) => DataColumn(label: Text(k, style: const TextStyle(fontWeight: FontWeight.bold)))),
              const DataColumn(label: Text('Monthly Total', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Current Due', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: students.map((s) {
              final feeConfig = s['feeConfig'] as Map<String, dynamic>? ?? {};
              
              // Calculate dynamic total
              double total = 0.0;
              if (feeConfig['Coaching Fee'] != false) total += classModel.coachingFee;
              
              double currentStudentBusFee = classModel.busFee;
              if (feeConfig['Bus Fee'] != false) {
                final busStopId = s['busStopId']?.toString();
                final stop = destinations.firstWhere(
                  (d) => d.id == busStopId,
                  orElse: () => BusDestination(id: '', name: '', lat: 0, lng: 0, fee: classModel.busFee),
                );
                currentStudentBusFee = stop.fee;
                total += currentStudentBusFee;
              }
              
              if (feeConfig['Hostel Fee'] != false) total += classModel.hostelFee;
              
              classModel.otherFees.forEach((key, value) {
                if (feeConfig[key] != false) total += value;
              });

              final double due = (s['currentDue'] as num?)?.toDouble() ?? 0.0;
              final userId = s['id'];

              return DataRow(cells: [
                DataCell(Text(s['admNo'] ?? 'N/A')),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (s['phone'] != null) Text(s['phone'], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    ],
                  ),
                ),
                // Coaching Toggle
                _buildToggleCell(context, userId, 'Coaching Fee', classModel.coachingFee, feeConfig['Coaching Fee'] != false),
                // Bus Toggle
                _buildToggleCell(context, userId, 'Bus Fee', currentStudentBusFee, feeConfig['Bus Fee'] != false),
                // Hostel Toggle
                _buildToggleCell(context, userId, 'Hostel Fee', classModel.hostelFee, feeConfig['Hostel Fee'] != false),
                
                ...classModel.otherFees.entries.map((e) => 
                  _buildToggleCell(context, userId, e.key, e.value, feeConfig[e.key] != false)
                ),

                DataCell(Text('₹${total.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                DataCell(
                  _buildDueCell(context, due, total),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDueCell(BuildContext context, double currentDue, double monthlyTotal) {
    if (currentDue <= 0) {
      return Text('₹${currentDue.toInt()}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
    }

    double thisMonthDue = monthlyTotal;
    // If due is less than monthly total, it means partial payment for this month, so remaining is the due
    if (currentDue < monthlyTotal) {
      thisMonthDue = currentDue;
    }
    
    double previousMonthDue = (currentDue - thisMonthDue).clamp(0, double.infinity);

    return PopupMenuButton<void>(
      tooltip: 'View Due Breakdown',
      offset: const Offset(0, 30),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('₹${currentDue.toInt()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const Icon(Icons.arrow_drop_down, color: Colors.red, size: 18),
        ],
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Breakdown', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('This Month:', style: TextStyle(fontSize: 13, color: Colors.black87)),
                  Text('₹${thisMonthDue.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              if (previousMonthDue > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Previous:', style: TextStyle(fontSize: 13, color: Colors.black87)),
                      Text('₹${previousMonthDue.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  DataCell _buildToggleCell(BuildContext context, String userId, String label, double amount, bool isActive) {
     if (amount == 0) return const DataCell(Text('-'));
     return DataCell(
       InkWell(
         onTap: () {
           // Toggle
           Provider.of<UserService>(context, listen: false).updateStudentFeeConfig(userId, label, !isActive);
         },
         child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
           decoration: BoxDecoration(
             color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: isActive ? Colors.green : Colors.red, width: 0.5),
           ),
           child: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               Text('₹${amount.toInt()}', style: TextStyle(
                 fontWeight: FontWeight.bold, 
                 fontSize: 12,
                 color: isActive ? Colors.black : Colors.grey
               )),
               const SizedBox(width: 4),
               Icon(
                 isActive ? Icons.check_circle : Icons.cancel, 
                 size: 16, 
                 color: isActive ? Colors.green : Colors.red
                ),
             ],
           ),
         ),
       ),
     );
  }

  Widget _buildListView(List<Map<String, dynamic>> students, List<BusDestination> destinations) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        final double due = (s['currentDue'] as num?)?.toDouble() ?? 0.0;
        final feeConfig = s['feeConfig'] as Map<String, dynamic>? ?? {};

        // Calculate dynamic total for Mobile View
        double monthlyTotal = 0.0;
        if (feeConfig['Coaching Fee'] != false) monthlyTotal += classModel.coachingFee;
        
        double studentBusFee = classModel.busFee;
        if (feeConfig['Bus Fee'] != false) {
          final busStopId = s['busStopId']?.toString();
          final stop = destinations.firstWhere(
            (d) => d.id == busStopId,
            orElse: () => BusDestination(id: '', name: '', lat: 0, lng: 0, fee: classModel.busFee),
          );
          studentBusFee = stop.fee;
          monthlyTotal += studentBusFee;
        }
        
        if (feeConfig['Hostel Fee'] != false) monthlyTotal += classModel.hostelFee;
        
        classModel.otherFees.forEach((key, value) {
          if (feeConfig[key] != false) monthlyTotal += value;
        });
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: due > 0 ? Colors.red[50] : Colors.green[50],
              child: Text(
                s['name']?[0] ?? 'S',
                style: TextStyle(color: due > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(s['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Adm: ${s['admNo'] ?? 'N/A'} • Due: ₹${due.toInt()}', 
              style: TextStyle(color: due > 0 ? Colors.red : Colors.grey[600], fontSize: 13)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _detailRow('Coaching Fee', '₹${classModel.coachingFee.toInt()}'),
                    _detailRow('Bus Fee', '₹${studentBusFee.toInt()}'),
                    _detailRow('Hostel Fee', '₹${classModel.hostelFee.toInt()}'),
                    ...classModel.otherFees.entries.map((e) => _detailRow(e.key, '₹${e.value.toInt()}')),
                    const Divider(),
                    _detailRow('Monthly Total', '₹${monthlyTotal.toInt()}', isBold: true),
                    _detailRow('Total Pending', '₹${due.toInt()}', isBold: true, color: due > 0 ? Colors.red : Colors.green),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.black87,
            fontSize: 14,
          )),
        ],
      ),
    );
  }
}

class _DefineFeeSheet extends StatefulWidget {
  final ClassModel classModel;
  const _DefineFeeSheet({required this.classModel});

  @override
  State<_DefineFeeSheet> createState() => _DefineFeeSheetState();
}

class _DefineFeeSheetState extends State<_DefineFeeSheet> {
  late TextEditingController _coachingCtrl;
  late TextEditingController _busCtrl;
  late TextEditingController _hostelCtrl;
  final Map<String, TextEditingController> _otherCtrls = {};

  @override
  void initState() {
    super.initState();
    _coachingCtrl = TextEditingController(text: widget.classModel.coachingFee.toInt().toString());
    _busCtrl = TextEditingController(text: widget.classModel.busFee.toInt().toString());
    _hostelCtrl = TextEditingController(text: widget.classModel.hostelFee.toInt().toString());
    widget.classModel.otherFees.forEach((k, v) {
      _otherCtrls[k] = TextEditingController(text: v.toInt().toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('Define Fees', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Set monthly charges for ${widget.classModel.name}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 24),
          _input('Coaching Fee', _coachingCtrl, Icons.school_outlined),
          _input('Bus Fee', _busCtrl, Icons.directions_bus_outlined),
          _input('Hostel Fee', _hostelCtrl, Icons.hotel_outlined),
          ..._otherCtrls.entries.map((e) => _input(e.key, e.value, Icons.star_border)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _addNewField,
            icon: const Icon(Icons.add),
            label: const Text('Add Custom Fee Field'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: BorderSide(color: Colors.indigo[100]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.indigo[300]),
          prefixText: '₹ ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.indigo)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  void _addNewField() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        return AlertDialog(
          title: const Text('New Fee Field'),
          content: TextField(
            decoration: const InputDecoration(labelText: 'Field Name (e.g. Milk, Uniform)'),
            onChanged: (v) => name = v,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  setState(() {
                    _otherCtrls[name] = TextEditingController(text: '0');
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _save() async {
    final coaching = double.tryParse(_coachingCtrl.text) ?? 0;
    final bus = double.tryParse(_busCtrl.text) ?? 0;
    final hostel = double.tryParse(_hostelCtrl.text) ?? 0;
    Map<String, double> other = {};
    _otherCtrls.forEach((k, v) {
      other[k] = double.tryParse(v.text) ?? 0;
    });

    final total = coaching + bus + hostel + other.values.fold(0.0, (a, b) => a + b);

    await Provider.of<ClassService>(context, listen: false).updateClassFees(
      classId: widget.classModel.id,
      coachingFee: coaching,
      busFee: bus,
      hostelFee: hostel,
      monthlyFee: total,
      otherFees: other,
    );
    Navigator.pop(context);
  }
}

class _CashPaymentSheet extends StatefulWidget {
  final ClassModel classModel;
  const _CashPaymentSheet({required this.classModel});

  @override
  State<_CashPaymentSheet> createState() => _CashPaymentSheetState();
}

class _CashPaymentSheetState extends State<_CashPaymentSheet> {
  Map<String, dynamic>? _selectedStudent;
  final _amountCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('Collect Payment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Provider.of<UserService>(context, listen: false).getStudentsByClass(widget.classModel.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final students = snapshot.data!;
              return DropdownButtonFormField<String>(
                initialValue: _selectedStudent?['id'],
                decoration: InputDecoration(
                  labelText: 'Select Student',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: students.map((s) => DropdownMenuItem(
                  value: s['id'] as String,
                  child: Text(s['name'] ?? 'Unknown'),
                )).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedStudent = students.firstWhere((s) => s['id'] == v);
                  });
                },
              );
            },
          ),
          if (_selectedStudent != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red[50]!, Colors.orange[50]!]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                children: [
                   const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.priority_high, color: Colors.white, size: 20)),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Unpaid Balance', style: TextStyle(color: Colors.red[900], fontSize: 12, fontWeight: FontWeight.bold)),
                         Text('₹${(_selectedStudent!['currentDue'] ?? 0).toInt()}', 
                           style: const TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Receive Amount',
                prefixText: '₹ ',
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _pay() async {
    if (_selectedStudent == null || _amountCtrl.text.isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    await Provider.of<FeeService>(context, listen: false).processGeneralPayment(
      userId: _selectedStudent!['id'],
      studentName: _selectedStudent!['name'],
      classId: widget.classModel.id,
      amount: amount,
      paymentMethod: 'Cash',
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment of ₹$amount received from ${_selectedStudent!['name']}')),
    );
  }
}

class _ApplyFineSheet extends StatefulWidget {
  final ClassModel classModel;
  const _ApplyFineSheet({required this.classModel});

  @override
  State<_ApplyFineSheet> createState() => _ApplyFineSheetState();
}

class _ApplyFineSheetState extends State<_ApplyFineSheet> {
  Map<String, dynamic>? _selectedStudent;
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('Apply Fine', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Provider.of<UserService>(context, listen: false).getStudentsByClass(widget.classModel.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final students = snapshot.data!;
              return DropdownButtonFormField<String>(
                initialValue: _selectedStudent?['id'],
                decoration: InputDecoration(
                  labelText: 'Select Student',
                  prefixIcon: const Icon(Icons.person_search_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: students.map((s) => DropdownMenuItem(
                  value: s['id'] as String,
                  child: Text(s['name'] ?? 'Unknown'),
                )).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedStudent = students.firstWhere((s) => s['id'] == v);
                  });
                },
              );
            },
          ),
          if (_selectedStudent != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[100]!),
              ),
              child: Row(
                children: [
                   const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20)),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Current Ledger Balance', style: TextStyle(color: Colors.orange[900], fontSize: 11, fontWeight: FontWeight.bold)),
                         Text('₹${(_selectedStudent!['currentDue'] ?? 0).toInt()}', style: const TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Fine Amount',
                prefixText: '₹ ',
                prefixIcon: const Icon(Icons.gavel_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              decoration: InputDecoration(
                labelText: 'Reason / Remark',
                prefixIcon: const Icon(Icons.edit_note),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Issue Fine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _submit() async {
    if (_selectedStudent == null || _amountCtrl.text.isEmpty || _reasonCtrl.text.isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    await Provider.of<FeeService>(context, listen: false).applyFine(
      userId: _selectedStudent!['id'],
      studentName: _selectedStudent!['name'],
      classId: widget.classModel.id,
      amount: amount,
      reason: _reasonCtrl.text,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fine of ₹$amount applied to ${_selectedStudent!['name']}')),
    );
  }
}
