import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rootly/screens/payment.dart';
import 'package:google_fonts/google_fonts.dart';

class Purchase extends StatefulWidget {
  const Purchase({super.key});

  @override
  _PurchaseState createState() => _PurchaseState();
}

class _PurchaseState extends State<Purchase> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationDialog();
    });
  }

  void _showLocationDialog() {
    TextEditingController pincodeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text("Location Access"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Enter your pincode to allow access:"),
                SizedBox(height: 10),
                TextField(
                  controller: pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter Pincode",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Deny"),
              ),
              TextButton(
                onPressed: () {
                  if (pincodeController.text.isNotEmpty) {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => FarmerListScreen(
                              pincode: pincodeController.text,
                            ),
                      ),
                    );
                  }
                },
                child: Text("Allow"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF56B686), Color(0xFF045D56)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Location Permission',
                  style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Checking location permission...",
                  style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FarmerListScreen extends StatefulWidget {
  final String pincode;
  const FarmerListScreen({super.key, required this.pincode});

  @override
  _FarmerListScreenState createState() => _FarmerListScreenState();
}

class _FarmerListScreenState extends State<FarmerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _farmers = [];
  List<Map<String, String>> _filteredFarmers = [];

  @override
  void initState() {
    super.initState();
    _fetchFarmersByPincode();
  }

  void _fetchFarmersByPincode() async {
    if (widget.pincode.isEmpty) {
      print("Pincode is null, aborting fetch.");
      return;
    }

    print("Fetching farmers for pincode: ${widget.pincode}");

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('Farmers')
              .where('Pincode', isEqualTo: widget.pincode)
              .get();

      if (querySnapshot.docs.isEmpty) {
        print("No farmers found for pincode ${widget.pincode}.");
      } else {
        print("Farmers found: ${querySnapshot.docs.length}");
      }

      List<Map<String, String>> fetchedFarmers =
          querySnapshot.docs.map((doc) {
            print("Farmer Data: ${doc.data()}");
            return {
              "name": doc["Username"]?.toString() ?? "Unknown",
              "email": doc["Email"]?.toString() ?? "No Email",
              "pincode": doc["Pincode"]?.toString() ?? "N/A",
            };
          }).toList();

      setState(() {
        _farmers = fetchedFarmers;
        _filteredFarmers = List.from(fetchedFarmers);
      });
    } catch (e) {
      print("Error fetching farmers: $e");
    }
  }

  void _filterFarmers(String query) async {
    print(query);
    if (query.isEmpty) {
      setState(() {
        _filteredFarmers = List.from(_farmers);
      });
      return;
    }

    // Filter by name/email
    List<Map<String, String>> filteredByName =
        _farmers.where((farmer) {
          return farmer["name"]!.toLowerCase().contains(query.toLowerCase()) ||
              farmer["email"]!.toLowerCase().contains(query.toLowerCase());
        }).toList();

    // Collect farmers with matching products
    List<Map<String, String>> filteredByProduct = [];

    for (var farmer in _farmers) {
      try {
        QuerySnapshot<Map<String, dynamic>> productSnapshot =
            await FirebaseFirestore.instance
                .collection('Farmers')
                .doc(farmer["email"]) // ✅ Access the farmer's document
                .collection('Products') // ✅ Search inside the subcollection
                .where('Item', isGreaterThanOrEqualTo: query)
                .where('Item', isLessThan: query + '\uf8ff')
                .get();

        if (productSnapshot.docs.isNotEmpty) {
          print("Farmer ${farmer["name"]} has the product: $query");
          filteredByProduct.add(farmer);
        } else {
          print("Kanaran");
        }
      } catch (e) {
        print("Error fetching products for ${farmer["email"]}: $e");
      }
    }

    // Combine results and remove duplicates
    setState(() {
      _filteredFarmers = {...filteredByName, ...filteredByProduct}.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Keeps the gradient behind the app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50,
        title: Text("Select Farmer"),
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
          // Prevents overlap with the AppBar
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: "Search Product",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_searchcontroller) {
                    _filterFarmers(_searchController.text.toLowerCase().trim());
                  },
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredFarmers.length,
                    itemBuilder: (context, index) {
                      var farmer = _filteredFarmers[index];
                      return Card(
                        child: ListTile(
                          title: Text(farmer["name"]!),
                          subtitle: Text("Email: ${farmer["email"]!}"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        PurchaseScreen(email: farmer["email"]!),
                              ),
                            );
                          },
                        ),
                      );
                    },
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

