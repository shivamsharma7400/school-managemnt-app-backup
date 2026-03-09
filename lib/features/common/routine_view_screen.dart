
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/routine_service.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class RoutineViewScreen extends StatelessWidget {
  const RoutineViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Routines'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Class Routine', icon: Icon(Icons.class_)),
              Tab(text: 'Bus Routine', icon: Icon(Icons.directions_bus)),
              Tab(text: 'Time Table', icon: Icon(Icons.table_chart)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RoutineList(type: 'class'),
            _RoutineList(type: 'bus'),
            _RoutineList(type: 'timetable'),
          ],
        ),
      ),
    );
  }
}

class _RoutineList extends StatelessWidget {
  final String type;

  const _RoutineList({required this.type});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<RoutineService>(context).getRoutines(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('No routines found.'));

        final routines = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: routines.length,
          itemBuilder: (context, index) {
            final routine = routines[index];
            return Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))
                ]
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      routine['title'] ?? '', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue.shade900)
                    ),
                    subtitle: routine['tableData'] == null ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SelectableLinkify(
                        onOpen: (link) async {
                           final Uri url = Uri.parse(link.url);
                           if (await canLaunchUrl(url)) {
                             await launchUrl(url, mode: LaunchMode.externalApplication);
                           }
                        },
                        text: routine['description'] ?? '',
                        style: TextStyle(color: Colors.black87, height: 1.4),
                        linkStyle: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      ),
                    ) : null,
                    trailing: routine['imageUrl'] != null && (routine['imageUrl'] as String).isNotEmpty
                        ? InkWell(
                            onTap: () => _showFullScreenImage(context, routine['imageUrl']),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(routine['imageUrl']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        : null,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(
                        type == 'class' 
                            ? Icons.book 
                            : type == 'bus' 
                                ? Icons.airport_shuttle 
                                : Icons.table_chart, 
                        color: Colors.blue
                      ),
                    ),
                  ),
                  if (routine['tableData'] != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade100),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                              columns: List<String>.from(routine['tableData']['columns'] ?? [])
                                  .map((c) => DataColumn(
                                        label: Text(c, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                      ))
                                  .toList(),
                              rows: (routine['tableData']['rows'] as List? ?? [])
                                  .map((row) {
                                    // Handle both new Map format and old List format
                                    final List<dynamic> cells = (row is Map)
                                        ? List.generate(
                                            (routine['tableData']['columns'] as List).length,
                                            (i) => row[i.toString()] ?? "",
                                          )
                                        : (row as List);

                                    return DataRow(
                                      cells: cells.asMap().entries.map((cellEntry) {
                                        return DataCell(
                                          Text(
                                            cellEntry.value.toString(),
                                            style: TextStyle(
                                              fontWeight: cellEntry.key == 0 ? FontWeight.bold : FontWeight.normal,
                                              color: cellEntry.key == 0 ? Colors.blue.shade700 : Colors.black87,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
