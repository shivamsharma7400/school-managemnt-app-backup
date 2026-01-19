import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fee_service.dart';

class PaymentService {
  late Razorpay _razorpay;
  final FeeService _feeService = FeeService();
  
  // CAUTION: Using LIVE Key as per user request.
  static const String _keyId = 'rzp_live_RzHEljBosquwb6'; 

  Function(bool success, String message)? _onResult;
  String? _currentFeeId;
  double? _currentAmount; // Added to store amount
  String? _currentStudentId;

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void openCheckout({
    required String feeId,
    required double amount,
    required String name,
    required String contact, // e.g. '9876543210'
    required String email,
    required Function(bool, String) onResult,
  }) {
    _currentFeeId = feeId;
    _currentAmount = amount; // Store amount
    _onResult = onResult;

    var options = {
      'key': _keyId, // Using the key defined above
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Veena Public School',
      'description': 'Fee Payment',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': contact, 'email': email},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      _onResult?.call(false, "Initialization failed: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("Payment Success: ${response.paymentId}");
    if (_currentFeeId != null) {
      // Update Fee Status in Firestore
      try {
        // Fetch current fee status to get previously paid amount
        final feeSnapshot = await FirebaseFirestore.instance.collection('fees').doc(_currentFeeId).get();
        double previousPaid = 0.0;
        if (feeSnapshot.exists) {
          previousPaid = (feeSnapshot.data()?['paidAmount'] as num?)?.toDouble() ?? 0.0;
        }

        // Calculate new total paid amount
        // FeeService.updatePayment calculates diff = (new - old), so we must pass (old + current)
        double newTotalPaid = previousPaid + (_currentAmount ?? 0.0);

        await _feeService.updatePayment(_currentFeeId!, newTotalPaid);
        _onResult?.call(true, "Payment Successful: ${response.paymentId}");
      } catch (e) {
        _onResult?.call(false, "Payment succeeded but update failed: $e");
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Error: ${response.code} - ${response.message}");
    _onResult?.call(false, "Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
    _onResult?.call(false, "External Wallet Selected: ${response.walletName}"); // Handle as needed
  }
}
