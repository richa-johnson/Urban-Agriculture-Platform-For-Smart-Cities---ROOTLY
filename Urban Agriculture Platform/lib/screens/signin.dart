import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rootly/auth_service.dart';

class Login extends StatelessWidget {
  Login({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
        height: 900,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF56B686), Color(0xFF045D56)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    'Login To Your Account',
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                _emailAddress(),
                const SizedBox(height: 20),
                _password(),
                const SizedBox(height: 40),
                _signin(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailAddress() {
    return _buildInputField(
      _emailController,
      "Email Address",
      false,
      "Enter your email",
      TextInputType.emailAddress,
    );
  }

  Widget _password() {
    return _buildInputField(
      _passwordController,
      "Password",
      true,
      "Enter your password",
      TextInputType.text,
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    bool ob,
    String hint, [
    TextInputType keyboardType = TextInputType.text,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Color.fromARGB(255, 245, 244, 244),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: ob,
          style: const TextStyle(color: Color.fromARGB(255, 17, 8, 8)),
          decoration: InputDecoration(
            filled: true,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            fillColor: Colors.white.withOpacity(0.3),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _signin(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(double.infinity, 55),
      ),
      onPressed: () async {
        await AuthService().signin(
          email: _emailController.text,
          password: _passwordController.text,
          context: context,
        );
      },
      child: const Text(
        "Sign In",
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
