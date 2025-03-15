import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onBoarding/onbording_veiw_screen.dart';
import '../Components/color.dart';
import './WebView/webview_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

   @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}


class _WelcomeScreenState extends State<WelcomeScreen> {

  @override
  void initState() {
    super.initState();

    // Ensure navigation is executed after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkFirstTime();
    });

  }


  Future<void> checkFirstTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true; // Default is true

    await Future.delayed(const Duration(seconds: 3)); // Simulating splash delay

    if (mounted) {
      if (isFirstTime) {
        // If first time, show onboarding and save the flag
        prefs.setBool('isFirstTime', false); 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingView()),
        );
      } else {
        // If not first time, go to WebView
        const url = "https://60c2-102-88-108-224.ngrok-free.app/auth/students/login";
        //const url = "https://unlimtedhealth.com/auth/patients/login";
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WebViewPage(url: url)), // Pass your link inside the WebViewScreen
        );
      }
    }
  }


  // This widget is the root of your application
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // extendBodyBehindAppBar: true,
      body: Stack(
        children: [

          // Set the logo Image and the Brand Name
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Center the content vertically
		children: [
		  Image.asset(
		    'assets/images/logo.png',
		    width: 200,
		    height: 200,
		  ),
                 
		],
              ),
            ),
          ), // SafeArea

        ]
      ) // Stack
    ); // Scaffold
  }
}
