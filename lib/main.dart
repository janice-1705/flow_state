import 'package:flow_state/pages/home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FlowStateApp());
}

class FlowStateApp extends StatelessWidget {
  const FlowStateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow State',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        
        //setting #F4FFFF as the global app background
        scaffoldBackgroundColor: const Color(0xFFF4FFFF),

        colorScheme: ColorScheme.fromSeed(
          // #4495A7 teal as the primary accent color
          seedColor: const Color(0xFF4495A7),
          primary: Color(0xFF4495A7),

          //setting secondary color using #EBFFEE (soft mint)
          secondary: Color(0xFFEBFFEE),
          surfaceVariant: const Color(0xFFEBFFEE),
        ),

        // customize global button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            //sets button color to teal by default
            backgroundColor: const Color(0xFF4495A7),
            //sets button text to white by default
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
          ),
        ),
        
        // tells flutter to use Google's latest user interface design system
        useMaterial3: true,

      ),

      home: const HomePage(),

    );
  }
}

