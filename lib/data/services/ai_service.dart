import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// Compatibility Layer for UI
class Content {
  final String role;
  final String text;

  Content({required this.role, required this.text});

  static Content user(String text) => Content(role: 'user', text: text);
  static Content system(String text) => Content(role: 'system', text: text);
  static Content model(String text) => Content(role: 'assistant', text: text);
}

class GenerateContentResponse {
  final String? text;
  GenerateContentResponse(this.text);
}

class ChatSession {
  final AIService service;
  final List<Content> history;
  final String? systemPrompt;

  ChatSession({required this.service, required this.history, this.systemPrompt});

  Future<GenerateContentResponse> sendMessage(Content content) async {
    history.add(content);
    
    final messages = <Map<String, String>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt!});
    }
    
    for (var msg in history) {
      messages.add({'role': msg.role, 'content': msg.text});
    }

    final responseText = await service._fetchChatCompletion(messages);
    if (responseText != null) {
      history.add(Content.model(responseText));
    }
    
    return GenerateContentResponse(responseText);
  }
}

class AIService extends ChangeNotifier {
  static const String _apiKey = 'AIzaSyBIq_qSKGogWvH44OqybnmUH3gljqk4gtQ';
  static const String _modelName = 'gemini-2.5-flash'; 
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$_apiKey';

  AIService();

