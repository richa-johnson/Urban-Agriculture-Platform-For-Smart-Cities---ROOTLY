import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rootly/screens/fetch.dart';

class CaterersAndTransactionsScreen extends StatefulWidget {
  final String userEmail;

  const CaterersAndTransactionsScreen({Key? key, required this.userEmail})
    : super(key: key);

  @override
  _CaterersAndTransactionsScreenState createState() =>
      _CaterersAndTransactionsScreenState();
}

class _CaterersAndTransactionsScreenState
    extends State<CaterersAndTransactionsScreen> {
  String? userPincode;
  String? farmerDocId;

  @override
  void initState() {
    super.initState();
    _fetchFarmerDetails();
  }

  void _fetchFarmerDetails() async {
    try {
      String? userEmail = FirebaseAuth.instance.currentUser?.email;

      if (userEmail != null) {
        var querySnapshot =
            await FirebaseFirestore.instance
                .collection('Farmers')
                .where('Email', isEqualTo: userEmail)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          var farmerData = querySnapshot.docs.first.data();
          String pincode = farmerData['Pincode'];
          String farmerId = querySnapshot.docs.first.id;

          setState(() {
            userPincode = pincode;
            farmerDocId = farmerId;
          });

          print("Fetched Pincode: $pincode");
          print("Fetched Farmer Document ID: $farmerId");
        } else {
          print("No document found for the given email.");
        }
      } else {
        print("User email is null.");
      }
    } catch (e) {
      print("Error fetching farmer details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF56B686), Color(0xFF045D56)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                SizedBox(height: 20),
                ElevatedButton(
                  style: _buttonStyle(),
                  onPressed: () {
                    if (userPincode != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  FetchScreen(),
                        ),
                      );
                    } else {
                      print("Pincode not available.");
                    }
                  },
                  child: Text("Show Caterers", style: _buttonTextStyle()),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  style: _buttonStyle(),
                  onPressed: () {
                    if (widget.userEmail.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  TransactionsScreen(email: widget.userEmail),
                        ),
                      );
                    } else {
                      print("User email is null.");
                    }
                  },
                  child: Text("Show Transactions", style: _buttonTextStyle()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Text(
        "Caterers & Transactions",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  TextStyle _buttonTextStyle() {
    return TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  }
}

class CatererSelectionScreen extends StatefulWidget {
  final String pincode;

  const CatererSelectionScreen({Key? key, required this.pincode})
    : super(key: key);

  @override
  _CatererSelectionScreenState createState() => _CatererSelectionScreenState();
}

class _CatererSelectionScreenState extends State<CatererSelectionScreen> {
  List<Map<String, dynamic>> caterers = [];
  String? userEmail;
  Map<String, dynamic>? userData;
  String? userDocumentId;
  String? userCollection;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 🔹 Fetch caterers with same pincode & check if they have "Products" collection
  Future<void> _fetchUserData() async {
    try {
      var catererSnapshot =
          await FirebaseFirestore.instance
              .collection('Caterers')
              .where('Email', isEqualTo: userEmail)
              .get();

      if (catererSnapshot.docs.isNotEmpty) {
        setState(() {
          userData = catererSnapshot.docs.first.data();
          userDocumentId = catererSnapshot.docs.first.id;
          userCollection = 'Caterers';
        });
        return;
      }

      setState(() => userData = null);
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => userData = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select a Caterer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            caterers.isEmpty
                ? Center(child: Text("No caterers found."))
                : ListView.builder(
                  itemCount: caterers.length,
                  itemBuilder: (context, index) {
                    var caterer = caterers[index];

                    return Dismissible(
                      key: Key(caterer['email']), // Unique key for swipe action
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        print(
                          "Caterer Email: ${caterer['email']}",
                        ); // Debug print
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Caterer Email: ${caterer['email']}"),
                          ),
                        );
                      },
                      background: Container(
                        color: const Color.fromARGB(255, 144, 188, 120),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.email, color: Colors.white),
                      ),
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                            caterer['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Swipe to reveal email"),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            print(
                              "Tapped Caterer Email: ${caterer['email']}",
                            ); // Debug
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Email: ${caterer['email']}"),
                              ),
                            );

                            // Navigate to Caterers Screen with selected caterer's email
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CaterersScreen(
                                      pincode: widget.pincode,
                                      catererEmail: caterer['email'],
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

class CaterersScreen extends StatefulWidget {
  final String pincode;
  final String catererEmail;

  const CaterersScreen({
    Key? key,
    required this.pincode,
    required this.catererEmail,
  }) : super(key: key);

  @override
  _CaterersScreenState createState() => _CaterersScreenState();
}

class _CaterersScreenState extends State<CaterersScreen> {
  List<Map<String, dynamic>> caterers = [];
  Map<String, dynamic>? farmerDetails;

  @override
  void initState() {
    super.initState();
    fetchCaterers();
  }

  // ✅ Fetch Caterers & Their Products
   Future<void> fetchCaterers() async {
    var matchedCaterers=[];
    var isLoading;
    try {
      String? userEmail = "richamariajohnson@gmail.com";
      print("User email: $userEmail");

      // Attempt to fetch user as a Caterer
      print("Fetching caterer with email: $userEmail");
      var catererSnapshot = await FirebaseFirestore.instance
          .collection('Caterers')
          .where('Email', isEqualTo: userEmail)
          .get();
      print("Caterer snapshot count: ${catererSnapshot.docs.length}");

      if (catererSnapshot.docs.isNotEmpty) {
        var catererDoc = catererSnapshot.docs.first;
        print("Caterer document found with ID: ${catererDoc.id}");
        // Check if this caterer has a non-empty Product subcollection
        var productSnapshot = await FirebaseFirestore.instance
            .collection('Caterers')
            .doc(catererDoc.id)
            .collection('Product')
            .get();
        print("Product snapshot count for caterer ${catererDoc.id}: ${productSnapshot.docs.length}");

        if (productSnapshot.docs.isNotEmpty) {
          print("Valid caterer found with non-empty Product collection.");
          setState(() {
            matchedCaterers = []; // Clearing matchedCaterers if the user is a valid caterer.
            isLoading = false;
          });
          return;
        } else {
          print("Caterer found but no products available.");
        }
      } else {
        print("No caterer document found for this email.");
      }

      // If the user is not a valid Caterer, check if they are a Farmer
      print("Fetching farmer with email: $userEmail");
      var farmerSnapshot = await FirebaseFirestore.instance
          .collection('Farmers')
          .where('Email', isEqualTo: userEmail)
          .get();
      print("Farmer snapshot count: ${farmerSnapshot.docs.length}");

      if (farmerSnapshot.docs.isNotEmpty) {
        var farmerDoc = farmerSnapshot.docs.first;
        var farmerData = farmerDoc.data();
        String pincode = farmerData['Pincode'];
        print("Farmer found. Pincode: $pincode");

        // Query Caterers matching the farmer's pincode
        print("Fetching caterers with pincode: $pincode");
        var caterersQuerySnapshot = await FirebaseFirestore.instance
            .collection('Caterers')
            .where('Pincode', isEqualTo: pincode)
            .get();
        print("Caterers with matching pincode count: ${caterersQuerySnapshot.docs.length}");

        List<Map<String, dynamic>> tempMatchedCaterers = [];

        // Iterate over each caterer and verify they have products
        for (var caterer in caterersQuerySnapshot.docs) {
          print("Checking products for caterer with ID: ${caterer.id}");
          var productSnapshot = await FirebaseFirestore.instance
              .collection('Caterers')
              .doc(caterer.id)
              .collection('Products')
              .get();
          print("Product count for caterer ${caterer.id}: ${productSnapshot.docs.length}");
          if (productSnapshot.docs.isNotEmpty) {
            tempMatchedCaterers.add({
              'id': caterer.id,
              'data': caterer.data(),
            });
            print("Added caterer ${caterer.id} to matched list.");
          }
        }

        print("Total matched caterers found: ${tempMatchedCaterers.length}");
        setState(() {
          matchedCaterers = tempMatchedCaterers;
          isLoading = false;
        });
      } else {
        print("No farmer document found for this email.");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
    var caterer;
    var data = caterer['data'] as Map<String, dynamic>;
    print(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF56B686), Color(0xFF045D56)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Farmer Details Section
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Farmer Details",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Name: ${farmerDetails?['Name'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        "Email: ${farmerDetails?['Email'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        "Pincode: ${farmerDetails?['Pincode'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // ✅ Caterers Table
                Expanded(
                  child:
                      caterers.isEmpty
                          ? Center(
                            child: Text(
                              "No caterers found.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          )
                          : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                columnSpacing: 20.0,
                                headingRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.white.withOpacity(0.2),
                                ),
                                dataRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.white.withOpacity(0.1),
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Item Name',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Cost',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Amount',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Date Updated',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                                rows:
                                    caterers.map((caterer) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              caterer['name'] ?? 'N/A',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "₹${caterer['cost']}",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              caterer['amount'].toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              caterer['dateUpdated'] ?? 'N/A',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
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

class TransactionsScreen extends StatefulWidget {
  final String email;

  const TransactionsScreen({Key? key, required this.email}) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    fetchTransactions(widget.email);
  }

  void fetchTransactions(String email) async {
    try {
      var querySnapshot =
          await FirebaseFirestore.instance
              .collection('Farmers')
              .where('Email', isEqualTo: email)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        String farmerDocId = querySnapshot.docs.first.id;

        var transactionsSnapshot =
            await FirebaseFirestore.instance
                .collection('Farmers')
                .doc(farmerDocId)
                .collection('Transactions')
                .get();

        setState(() {
          transactions =
              transactionsSnapshot.docs.map((doc) => doc.data()).toList();
        });
      } else {
        print("No document found for the given email.");
      }
    } catch (e) {
      print("Error fetching transactions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF56B686), Color(0xFF045D56)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Custom Header
                Text(
                  "Transactions",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),

                // Transactions Table
                Expanded(
                  child:
                      transactions.isEmpty
                          ? Center(
                            child: Text(
                              "No transactions found.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          )
                          : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                columnSpacing: 20.0,
                                headingRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.white.withOpacity(0.2),
                                ),
                                dataRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.white.withOpacity(0.1),
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Address',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Paid Amount',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Payment ID',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Payment Method',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  // DataColumn(
                                  //   label: Text(
                                  //     'Time',
                                  //     style: TextStyle(color: Colors.white),
                                  //   ),
                                  // ),
                                  DataColumn(
                                    label: Text(
                                      'UPI ID',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                                rows:
                                    transactions.map((transactions) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              transactions['address'] ?? 'N/A',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "₹${transactions['amountPaid']}",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              transactions['paymentId'] ?? 'N/A',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              transactions['paymentMethod'] ??
                                                  'Unknown',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          // DataCell(
                                          //   Text(
                                          //     transaction['time'] ?? 'N/A',
                                          //     style: TextStyle(
                                          //       color: Colors.white,
                                          //     ),
                                          //   ),
                                          // ),
                                          DataCell(
                                            Text(
                                              transactions['upiId'] ?? 'N/A',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
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
