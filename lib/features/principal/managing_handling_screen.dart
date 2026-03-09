import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vps/features/common/widgets/modern_layout.dart';
import 'package:vps/core/constants/app_constants.dart';

class ManagingHandlingScreen extends StatelessWidget {
  const ManagingHandlingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernLayout(
      title: 'Managing & Handling',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operational Overview',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your daily tasks, planning, and team distribution.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: constraints.maxWidth > 1200 ? 2 : 1,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.8,
                  children: [
                    _buildTodoModule(),
                    _buildThingsToDoModule(),
                    _buildWorkDistributionModule(),
                    _buildPlanningModule(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoModule() {
    return _buildModuleCard(
      title: 'To-do List',
      icon: Icons.check_circle_outline_rounded,
      color: Colors.blue,
      trailing: TextButton(
        onPressed: () {},
        child: const Text('+ Add Task'),
      ),
      children: [
        _buildTodoItem('Review teacher attendance', true),
        _buildTodoItem('Approve pending fee waivers', false),
        _buildTodoItem('Finalize monthly audit report', false),
      ],
    );
  }

  Widget _buildTodoItem(String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            color: isDone ? Colors.green : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDone ? Colors.grey : Colors.black87,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThingsToDoModule() {
    return _buildModuleCard(
      title: 'Things to do',
      icon: Icons.lightbulb_outline_rounded,
      color: Colors.amber,
      children: [
        _buildNoteItem('Organize annual sports meet preparation'),
        _buildNoteItem('Schedule parent-teacher meeting for Grade 10'),
        _buildNoteItem('Upgrade library management system'),
      ],
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDistributionModule() {
    return _buildModuleCard(
      title: 'Work Distribution',
      icon: Icons.groups_outlined,
      color: Colors.purple,
      children: [
        _buildDistributionItem('Senior Teachers', 'Exam Coordination', 0.8),
        _buildDistributionItem('Admin Staff', 'Fee Collection', 0.6),
        _buildDistributionItem('Support Staff', 'School Maintenance', 0.4),
      ],
    );
  }

  Widget _buildDistributionItem(String team, String task, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(team, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(task, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.purple.shade50,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningModule() {
    return _buildModuleCard(
      title: 'Today\'s Planning',
      icon: Icons.calendar_today_rounded,
      color: Colors.teal,
      children: [
        _buildPlanningItem('09:00 AM', 'Morning Assembly & Briefing'),
        _buildPlanningItem('11:30 AM', 'Curriculum Review Meeting'),
        _buildPlanningItem('02:00 PM', 'Staff Performance Evaluation'),
      ],
    );
  }

  Widget _buildPlanningItem(String time, String event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
