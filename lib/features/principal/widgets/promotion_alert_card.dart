import 'package:flutter/material.dart';
import '../../../data/services/promotion_service.dart';

class PromotionAlertCard extends StatefulWidget {
  const PromotionAlertCard({super.key});

  @override
  State<PromotionAlertCard> createState() => _PromotionAlertCardState();
}

class _PromotionAlertCardState extends State<PromotionAlertCard> {
  bool _isPending = false;
  bool _isLoading = true;
  final PromotionService _promotionService = PromotionService();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    bool pending = await _promotionService.isPromotionPending();
    if (mounted) {
      setState(() {
        _isPending = pending;
        _isLoading = false;
      });
    }
  }

  void _runPromotion() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Start New Academic Session?"),
        content: Text(
          "This will promote all students (Class 1-7 -> Next Class) and GRADUATE Class 8 students (Delete Data).\n\n"
          "This action cannot be undone. Are you sure?"
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Confirm & Start", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      final stats = await _promotionService.runPromotion();
      setState(() {
        _isLoading = false;
        _isPending = false;
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Promotion Complete"),
            content: Text("Promoted: ${stats['promoted']}\nGraduated/Removed: ${stats['graduated']}"),
             actions: [
               TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
             ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return SizedBox.shrink(); // Or loading spinner
    if (!_isPending) return SizedBox.shrink(); // Hide if not pending

    return Card(
      color: Colors.red.shade50,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Academic Session End (March 31)", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text("It's time to promote students to the next class."),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _runPromotion,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Start New Session", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
