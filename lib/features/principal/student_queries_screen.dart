import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/student_query_service.dart';

class StudentQueriesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Queries')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<StudentQueryService>(context).getPendingQueries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No queries found."));
          }

          final queries = snapshot.data!;
          return ListView.builder(
            itemCount: queries.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final query = queries[index];
              final Timestamp? timestamp = query['timestamp'] as Timestamp?;
              final dateStr = timestamp != null 
                  ? DateFormat('MMM d, h:mm a').format(timestamp.toDate()) 
                  : 'Just now';
              final isReviewed = query['isReviewed'] ?? false;

              return Card(
                color: isReviewed ? Colors.white : Colors.blue[50],
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            query['userName'] ?? 'Unknown User',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (!isReviewed)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                              child: Text('New', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                        ],
                      ),
                      Text(dateStr, style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Divider(),
                      Text("Q: ${query['query']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(height: 8),
                      Text("AI Answer: ${query['aiResponse']}", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[800])),
                      if (!isReviewed)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Provider.of<StudentQueryService>(context, listen: false).markAsReviewed(query['id']);
                            },
                            child: Text("Mark as Reviewed"),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
