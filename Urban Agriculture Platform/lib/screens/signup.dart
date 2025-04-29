import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rootly/auth_service.dart';
import 'package:rootly/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});
  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phonenoController = TextEditingController();

  final UserRepository userRepo = UserRepository();
  String userType = "Farmer";
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _pincodeController.dispose();
    _usernameController.dispose();
    _phonenoController.dispose();
    super.dispose();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Register Rootly Account',
                      style: GoogleFonts.raleway(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildInputField(
                    controller: _emailController,
                    label: "Email Address",
                    hint: "Enter your email",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Email is required";
                      }
                      final emailRegex = RegExp(
                        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return "Enter a valid email address";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _passwordController,
                    label: "Password",
                    hint: "Enter your password",
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Password is required";
                      }
                      if (value.length < 8) {
                        return "Password must be at least 8 characters";
                      }
                      if (!RegExp(
                        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$',
                      ).hasMatch(value)) {
                        return "Must contain upper, lower, number & special character";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _usernameController,
                    label: "Username",
                    hint: "Enter your username",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Username is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _pincodeController,
                    label: "Pincode",
                    hint: "Enter your pincode",
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Pincode is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _phonenoController,
                    label: "Phone Number",
                    hint: "Enter your contact number",
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Phone number is required";
                      }
                      if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return "Enter a valid 10-digit phone number";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _userTypeSelection(),
                  const SizedBox(height: 40),
                  _signupButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword ? _obscurePassword : false,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            fillColor: Colors.white.withOpacity(0.15),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(14),
            ),
            suffixIcon:
                isPassword
                    ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _userTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select User Type",
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        RadioListTile(
          title: const Text("Farmer", style: TextStyle(color: Colors.white)),
          value: "Farmer",
          activeColor: Colors.white,
          groupValue: userType,
          onChanged: (value) => setState(() => userType = value.toString()),
        ),
        RadioListTile(
          title: const Text("Catering", style: TextStyle(color: Colors.white)),
          value: "Catering",
          activeColor: Colors.white,
          groupValue: userType,
          onChanged: (value) => setState(() => userType = value.toString()),
        ),
      ],
    );
  }

  Widget _signupButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _isLoading ? null : _signup,
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text(
                  "Sign Up",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  Future<void> _signup() async {
    print("Signup button pressed!");
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final pincode = _pincodeController.text.trim();
      final username = _usernameController.text.trim();
      final phone = _phonenoController.text.trim();

      try {
        await AuthService().signup(
          email: email,
          password: password,
          pincode: pincode,
          username: username,
          phone: phone,
          context: context,
        );

        final user = UserModel(
          email: email,
          username: username,
          pincode: pincode,
          password: password,
          phone: phone,
        );

        final result = await userRepo.createUser(user, userType);

        if (!mounted) return;

        String message;
        Color bgColor;

        if (result == 'success') {
          message =
              "Your details are added to ${userType == "Farmer" ? "Farmers" : "Caterers"}";
          bgColor = Colors.green;
        } else if (result == 'duplicate') {
          message = "User with this email already exists";
          bgColor = Colors.orange;
        } else {
          message = "Something went wrong. Try again";
          bgColor = Colors.red;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: bgColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        if (result == "success") {
          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration failed: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
    print("Signup completed, no navigation should happen!");
  }
}

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createUser(UserModel user, String userType) async {
    String collectionName = userType == "Farmer" ? "Farmers" : "Caterers";
    try {
      return await _db.runTransaction((transaction) async {
        DocumentReference docRef = _db
            .collection(collectionName)
            .doc(user.email);
        DocumentSnapshot snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          return 'duplicate';
        } else {
          transaction.set(docRef, user.toJson());
          return 'success';
        }
      });
    } catch (error) {
      print("Error storing user: ${error.toString()}");
      return 'error';
    }
  }
}
