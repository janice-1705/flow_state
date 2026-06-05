import 'package:flutter/material.dart';
import 'library_page.dart';
import 'focus_page.dart';
import 'input_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool _isProcessing = false;

  void _showBrainDumpOptions(BuildContext context){

    //function to create bottom sliding sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF4495A7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),

      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            //this is a dynamic container wrap - prevents full screen stretching
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How do you want to capture your thoughts?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // option 1: Use Camera Button
              _buildMenuButton(
                label: 'Use Camera',
                icon: Icons.camera_alt_outlined,
                onTap: () => _handleOptionSelected('Camera'),
              ),

              const SizedBox(height: 16),

              //option 2: Type thoughts button
              _buildMenuButton(
                label: 'Type your thoughts',
                icon: Icons.edit_note_outlined,
                onTap: () => _handleOptionSelected('Text'),
              ),

              const SizedBox(height: 16),

              //option 3: Record voice button
              _buildMenuButton(
                label: 'Record your voice',
                icon: Icons.mic_none_outlined,
                onTap: () => _handleOptionSelected('Voice'),
              ),
            ],
          ),
        );
      }
    );
  }

  // modular helper method to keep menu button styling uniform and clean

  Widget _buildMenuButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity, // forces the button to match card width boundaries
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFEBFFEE), // soft mint accent color
          foregroundColor: Color(0xFF4495A7), // Teal text
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]
        ),
      ),
    );
  }

  // helper widget to generate menu item links

  Widget _buildDrawerLink({required String label, required VoidCallback onTap}){
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
        ),
      ),
    );
  }


  //function to handle option selection in sliding window
  void _handleOptionSelected(String captureType){
    Navigator.pop(context); // closes the sliding bottom sheet menu
    Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => InputPage(inputType: captureType),
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
      // if processing is true -> show the loading view
      if (_isProcessing){
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'structuring your thoughts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4495A7),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '......',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4495A7),
                  ),
                ),
                const SizedBox(height: 48),
                //temporary button to click to return to the home page while testing
                TextButton(
                  onPressed: () => setState(() => _isProcessing = false),
                  child: const Text('Cancel & Return', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        // drawer block: creates the left slide-out bar
        drawer: Drawer(
          backgroundColor: Color(0xFF4495A7), // dark teal
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context), //closes the drawer
                  ),
                  
                  const SizedBox(height: 48), //for space between menu items

                  //menu links
                  _buildDrawerLink(
                    label: 'Sign in',
                    onTap: () => print("Sign in tapped"),
                  ),

                  const SizedBox(height: 32),

                  _buildDrawerLink(
                    label: 'Settings',
                    onTap: () => print("Settings tapped"),
                  ),

                  const SizedBox(height: 32),

                  _buildDrawerLink(
                    label: 'About Flow State',
                    onTap: () => print("Sign in tapped"),
                  ),

                ],
              ),
            ),
          ),
        ),

        // App bar
        appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        // Far left side, adding hamburger menu icon
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(
                Icons.menu,
                color: Color(0xFF4495A7),
                size: 28,
              ),
              onPressed:() {
                //opens the drawer
                Scaffold.of(context).openDrawer();
              },
            );
          }
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FocusPage()),
                );
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
          Align(
            alignment: Alignment(0.0, -0.35),
            child: GestureDetector(
              onTap:() {
                // triggers the sliding sheet layout
                _showBrainDumpOptions(context);
              },

              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4495A7),
                  boxShadow: [
                    BoxShadow(
                      //soft teal shadow tint
                      color: Color(0xFF4495A7).withValues(alpha: 0.6),
                      //makes the drop shadow feather outward
                      blurRadius: 40,
                      // Pushes the shadow downward 
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Tap to\nCapture',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      //controls line spacing
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Library button
          Align(
            //finds the bottom of the screen and adds pixels from the bottom
            alignment: Alignment.bottomCenter,

            child: Padding(
              padding: EdgeInsets.only(bottom: 80),
              child:ElevatedButton(
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LibraryPage()),
                  );
                },
                child: Text('View Library'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}