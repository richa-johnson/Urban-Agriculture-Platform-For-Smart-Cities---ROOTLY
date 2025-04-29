import 'package:flutter/material.dart';
import 'package:rootly/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // For generating random payment ID

class PaymentScreen extends StatefulWidget {
  final String farmerEmail;
  final double totalAmount;

  const PaymentScreen({
    Key? key,
    required this.farmerEmail,
    required this.totalAmount,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  String _selectedPaymentMethod = "COD"; // Default method
  bool _isUpiValid = false; // Flag for UPI validation

  void _validateUpi(String upi) {
    // Simple UPI validation regex
    final RegExp upiRegex = RegExp(r"^[\w.-]+@[\w]+$");
    setState(() {
      _isUpiValid = upiRegex.hasMatch(upi);
    });
  }

  void _sendUpiRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("UPI Request Sent to ${_upiController.text}")),
    );
  }

  Future<void> savePaymentToFirestore(
    String farmerEmail,
    String address,
    String paymentMethod,
    double amountPaid, {
    String? upiId,
  }) async {
    try {
      // Generate a random Payment ID
      String paymentId = "PAY${Random().nextInt(1000000)}";

      // Get Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Reference to user's payment collection
      DocumentReference userDoc = firestore
          .collection("Farmers")
          .doc(farmerEmail);

      // Store payment details in a subcollection "Transactions"
      await userDoc.collection("Transactions").doc(paymentId).set({
        "paymentId": paymentId,
        "address": address,
        "paymentMethod": paymentMethod,
        "upiId": paymentMethod == "UPI" ? upiId : "COD",
        "amountPaid": amountPaid,
        "timestamp": FieldValue.serverTimestamp(),
      });

      print("Payment successfully saved with ID: $paymentId");
    } catch (e) {
      print("Error saving payment: $e");
    }
  }

  void _showConfirmOrderDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Confirm Order"),
            content: Text("Are you sure you want to place this order?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                },
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await savePaymentToFirestore(
                    widget.farmerEmail,
                    _addressController.text,
                    _selectedPaymentMethod,
                    widget.totalAmount,
                    upiId:
                        _selectedPaymentMethod == "UPI"
                            ? _upiController.text
                            : null,
                  ); // Close dialog first
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignUpPage(),
                    ), // Navigate to Purchase screen
                  );
                },
                child: Text("Confirm"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Gradient extends behind appbar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50,
        title: Text("Payment"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF56B686), Color(0xFF045D56)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          // Prevents content from overlapping app bar
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Farmer Email: ${widget.farmerEmail}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "Total Amount: ₹${widget.totalAmount.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),

                // Delivery Address Input
                Text("Delivery Address:", style: TextStyle(fontSize: 16)),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: "Enter delivery address",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),

                // Payment Methods Section
                Text("Payment Methods:", style: TextStyle(fontSize: 16)),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedPaymentMethod = "UPI";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _selectedPaymentMethod == "UPI"
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                        child: Text("UPI Payment"),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedPaymentMethod = "Cash On Delivery";
                          });
                          _showConfirmOrderDialog(); // Show confirmation dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _selectedPaymentMethod == "Cash On Delivery"
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                        child: Text("Cash on Delivery"),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // UPI Payment TextField
                if (_selectedPaymentMethod == "UPI")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Enter UPI Address:",
                        style: TextStyle(fontSize: 16),
                      ),
                      TextField(
                        controller: _upiController,
                        decoration: InputDecoration(
                          hintText: "example@upi",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _validateUpi,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isUpiValid ? _sendUpiRequest : null,
                        child: Text("OK"),
                      ),
                    ],
                  ),

                Spacer(),

                // Confirm Payment Button
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await savePaymentToFirestore(
                        widget.farmerEmail,
                        _addressController.text,
                        _selectedPaymentMethod,
                        widget.totalAmount,
                        upiId:
                            _selectedPaymentMethod == "UPI"
                                ? _upiController.text
                                : null,
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      "Confirm Payment",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
