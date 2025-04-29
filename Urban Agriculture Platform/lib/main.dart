import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rootly/screens/purchase.dart';
import 'package:rootly/screens/signup.dart';
import 'package:rootly/screens/signin.dart'; // For Timer

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rootly',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.green.shade50,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.green.shade900),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

// SPLASH SCREEN
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(context, PageTransition(child: SignUpPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF56B686), Color(0xFF045D56)],
          ),
        ),
        child: Center(
          // To center the image
          child: SizedBox(
            width: 200, // Change width here
            height: 200, // Change height here
            child: Image.asset("assets/Rootly.png", fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// SIGN-UP PAGE
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF56B686), Color(0xFF045D56)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/Rootly.png", width: 100, height: 100),
              Text(
                'Rootly',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              CustomButton(
                text: 'PURCHASE HERE',
                onPressed: () {
                  Navigator.push(context, PageTransition(child: Purchase()));
                },
              ),
              CustomButton(
                text: 'Sign in',

                onPressed: () {
                  Navigator.push(context, PageTransition(child: Login()));
                },
              ),
              SizedBox(height: 10),
              Text(
                'Do not have an account? Register here',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              CustomButton(
                text: 'Signup',
                onPressed: () {
                  Navigator.push(context, PageTransition(child: Signup()));
                },
                minimumSize: Size(100, 50), // Custom size for this button only
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CUSTOM BUTTON WIDGET
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Size? minimumSize; // Optional button size

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.minimumSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: MouseRegion(
        onHover: (event) => {}, // Needed for hover effect to work
        onExit: (event) => {},
        child: ElevatedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.hovered)) {
                return const Color.fromARGB(255, 80, 170, 140); // Hover color
              }
              return const Color.fromARGB(255, 105, 192, 160); // Default color
            }),
            foregroundColor: WidgetStateProperty.all(
              const Color.fromARGB(255, 255, 255, 255),
            ),
            minimumSize: WidgetStateProperty.all(
              minimumSize ?? const Size(double.infinity, 50),
            ),
          ),
          child: Text(text, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

// PAGE TRANSITION ANIMATION
class PageTransition extends PageRouteBuilder {
  final Widget child;
  PageTransition({required this.child})
    : super(
        transitionDuration: Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
}
