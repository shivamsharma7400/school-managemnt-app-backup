import 'package:get/get.dart';
import 'dart:async';

class DriverController extends GetxController {
  // Trip Status: true if completed, false otherwise
  // Index 0 = Trip 1, Index 4 = Trip 5
  var tripCompleted = <bool>[false, false, false, false, false].obs;
  
  // Current Selection
  var selectedTripIndex = Rxn<int>();
  var selectedDestinations = <String>[].obs;
  var selectedType = 'Arrival'.obs; // Arrival / Departure

  // Session State
  var isSessionActive = false.obs;
  var sessionStartTime = Rxn<DateTime>();
  Timer? _timer;
  var currentTime = ''.obs;

  // Mock Destinations (As per user, management sets these)
  final List<String> availableDestinations = [
    'Stop A (Main Gate)',
    'Stop B (City Center)',
    'Stop C (North Avenue)',
    'Stop D (South Park)',
    'Stop E (West End)',
  ];

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void startSession(int tripIndex, List<String> destinations, String type) {
    selectedTripIndex.value = tripIndex;
    selectedDestinations.value = destinations;
    selectedType.value = type;
    isSessionActive.value = true;
    sessionStartTime.value = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    currentTime.value = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  }

  void nextTrip() {
    if (selectedTripIndex.value != null) {
      // Mark current trip as completed
      tripCompleted[selectedTripIndex.value!] = true;
    }
    
    // Reset session state to show form again
    isSessionActive.value = false;
    selectedTripIndex.value = null;
    selectedDestinations.clear();
    _timer?.cancel();
  }

  void completeSession() {
    if (selectedTripIndex.value != null) {
      tripCompleted[selectedTripIndex.value!] = true;
    }
    // Reset everything
    isSessionActive.value = false;
    selectedTripIndex.value = null;
    selectedDestinations.clear();
    _timer?.cancel();
    
    // Optionally navigate back or show success
    Get.back(); 
    Get.snackbar("Session Completed", "Bus session has ended successfully.");
  }
}
