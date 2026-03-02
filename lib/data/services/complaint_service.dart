import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';
import 'ai_service.dart';

class ComplaintService {
  final CollectionReference _complaintsCollection =
      FirebaseFirestore.instance.collection('complaints');
  final AIService _aiService = AIService();

  // Submit a new complaint
  Future<void> submitComplaint(ComplaintModel complaint) async {
    await _complaintsCollection.doc(complaint.id).set(complaint.toMap());
  }


  // Get complaints for a specific user
  Stream<List<ComplaintModel>> getUserComplaints(String userId) {
    return _complaintsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final complaints = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort in memory to avoid Firestore Index requirement
      complaints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return complaints;
    });
  }

  // Get all pending complaints for Principal
  Stream<List<ComplaintModel>> getPendingComplaints() {
    return _complaintsCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final complaints = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Sort in memory to avoid Firestore Index requirement
      complaints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return complaints;
    });
  }

  // Get pending complaints count for Principal Dashboard
  Stream<int> getPendingComplaintsCount() {
    return _complaintsCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Approve a complaint with a response
  Future<void> approveComplaint(String id, String response) async {
    await _complaintsCollection.doc(id).update({
      'status': 'approved',
      'response': response,
    });
  }

  // Reject a complaint with a reason
  Future<void> rejectComplaint(String id, String reason) async {
    await _complaintsCollection.doc(id).update({
      'status': 'rejected',
      'response': reason,
    });
  }


  // AI Rewrite for Complaint Description
  Future<String?> rewriteComplaintWithAI(String originalText, String userName, String userRole, {Map<String, dynamic>? userDetails}) async {
    String extraDetails = "";
    if (userDetails != null) {
      final className = userDetails['classId'] ?? 'N/A';
      final section = userDetails['section'] ?? 'N/A';
      final admNo = userDetails['admNo'] ?? 'N/A';
      extraDetails = "\nUser Details for Signature:\n- Name: $userName\n- Role: $userRole\n- Class: $className\n- Section: $section\n- Admission No: $admNo";
    }

    final prompt = """
    You are an AI assistant helping a $userRole named $userName write a formal complaint to the school principal.
    $extraDetails
    
    Task: Rewrite the following complaint draft into a professional, polite, and well-structured formal letter. 
    The output must be a COMPLETE letter ready to be submitted. 
    It MUST include:
    1. A formal Subject line.
    2. A formal salutation (e.g., Respected Principal,).
    3. The body of the complaint based on the draft.
    4. A proper closing (e.g., Sincerely, or Yours obediently,).
    5. A signature block at the end using the User Details provided above.

    Do NOT add any conversational fillers like "Sure, here is the letter". 
    Just output the final rewritten complaint letter text itself.

    Original Draft:
    "$originalText"
    
    Rewritten Complaint:
    """;
    
    return await _aiService.generateContent(prompt);
  }

  // AI Generate Response for Principal
  Future<String?> generateResponseWithAI(String complaintText, bool isApprove) async {
    final action = isApprove ? "approving" : "rejecting";
    final prompt = """
    You are the Principal of a school. 
    Write a short, professional, and empathetic response to the following complaint, $action it.
    
    Complaint: "$complaintText"
    
    Response:
    """;
    
    return await _aiService.generateContent(prompt);
  }
}