class PurchaseScreen extends StatefulWidget {
  final String email;

  const PurchaseScreen({super.key, required this.email});

  @override
  _PurchaseScreenState createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _products = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      print("Fetching products for: ${widget.email}");

      DocumentReference farmerDocRef = _firestore
          .collection('Farmers')
          .doc(widget.email);
      QuerySnapshot productSnapshot =
          await farmerDocRef.collection('Products').get();

      List<Map<String, dynamic>> fetchedProducts =
          productSnapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;

            return {
              "item": data["Item"] ?? "Unnamed", // Product name
              "cost":
                  double.tryParse(data["Cost"].toString()) ??
                  0.0, // Safe conversion
              "weight":
                  double.tryParse(data["Weight"].toString()) ??
                  0.0, // Safe conversion
              "controller":
                  TextEditingController(), // Unique controller per row
              "total": 0.0, // Store calculated total price
            };
          }).toList();

      setState(() {
        _products = fetchedProducts;
      });

      print("Fetched ${_products.length} products for farmer: ${widget.email}");
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  Future<void> _confirmPurchase() async {
    try {
      for (var product in _products) {
        double purchaseWeight =
            double.tryParse(product["controller"].text) ?? 0.0;
        if (purchaseWeight > 0 && purchaseWeight <= product["weight"]) {
          double newWeight = product["weight"] - purchaseWeight;

          // Update Firestore
          DocumentReference productDocRef = _firestore
              .collection('Farmers')
              .doc(widget.email)
              .collection('Products')
              .doc(
                product["item"],
              ); // Assuming item name is unique; else use an ID

          await productDocRef.update({"Weight": newWeight});
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Purchase confirmed! Stock updated.")),
      );

      _fetchProducts(); // Refresh product list after update
    } catch (e) {
      print("Error updating weight: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating stock.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50,
        title: Text(
          "Purchase from ${widget.email}",
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF56B686), Color(0xFF045D56)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                _products.isEmpty
                    ? const Center(
                      child: CircularProgressIndicator(),
                    ) // Show loading indicator
                    : Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 16,
                            dataRowHeight: 60,
                            headingTextStyle: GoogleFonts.raleway(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            dataTextStyle: GoogleFonts.raleway(
                              color: Colors.white, // All text white
                            ),
                            border: TableBorder.all(
                              color: Colors.white.withOpacity(
                                0.5,
                              ), // Light border
                            ),
                            columns: const [
                              DataColumn(label: Text("Item")),
                              DataColumn(label: Text("Cost (₹/kg)")),
                              DataColumn(label: Text("Available (kg)")),
                              DataColumn(label: Text("Purchase (kg)")),
                              DataColumn(label: Text("Total Price")),
                            ],
                            rows:
                                _products.map((product) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(product["item"])),
                                      DataCell(
                                        Text(
                                          "₹${product["cost"].toStringAsFixed(2)}",
                                        ),
                                      ),
                                      DataCell(Text("${product["weight"]} kg")),
                                      DataCell(
                                        TextField(
                                          controller: product["controller"],
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: "Enter weight",
                                            hintStyle: TextStyle(
                                              color: Colors.white70,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          onChanged:
                                              (value) => _calculateTotal(),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          "₹${product["total"].toStringAsFixed(2)}",
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Total Amount: ₹${_totalAmount.toStringAsFixed(2)}",
                          style: GoogleFonts.raleway(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await _confirmPurchase();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PaymentScreen(
                                      farmerEmail: widget.email,
                                      totalAmount: _totalAmount,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Confirm Purchase",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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

  /// This function calculates the total for each row and updates `_totalAmount`
  void _calculateTotal() {
    double total = 0.0;

    setState(() {
      for (var product in _products) {
        double purchaseWeight =
            double.tryParse(product["controller"].text) ?? 0.0;
        product["total"] = product["cost"] * purchaseWeight;
        total += product["total"]; // Sum up the total price
      }

      _totalAmount = total;
    });
  }
}
