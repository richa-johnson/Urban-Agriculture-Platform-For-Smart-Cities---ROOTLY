import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FetchScreen extends StatefulWidget {
  const FetchScreen({super.key});

  @override
  _FetchScreenState createState() => _FetchScreenState();
}

class _FetchScreenState extends State<FetchScreen> {
  List<Map<String, dynamic>> matchedCaterers = [];
  bool isLoading = true;

  Future<void> _fetchUserData() async {
    try {
      String? userEmail = "richamariajohnson@gmail.com";
      print("User email: $userEmail");

      // Attempt to fetch user as a Caterer
      print("Fetching caterer with email: $userEmail");
      var catererSnapshot =
          await FirebaseFirestore.instance
              .collection('Caterers')
              .where('Email', isEqualTo: userEmail)
              .get();
      print("Caterer snapshot count: ${catererSnapshot.docs.length}");

      if (catererSnapshot.docs.isNotEmpty) {
        var catererDoc = catererSnapshot.docs.first;
        print("Caterer document found with ID: ${catererDoc.id}");
        // Check if this caterer has a non-empty Product subcollection
        var productSnapshot =
            await FirebaseFirestore.instance
                .collection('Caterers')
                .doc(catererDoc.id)
                .collection('Products')
                .get();
        print(
          "Product snapshot count for caterer ${catererDoc.id}: ${productSnapshot.docs.length}",
        );

        if (productSnapshot.docs.isNotEmpty) {
          print("Valid caterer found with non-empty Product collection.");
          setState(() {
            matchedCaterers =
                []; // Clearing matchedCaterers if the user is a valid caterer.
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
      var farmerSnapshot =
          await FirebaseFirestore.instance
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
        var caterersQuerySnapshot =
            await FirebaseFirestore.instance
                .collection('Caterers')
                .where('Pincode', isEqualTo: pincode)
                .get();
        print(
          "Caterers with matching pincode count: ${caterersQuerySnapshot.docs.length}",
        );

        List<Map<String, dynamic>> tempMatchedCaterers = [];

        // Iterate over each caterer and verify they have products
        for (var caterer in caterersQuerySnapshot.docs) {
          print("Checking products for caterer with ID: ${caterer.id}");
          var productSnapshot =
              await FirebaseFirestore.instance
                  .collection('Caterers')
                  .doc(caterer.id)
                  .collection('Products')
                  .get();
          print(
            "Product count for caterer ${caterer.id}: ${productSnapshot.docs.length}",
          );
          if (productSnapshot.docs.isNotEmpty) {
            tempMatchedCaterers.add({'id': caterer.id, 'data': caterer.data()});
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
  }

  @override
  void initState() {
    super.initState();
    print("Initializing FetchScreen and fetching user data...");
    _fetchUserData();
  }

  Widget _buildCatererItem(Map<String, dynamic> caterer) {
    var data = caterer['data'] as Map<String, dynamic>;
    print("Building list item for caterer: ${caterer['id']}");
    return ListTile(
      title: Text(data['Username'] ?? 'No Name'),
      subtitle: Text(
        'Email: ${data['Email'] ?? ''}\nPhone: ${data['Phone Number'] ?? ''}',
      ),
      onTap: () {
        print("Tapped on caterer: ${caterer['id']}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ProductDetailsScreen(catererId: caterer['id']),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
      "Building UI. isLoading: $isLoading, matchedCaterers count: ${matchedCaterers.length}",
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Matched Caterers')),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : matchedCaterers.isEmpty
                ? const Center(child: Text('No matched caterers found.'))
                : ListView.builder(
                  itemCount: matchedCaterers.length,
                  itemBuilder:
                      (context, index) =>
                          _buildCatererItem(matchedCaterers[index]),
                ),
      ),
    );
  }
}

class ProductDetailsScreen extends StatelessWidget {
  final String catererId;

  const ProductDetailsScreen({super.key, required this.catererId});

  @override
  Widget build(BuildContext context) {
    print("Fetching products for caterer: $catererId");
    CollectionReference productsRef = FirebaseFirestore.instance
        .collection('Caterers')
        .doc(catererId)
        .collection('Products');

    return Scaffold(
      appBar: AppBar(title: const Text("Products")),
      body: FutureBuilder<QuerySnapshot>(
        future: productsRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("Loading products...");
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error loading products: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print("No products found for caterer: $catererId");
            return const Center(child: Text("No products found."));
          }

          List<DocumentSnapshot> products = snapshot.data!.docs;
          print("Total products found: ${products.length}");
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              var productData = products[index].data() as Map<String, dynamic>;
              String itemName = productData["Item"] ?? "No item";
              String weight = productData["Weight"]?.toString() ?? "No weight";
              String cost = productData["Cost"]?.toString() ?? "No cost";
              print(
                "Displaying product: $itemName, Weight: $weight, Cost: $cost",
              );
              return ListTile(
                title: Text(itemName),
                subtitle: Text(
                  "Weight: $weight, Cost: $cost , Date ${productData["Date"]}",
                ),
              );
            },
          );
        },
      ),
    );
  }
}
