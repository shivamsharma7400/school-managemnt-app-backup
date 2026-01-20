import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veena_public_school/features/driver/driver_controller.dart';

class StartBusScreen extends StatelessWidget {
  const StartBusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DriverController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Start Bus Workflow"),
      ),
      body: Obx(() {
        if (controller.isSessionActive.value) {
          return _buildActiveTripView(controller);
        } else {
          return _buildSetupForm(controller);
        }
      }),
    );
  }

  // SCREEN 1: Setup Form
  Widget _buildSetupForm(DriverController controller) {
    // Local state variables for form (using Rx for reactivity within the widget)
    final Rxn<int> formTripIndex = Rxn<int>();
    final RxList<String> formDestinations = <String>[].obs;
    final RxString formType = 'Arrival'.obs;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Select Trip Details",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Trip Dropdown
          const Text("Select Trip:"),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Obx(() => DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: formTripIndex.value,
                    hint: const Text("Choose Trip"),
                    isExpanded: true,
                    items: List.generate(5, (index) {
                      final isCompleted = controller.tripCompleted[index];
                      return DropdownMenuItem(
                        value: index,
                        enabled: !isCompleted,
                        child: Row(
                          children: [
                            Text("Trip ${index + 1}"),
                            if (isCompleted) ...[
                              const Spacer(),
                              const Icon(Icons.check_circle, color: Colors.green),
                            ]
                          ],
                        ),
                      );
                    }),
                    onChanged: (val) {
                      formTripIndex.value = val;
                    },
                  ),
                )),
          ),
          const SizedBox(height: 20),

          // Destination Multi-select Dropdown (Simplified as a Dialog or List for now)
          const Text("Select Destinations:"),
           const SizedBox(height: 8),
          Obx(() => InkWell(
            onTap: () {
               _showDestinationSelectionDialog(controller, formDestinations);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formDestinations.isEmpty
                          ? "Tap to select destinations"
                          : formDestinations.join(", "),
                      style: TextStyle(
                        color: formDestinations.isEmpty ? Colors.grey.shade600 : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          )),
          const SizedBox(height: 20),

          // Type Dropdown
          const Text("Type:"),
           const SizedBox(height: 8),
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
             child: Obx(() => DropdownButtonHideUnderline(
               child: DropdownButton<String>(
                 value: formType.value,
                 isExpanded: true,
                 items: ["Arrival", "Departure"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                 onChanged: (val) {
                   if(val != null) formType.value = val;
                 },
               ),
             )),
           ),

          const Spacer(),

          // Start Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (formTripIndex.value == null) {
                  Get.snackbar("Error", "Please select a trip");
                  return;
                }
                if (formDestinations.isEmpty) {
                  Get.snackbar("Error", "Please select at least one destination");
                  return;
                }
                controller.startSession(formTripIndex.value!, formDestinations, formType.value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text("Start", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDestinationSelectionDialog(DriverController controller, RxList<String> currentSelections) {
    Get.dialog(
      AlertDialog(
        title: const Text("Select Destinations"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controller.availableDestinations.length,
            itemBuilder: (context, index) {
              final dest = controller.availableDestinations[index];
              return Obx(() {
                 final isSelected = currentSelections.contains(dest);
                 return CheckboxListTile(
                   title: Text(dest),
                   value: isSelected,
                   onChanged: (val) {
                     if (val == true) {
                       currentSelections.add(dest);
                     } else {
                       currentSelections.remove(dest);
                     }
                   },
                 );
              });
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Done")),
        ],
      ),
    );
  }


  // SCREEN 2: Active Session
  Widget _buildActiveTripView(DriverController controller) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Current Time
          Obx(() => Text(
                controller.currentTime.value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              )),
          const SizedBox(height: 10),
          
          // Timer Icon
          const Icon(Icons.timer, size: 100, color: Colors.blueAccent),
          
           const SizedBox(height: 20),

          // Trip Info
           Card(
             elevation: 4,
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 children: [
                   Text(
                     "Trip ${controller.selectedTripIndex.value! + 1}",
                     style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                   ),
                    const SizedBox(height: 8),
                   Text(
                     "Type: ${controller.selectedType.value}",
                     style: const TextStyle(fontSize: 16, color: Colors.grey),
                   ),
                    const SizedBox(height: 12),
                   const Text("Destinations:", style: TextStyle(fontWeight: FontWeight.bold)),
                   ...controller.selectedDestinations.map((e) => Text(e)),
                 ],
               ),
             ),
           ),

          const Spacer(),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.nextTrip();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                     side: const BorderSide(color: Colors.blueAccent),
                  ),
                  child: const Text("Next Trip"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                     controller.completeSession();
                  },
                   style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Complete Session"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
