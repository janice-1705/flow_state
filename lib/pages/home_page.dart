import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        // Far left side, adding hamburger menu icon
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Color(0xFF4495A7),
            size: 28,
          ),
          onPressed:() {
            //will add the drawer trigger later
            print("Menu icon tapped!");
          },
        ),

         //Focus mode button on the far right
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
              ),

              onPressed: () {
                // will navigate to focus_page.dart later
                print("Focus Mode tapped!");
              },
              child: const Text(
                'Focus Mode',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ]
      ),

     

      body: Stack(
        children: [
          // Capture Circle button
          Center(
            child: ElevatedButton(
              onPressed:() {
                print("Central button tapped!");
              },
              child: Text('Capture circle location',),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 80),
              child:ElevatedButton(
                onPressed: (){
                  print("Library tapped!");
                },
                child: Text('Library Location'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}