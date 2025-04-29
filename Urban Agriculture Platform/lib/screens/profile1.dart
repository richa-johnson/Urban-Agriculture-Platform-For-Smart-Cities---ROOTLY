import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rootly/screens/profile.dart';
import 'package:rootly/screens/signin.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  List<Map<String, String>> items = [];
  int? editingIndex;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userEmail;
  Map<String, dynamic>? userData;
  String? userDocumentId;
  String? userCollection;
  Map<String, List<Map<String, dynamic>>> itemsByDate = {};
  bool hasNewNotification = false; // Tracks notification state

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _fetchUserEmail();
  }

  //Fetch useremail while taken at login
  Future<void> _fetchUserEmail() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() => userEmail = user.email);
      await _fetchUserData();
      await _fetchUserItems();
    }
  }

  //fetch the userdata using the email
  Future<void> _fetchUserData() async {
    try {
      var farmerSnapshot =
          await FirebaseFirestore.instance
              .collection('Farmers')
              .where('Email', isEqualTo: userEmail)
              .get();

      if (farmerSnapshot.docs.isNotEmpty) {
        setState(() {
          userData = farmerSnapshot.docs.first.data();
          userDocumentId = farmerSnapshot.docs.first.id;
          userCollection = 'Farmers';
        });
        return;
      }

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

  //Add Product details to the firestore for the logged in user
  Future<void> _addItemToUserDocument() async {
    if (userDocumentId == null || userCollection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User data not found for adding items")),
      );
      return;
    }

    String itemName = itemController.text.trim();
    if (itemName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please provide a valid item name")),
      );
      return;
    }

    Map<String, dynamic> itemData = {
      'Item': itemController.text.trim(),
      'Weight': weightController.text.trim(),
      'Cost': costController.text.trim(),
      'Date': dateController.text.trim(),
    };

    try {
      await FirebaseFirestore.instance
          .collection(userCollection!)
          .doc(userDocumentId)
          .collection('Products')
          .doc(itemName) // Use item name as document name
          .set(itemData);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Item added successfully!")));

      // Clear controllers after successful submission
      itemController.clear();
      weightController.clear();
      costController.clear();
      dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    } catch (e) {
      print("Failed to add item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add item. Please try again.")),
      );
    }
  }

  //Fetch the user items from firestore to print
  Future<void> _fetchUserItems() async {
    if (userDocumentId == null || userCollection == null) {
      print("User data is not available for fetching items.");
      return;
    }

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection(userCollection!)
              .doc(userDocumentId)
              .collection('Products')
              .get();

      List<Map<String, String>> fetchedItems = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          Map<String, String> stringData = data.map(
            (key, value) => MapEntry(key, value?.toString() ?? ''),
          );
          fetchedItems.add(stringData);
        }
      }

      setState(() {
        items = fetchedItems; // Ensure correct data type
      });

      print("Fetched items: $items");
    } catch (e) {
      print("Error fetching items: $e");
    }
  }

  void _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  void _editItem(int index) {
    setState(() {
      editingIndex = index; // Store index of the row being edited
      itemController.text = items[index]['Item'] ?? '';
      weightController.text = items[index]['Weight']?.toString() ?? '';
      costController.text = items[index]['Cost']?.toString() ?? '';
      dateController.text = items[index]['Date'] ?? '';
    });
  }

  //on button click the item is either added or updated in the firestore
  void _addOrUpdateItem() {
    String item = itemController.text.trim();
    String weight = weightController.text.trim();
    String cost = costController.text.trim();
    String date = dateController.text.trim();

    if (item.isEmpty || weight.isEmpty || cost.isEmpty || date.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("All fields must be filled")));
      return;
    }

    if (editingIndex == null) {
      // Call Firestore function to add the item
      _addItemToUserDocument().then((_) {
        _fetchUserItems();
      });
    } else {
      // Update Firestore and local list for editing
      String docId = items[editingIndex!]['Item'] ?? '';
      if (docId.isNotEmpty) {
        _updateItemInFirestore(docId, {
          'Item': item,
          'Weight': weight,
          'Cost': cost,
          'Date': date,
        });
      }
    }
  }

  //For firestore data updation
  Future<void> _updateItemInFirestore(
    String documentId,
    Map<String, dynamic> updatedData,
  ) async {
    if (userDocumentId == null || userCollection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User data not found for updating items")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(userCollection!)
          .doc(userDocumentId)
          .collection('Products')
          .doc(documentId)
          .update(updatedData);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Item updated successfully!")));

      // Refresh items list
      _fetchUserItems();

      // Clear inputs
      setState(() {
        editingIndex = null;
        itemController.clear();
        weightController.clear();
        costController.clear();
        dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      });
    } catch (e) {
      print("Failed to update item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update item. Please try again.")),
      );
    }
  }

  //To delete an item from the firestore
  Future<void> _deleteItemFromFirestore(String itemName) async {
    if (userDocumentId == null || userCollection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User data not found for deleting items")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(userCollection!)
          .doc(userDocumentId)
          .collection('Products')
          .doc(itemName)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Item deleted successfully!")));
    } catch (e) {
      print("Failed to delete item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete item. Please try again.")),
      );
    }
  }

  void _deleteItem(int index) async {
    String? itemName = items[index]['Item'];

    if (itemName != null) {
      await _deleteItemFromFirestore(
        itemName,
      ); // Ensure Firestore deletion happens first
    }

    setState(() {
      items.removeAt(index);
    });
  }

  //To delete the account
  Future<void> _confirmDeleteAccount() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Account"),
          content: Text(
            "Are you sure you want to permanently delete your account?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (userDocumentId == null || userCollection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User data not found for deletion")),
      );
      return;
    }

    try {
      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection(userCollection!)
          .doc(userDocumentId)
          .delete();

      // Delete user from Firebase Authentication
      await _auth.currentUser?.delete();

      // Sign out and redirect to Login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Account deleted successfully")));
    } catch (e) {
      print("Failed to delete account: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete account. Try again.")),
      );
    }
  }

  //to signout from the current account
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
      // Redirect to login page
    } catch (e) {
      print("Sign out failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to sign out. Please try again.")),
      );
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
                _buildHeader(),
                SizedBox(height: 20),
                _buildInputField("Item", itemController),
                _buildInputField("Weight", weightController, isNumeric: true),
                _buildInputField("Cost", costController, isNumeric: true),
                _buildDatePickerField("Date", dateController, context),
                SizedBox(height: 15),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _addOrUpdateItem,
                    child: Text(
                      editingIndex == null ? "Add Item" : "Update Item",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Expanded(child: _buildDataTable()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 28, color: Colors.black),
              ),
              SizedBox(width: 10),
              Text(
                "Hello",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CaterersAndTransactionsScreen(
                            userEmail:
                                FirebaseAuth.instance.currentUser?.email ?? '',
                          ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.white,
                ), // Delete Account Icon
                onPressed: () async {
                  await _confirmDeleteAccount();
                },
              ),
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                onPressed: _signOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withOpacity(0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(
    String label,
    TextEditingController controller,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(Icons.calendar_today, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    // Flatten the itemsByDate map into a single list
    List<Map<String, dynamic>> allItems = [];
    itemsByDate.forEach((date, itemList) {
      for (var item in itemList) {
        allItems.add({
          'item': item['Item'] ?? '',
          'weight': item['Weight'] ?? '',
          'cost': item['Cost'] ?? '',
          'date': date, // Store date separately
        });
      }
    });

    return Expanded(
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columnSpacing: 40,
                  headingRowHeight: 50,
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                    bottom: BorderSide(color: Colors.grey.shade600, width: 1.5),
                  ),
                  headingRowColor: WidgetStateProperty.resolveWith(
                    (states) => Colors.teal.shade300,
                  ),
                  columns: [
                    _buildColumnHeader("Item"),
                    _buildColumnHeader("Weight"),
                    _buildColumnHeader("Cost"),
                    _buildColumnHeader("Date"),
                    _buildColumnHeader("Actions"),
                  ],
                  rows: List.generate(items.length, (index) {
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>((states) {
                        return index.isEven
                            ? const Color.fromARGB(
                              255,
                              93,
                              191,
                              132,
                            ).withOpacity(0.3)
                            : Colors.white.withOpacity(0.3);
                      }),
                      cells: [
                        DataCell(
                          Text(
                            items[index]['Item'] ?? 'N/A',
                            style: _cellTextStyle(),
                          ),
                        ),
                        DataCell(
                          Text(
                            items[index]['Weight']?.toString() ?? 'N/A',
                            style: _cellTextStyle(),
                          ),
                        ),
                        DataCell(
                          Text(
                            items[index]['Cost']?.toString() ?? 'N/A',
                            style: _cellTextStyle(),
                          ),
                        ),
                        DataCell(
                          Text(
                            items[index]['Date'] ?? 'N/A',
                            style: _cellTextStyle(),
                          ),
                        ),
                        DataCell(_buildActionButtons(index)),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataColumn _buildColumnHeader(String title) {
    return DataColumn(
      label: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  TextStyle _cellTextStyle() {
    return TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  }

  Widget _buildActionButtons(int index) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.edit,
            color: const Color.fromARGB(255, 211, 202, 70),
          ),
          onPressed: () => _editItem(index),
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteItem(index),
        ),
      ],
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? userEmail;
  Map<String, dynamic>? userData;
  String? userDocumentId;
  String? userCollection;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  Future<void> _fetchUserEmail() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() => userEmail = user.email);
      await _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      var farmerSnapshot =
          await FirebaseFirestore.instance
              .collection('Farmers')
              .where('Email', isEqualTo: userEmail)
              .get();

      if (farmerSnapshot.docs.isNotEmpty) {
        setState(() {
          userData = farmerSnapshot.docs.first.data();
          userDocumentId = farmerSnapshot.docs.first.id;
          userCollection = 'Farmers';
        });
        return;
      }

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

  Future<void> _updateUserProfile() async {
    if (userDocumentId == null || userCollection == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("User data not found for update")));
      return;
    }

    Map<String, dynamic> updatedData = {
      'Username':
          _usernameController.text.trim().isNotEmpty
              ? _usernameController.text.trim()
              : userData?['Username'] ?? '',
      'Email':
          _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : userData?['Email'] ?? '',
      'Password':
          _passwordController.text.trim().isNotEmpty
              ? _passwordController.text.trim()
              : userData?['Password'] ?? '',
      'Phone Number':
          _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : userData?['Phone Number'] ?? '',
      'Pincode':
          _pincodeController.text.trim().isNotEmpty
              ? _pincodeController.text.trim()
              : userData?['Pincode'] ?? '',
    };

    try {
      await FirebaseFirestore.instance
          .collection(userCollection!)
          .doc(userDocumentId)
          .update(updatedData);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Profile updated successfully!")));

      // Refresh user data after update
      await _fetchUserData();
    } catch (e) {
      print("Failed to update profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile. Please try again.")),
      );
    }
  }

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF56B686), Color(0xFF045D56)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF56B686), Color.fromARGB(255, 70, 219, 176)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "Username",
                hintText: "${userData?['Username'] ?? 'Enter your username'}",
              ),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                hintText: "${userData?['Email'] ?? 'Enter your email'}",
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                hintText: "${userData?['Password'] ?? 'Enter your password'}",
              ),
              obscureText: true,
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "Phone Number",
                hintText:
                    "${userData?['Phone Number'] ?? 'Enter your phone number'}",
              ),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _pincodeController,
              decoration: InputDecoration(
                labelText: "Pincode",
                hintText: "${userData?['Pincode'] ?? 'Enter your pincode'}",
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUserProfile,
              child: Text("Update Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
