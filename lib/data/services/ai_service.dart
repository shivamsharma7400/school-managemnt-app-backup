

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AIService extends ChangeNotifier {
  // Ideally this should be in .env, but for this setup we keep it simple as requested
  static const String _apiKey = 'AIzaSyBIq_qSKGogWvH44OqybnmUH3gljqk4gtQ';
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: _apiKey,
    );
  }

  Future<String?> generateContent(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print('AI Error: $e');
      return "I'm having trouble connecting to the AI. Please try again later.";
    }
  }

  Future<String?> generateLeaveApplication({
    required String reason,
    required String startDate,
    required String endDate,
    required String name,
    required String role,
    String? className,
  }) async {
    // Context Retrieval
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
    // Context Retrieval
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
    - If 'Urgent': Be direct and concise.
    - If 'Event': Be inviting and informative.
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
  // Create a chat session with history
  Future<ChatSession> startChatSession() async {
    // Fetch School Info for system prompt
    final schoolInfoDoc = await FirebaseFirestore.instance.collection('school_settings').doc('info').get();
    final schoolInfo = schoolInfoDoc.data() ?? {};

    final String name = schoolInfo['name'] ?? 'Veena Public School';
    final String address = schoolInfo['address'] ?? 'Unknown Location';
    final String timings = schoolInfo['timings'] ?? '8 AM - 2 PM';
    final String contact = schoolInfo['contact'] ?? 'Contact Administration';
    final String rules = schoolInfo['rules'] ?? 'No specific rules provided.';
    final String about = schoolInfo['about'] ?? '';

    final systemPrompt = """
    You are "Veena AI Agent", a helpful and polite assistant for $name.
    
    Official School Info:
    - Address: $address
    - Timings: $timings
    - Contact: $contact
    - Admission/Rules: $rules
    - About School: $about

    Task:
    - Answer based strictly on the above information if available.
    - If the user asks something not covered here, politely suggest contacting the administration at $contact.
    - Be welcoming and encouraging.
    - Keep answers concise.
    - Use Markdown for formatting (bold, bullet points) to make text easy to read.
    """;

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(systemPrompt),
    );

    return model.startChat(history: []);
  }

  // Keep old method for backward compatibility if needed, using the new session momentarily
  Future<String?> answerSchoolQuery(String query) async {
    try {
      final chat = await startChatSession();
      final response = await chat.sendMessage(Content.text(query));
      return response.text;
    } catch (e) {
      print("AI Error: $e");
      return "I'm having trouble connecting right now. Please try again later.";
    }
  }
  // Principal AI Session with Full Context
  Future<ChatSession> startPrincipalChatSession() async {
    // 1. Fetch School Info
    final schoolDocs = await FirebaseFirestore.instance.collection('school_settings').doc('info').get();
    final schoolName = schoolDocs.data()?['name'] ?? 'Veena Public School';

    // 2. Fetch Pending Admissions (Users)
    final pendingSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'pending').get();
    final pendingCount = pendingSnapshot.docs.length;
    final pendingNames = pendingSnapshot.docs.take(5).map((d) => d['name']).join(', ');

    // 3. Fetch Leave Requests
    final leaveSnapshot = await FirebaseFirestore.instance.collection('leave_requests').where('status', isEqualTo: 'pending').get();
    final leaveCount = leaveSnapshot.docs.length;
    final leaveDetails = leaveSnapshot.docs.take(5).map((d) => "${d['studentName']} (${d['reason']})").join('; ');

    // 4. Fetch Recent Transactions (Budget/Growth)
    // Note: This is simplified. Real growth analysis needs more data.
    final transactionSnapshot = await FirebaseFirestore.instance.collection('transactions')
        .orderBy('date', descending: true).limit(10).get();
    final recentTransactions = transactionSnapshot.docs.map((d) => "${d['type']}: ${d['amount']} by ${d['studentName']}").join('\n');

    // 5. Fetch Diary & To-Do (Principal's personal data)
    // We assume single principal for MVP or handle by user ID if passed, but here simplified.
    // In a real app, pass userId to this method.
    // Let's assume we can fetch 'principal_diary' collection.
    // We'll skip specific user filtering for this generic context or assume it's global for the principal role.

    final systemPrompt = """
    You are the "Principal's AI Assistant" for $schoolName.
    You have access to real-time school data.
    
    Current Status:
    - Pending Admissions: $pendingCount (Names: $pendingNames...)
    - Pending Leaves: $leaveCount (Requests: $leaveDetails...)
    - Recent Finance Activity:
    $recentTransactions

    Capabilities:
    - Analyze school growth and suggest improvements (e.g., "How to improve with low budget?").
    - Advise on curriculum (e.g., "Class 3 Computer syllabus").
    - Recall Diary entries and To-Do items if the user asks (The user has a separate Diary/To-Do section).
    - Plan the day.

    Tone: Executive, Strategic, and Helpful.
    Format: Use Markdown. Be concise but deep in insight.
    """;

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(systemPrompt),
    );

    return model.startChat(history: []);
  }

  // Helper to generate generic content (kept for other uses)
  Future<String?> generateGenericResponse(String prompt) async {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
  }
}