  Future<String?> _fetchChatCompletion(List<Map<String, String>> messages) async {
    try {
      Map<String, dynamic>? systemInstruction;
      final contents = <Map<String, dynamic>>[];
      
      for (var m in messages) {
        if (m['role'] == 'system') {
          systemInstruction = {
            'parts': [{'text': m['content']}]
          };
        } else {
          contents.add({
            'role': m['role'] == 'assistant' ? 'model' : m['role'],
            'parts': [{'text': m['content']}]
          });
        }
      }

      final body = <String, dynamic>{
        'contents': contents,
      };
      
      if (systemInstruction != null) {
        body['system_instruction'] = systemInstruction;
      }

      if (kDebugMode) {
        print('Gemini Request Body: ${jsonEncode(body)}');
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } catch (e) {
          print('Gemini Response Parsing Error: $e');
          print('Gemini Response Body: ${response.body}');
          return null;
        }
      } else {
        print('Gemini API Error: ${response.statusCode}');
        print('Gemini Error Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('AI Service Exception: $e');
      return null;
    }
  }

  Future<String?> generateContent(String prompt) async {
    final response = await _fetchChatCompletion([
      {'role': 'user', 'content': prompt}
    ]);
    return response ?? "I'm having trouble connecting to the AI. Please try again later.";
  }

  Future<String?> generateLeaveApplication({
    required String reason,
    required String startDate,
    required String endDate,
    required String name,
    required String role,
    String? className,
  }) async {
    final schoolInfoDoc = await FirebaseFirestore.instance.collection('school_settings').doc('info').get();
    final schoolName = schoolInfoDoc.data()?['name'] ?? 'Veena Public School';

    final prompt = """
    Write a formal leave application for a student/teacher.
    
    Context:
    - School: $schoolName
    - Applicant Name: $name
    - Role: $role
    ${role == 'student' && className != null ? '- Class: $className' : ''}
    - Leave Dates: From $startDate to $endDate
    - Reason: "$reason"

    INSTRUCTIONS:
    - Output ONLY the body of the letter. 
    - Do NOT include "Subject:" line.
    - Do NOT include conversational text like "Here is your letter".
    - Tone: Strictly formal, polite, and professional.
    - Format:
      To,
      The Principal,
      $schoolName.
      
      Respected Sir/Madam,

      [Body of the application]

      Yours Obediently,
      $name
    """;
    
    return await generateContent(prompt);
  }

  Future<String?> generateAnnouncement({
    required String content,
    required String title,
    required String senderName,
    required String role,
  }) async {
    final schoolInfoDoc = await FirebaseFirestore.instance.collection('school_settings').doc('info').get();
    final schoolName = schoolInfoDoc.data()?['name'] ?? 'Veena Public School';

    final prompt = """
    You are the Official Communications Officer for $schoolName.
    Refine this draft into a professional official announcement.

    Draft: "$content"
    Title: "$title"
    Sender: $senderName ($role)

    INSTRUCTIONS:
    - Output ONLY the final announcement text.
    - Do NOT include "Here is the announcement" or "Draft".
    - Tone: Authoritative, Clear, and Professional. 
    - Automatically correct grammar and make it sound official.
    - Format:
      **$title**
      
      [Refined Content]

      Regards,
      $senderName
      ($role)
      $schoolName
    """;
    
    return await generateContent(prompt);
  }

  Future<ChatSession> startChatSession() async {
    // 1. Fetch School Info (static details like address)
    final schoolInfoDoc = await FirebaseFirestore.instance.collection('school_settings').doc('info').get();
    final schoolInfo = schoolInfoDoc.data() ?? {};
    
    // 2. Fetch Dynamic Config (Name, AI Name)
    final configDoc = await FirebaseFirestore.instance.collection('settings').doc('config').get();
    final configData = configDoc.data() ?? {};

    final String name = configData['schoolName'] ?? schoolInfo['name'] ?? 'Veena Public School';
    final String aiName = configData['aiAgentName'] ?? 'Veena AI Agent';

    final String address = schoolInfo['address'] ?? 'Unknown Location';
    final String timings = schoolInfo['timings'] ?? '8 AM - 2 PM';
    final String contact = schoolInfo['contact'] ?? 'Contact Administration';
    final String rules = schoolInfo['rules'] ?? 'No specific rules provided.';
    final String about = schoolInfo['about'] ?? '';

    final systemPrompt = """
    You are "$aiName", a helpful and polite assistant for $name.
    
    Official School Info:
    - Address: $address
    - Timings: $timings
    - Contact: $contact
    - Admission/Rules: $rules
    - About School: $about

    Task:
    - Answer based strictly on the above information if available.
    - If the user asks something not covered here, politely suggest contacting the administration at $contact.
    - Keep answers concise.
    - Use Markdown for formatting.
    """;

    return ChatSession(service: this, history: [], systemPrompt: systemPrompt);
  }

  Future<String?> answerSchoolQuery(String query) async {
    try {
      final chat = await startChatSession();
      final response = await chat.sendMessage(Content.user(query));
      return response.text;
    } catch (e) {
      print("AI Error: $e");
      return "Something went wrong. Please try again later.";
    }
  }

  Future<ChatSession> startManagementChatSession(String role) async {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);
    
    if (kDebugMode) print('AI: Starting Management Session for $role at ${now.toIso8601String()}');

    try {
      // 1. School Info
      final schoolDocs = await FirebaseFirestore.instance.collection('school_settings').doc('info').get();
      final schoolName = schoolDocs.data()?['name'] ?? 'Veena Public School';
      final session = schoolDocs.data()?['currentSession'] ?? '${now.year}-${(now.year + 1).toString().substring(2)}';

      // 2. Fetch ALL School Members (Comprehensive Fetch)
      final allUsersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final allUsers = allUsersSnapshot.docs;
      
      // 3. Today's Attendance Snapshot
      final dateStart = DateTime(now.year, now.month, now.day);
      final dateEnd = dateStart.add(const Duration(days: 1));
      final attendanceSnapshot = await FirebaseFirestore.instance.collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
          .where('date', isLessThan: Timestamp.fromDate(dateEnd))
          .get();

      Set<String> presentIds = {};
      for (var doc in attendanceSnapshot.docs) {
        final records = Map<String, dynamic>.from(doc.data()['records'] ?? {});
        records.forEach((id, status) {
          if (status.toString().toLowerCase() == 'p' || status.toString().toLowerCase() == 'present') {
            presentIds.add(id);
          }
        });
      }

      // 4. Format Master Directory as a Markdown Table (Highly readable for Gemini)
      final buffer = StringBuffer();
      buffer.writeln("| ROLE | ID/ADM | NAME | CLASS/TYPE | STATUS |");
      buffer.writeln("|------|--------|------|------------|--------|");

      for (var doc in allUsers) {
        final d = doc.data();
        final uRole = (d['role'] ?? '').toString().toUpperCase();
        final name = (d['name'] ?? 'Unknown').toString();
        final isP = presentIds.contains(doc.id) ? "P" : "A";
        
        String idInfo = d['admNo']?.toString() ?? d['staffId']?.toString() ?? doc.id.substring(0, 5);
        String subInfo = d['classId']?.toString() ?? d['pendingType']?.toString() ?? uRole;

        buffer.writeln("| $uRole | $idInfo | $name | $subInfo | $isP |");
      }

      // 5. Financial Snapshot (Today)
      final transTodaySnapshot = await FirebaseFirestore.instance.collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
          .where('date', isLessThan: Timestamp.fromDate(dateEnd))
          .get();
      double todayCollected = 0;
      for (var doc in transTodaySnapshot.docs) {
        if (doc.data()['type'] == 'Fee Payment') {
          todayCollected += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      final pendingLeaves = await FirebaseFirestore.instance.collection('leave_requests').where('status', isEqualTo: 'pending').get();

      final roleLabel = role.toLowerCase() == 'admin' ? 'Admin' : 'Principal';

      final systemPrompt = """
      You are the "${roleLabel}'s Strategic Command Assistant" for $schoolName.
      Current Session: $session | Date: ${DateFormat('dd-MMM-yyyy').format(now)}
      
      CRITICAL ROLE:
      - You have FULL and UNRESTRICTED access to the School Database provided below.
      - If a user asks for Admission Number 740, you MUST search the table below for "740" in the "ID/ADM" column.
      - NEVER say "I don't have this record" or "Check manual register". The table is the source of truth.
      
      SCHOOL MASTER DIRECTORY:
      ${buffer.toString()}
      
      METRICS:
      - Today's Collection: ₹${todayCollected.toStringAsFixed(2)}
      - Pending Leaves: ${pendingLeaves.docs.length}
      
      MISSION:
      1. Provide instant details on any student/staff by name or ID.
      2. Analyze attendance (P=Present, A=Absent).
      3. Handle management strategy and document generation.
      
      Tone: Extreme focus on data accuracy. Efficient and Professional.
      Language: Match user's language (Hindi/English).
      """;

      if (kDebugMode) {
        print('AI System Prompt (v2.3) Created. Length: ${systemPrompt.length}');
      }

      if (kDebugMode) {
        print('-------------------- AI SYSTEM PROMPT START --------------------');
        print(systemPrompt);
        print('-------------------- AI SYSTEM PROMPT END --------------------');
      }

      return ChatSession(service: this, history: [], systemPrompt: systemPrompt);
    } catch (e) {
      if (kDebugMode) print('AI: Failed to start management session: $e');
      return ChatSession(
        service: this, 
        history: [], 
        systemPrompt: "System Error: The school database could not be reached. Error: $e. Please inform the user to try again later."
      );
    }
  }

  Future<String?> generateGenericResponse(String prompt) async {
      return await generateContent(prompt);
  }
}
