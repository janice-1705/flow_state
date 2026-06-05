import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'library_page.dart';

// define 4 distinct visual states

enum FocusModeState{ setup, active, paused, ended}

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {

  // the software tracking controller
  final TextEditingController _focusTextController = TextEditingController();

  // for memory cleanup
  @override
  void dispose() {
    _focusTextController.dispose();
    super.dispose();
  }

  // the user starts on the "setup" view panel

  FocusModeState _currentState = FocusModeState.setup;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // background is already defined in main.dart
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // top bar configuration

              _buildTopBar(),

              // Central Expanding workspace (changes dynamically based on the state)

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: _buildMainContent(),
                  ),
                ),
              ),

              // Bottom footer
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Focus Mode',
                  style: TextStyle(
                    color: Color(0xFF4495A7), // teal
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // layout module: dynamic top nav bar
  Widget _buildTopBar(){
    if(_currentState == FocusModeState.setup){
      return Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap:() => Navigator.pop(context), // pops screen off stack to go back home
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF4495A7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'back',
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
    // return empty placeholder box when active, paused, or ended to preserve spacing
    return SizedBox(height: 38);
  }

  // layout module: Switches views based on the current active state
  Widget _buildMainContent(){
    switch (_currentState){
      case FocusModeState.setup:
        return _buildSetupContent();
      case FocusModeState.active:
        return _buildActiveContent();
      case FocusModeState.paused:
        return _buildPausedContent();
      case FocusModeState.ended:
        return _buildEndedContent();
    }
  }

  // 1. Setup layout view
  Widget _buildSetupContent(){
    return Column(
      children: [
        const Text(
          'What are we\nfocusing on\ntoday?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4495A7),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 32),

        //input box placeholder
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xFFDCDCDC),
            borderRadius: BorderRadius.circular(12),
            
          ),
          
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: TextField(
                controller: _focusTextController,
                style: const TextStyle(color: Colors.black87),
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: 'type here...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

        ),

        const SizedBox(height: 24),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4495A7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: () async {

            // safety check to make sure user didn't submit an empty response accidently

            if (_focusTextController.text.trim().isEmpty){
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Type out your session context first!')),
              );
              return;
            }

            try{
              //package and ship the data to firebase notes folder
              await FirebaseFirestore.instance.collection('notes').add({
                'title': 'Focus Session Log', // AI gen titles will go here later
                'summary': _focusTextController.text.trim(), // captures the input text
                'type': 'Text',
                'createdAt': FieldValue.serverTimestamp(),
              });

              // clear out field box for their next session
              _focusTextController.clear();

              // success alert
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session log successfully synced to Library!')),
              );

            }catch(error){
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cloud sync failed: $error')),
              );
            }

            setState(() {
              _currentState = FocusModeState.active;
            });
          },
          child: const Text('Start Focus Mode'),
        ),

      ],
    );
  }

  // 2. Active layout view
  Widget _buildActiveContent(){
    return Column(
      children: [
        _buildAssistantOrb('I\'ll be at the corner of your\nscreen ready to help when\nyou need me!'),
        const SizedBox(height: 32),
        const Text(
          'Focus mode\nis on!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4495A7), //teal
            height: 1.1,
          ),
        ),

        const SizedBox(height: 48),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionCapsule('Pause', () {
              setState(() {
                _currentState = FocusModeState.paused;
              });}
            ),
            const SizedBox(width: 32),
            _buildActionCapsule('End', () {setState(() {
              _currentState = FocusModeState.ended;
            });},
            ),
          ],
        ),
      ],
    );
  }

  // 3. Paused layout view
  Widget _buildPausedContent(){
    return Column(
      children: [
        _buildAssistantOrb('I\'ll be at the corner of your\nscreen ready to help when\nyou need me!'),
        const SizedBox(height: 32),
        const Text(
          'Focus mode\npaused...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40, 
            fontWeight: FontWeight.bold, 
            color: Color(0xFF4495A7),
            height: 1.1,
          ),
        ),

        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionCapsule(
              'Resume', 
              (){
                setState(() {
                  _currentState = FocusModeState.active;
                });
              }
            ),

            const SizedBox(width: 32),

            _buildActionCapsule(
              'End', 
              (){
                setState(() {
                  _currentState = FocusModeState.ended;
                });
              }
            ),
            
          ],
        ),
      ],
    );
  }

  // 4. Session ended layout view
  Widget _buildEndedContent(){
    return Column(
      children: [
        _buildAssistantOrb('Great work\ntoday!'),
        const SizedBox(height: 32),
        const Text(
          'Focus mode\nended',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40, 
            fontWeight: FontWeight.bold, 
            color: Color(0xFF4495A7), 
            height: 1.1
          ),
        ),

        const SizedBox(height: 48),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionCapsule('Go to\nHome', () => Navigator.pop(context)),
            const SizedBox(width: 24),
            _buildActionCapsule('Go to\nLibrary', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LibraryPage()),
              );
            }),
          ],
        ),
      ],
    );
  }

  // ozo(the ai orb) layout component
  Widget _buildAssistantOrb(String speechText){
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // the orb graphic
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.white, Color(0xFF4495A7).withValues(alpha:0.7)],
            ),
          ),
        ),

        // positioning of Ozo's speech box
        Positioned(
          bottom: 150,
          left: 85,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFDCDCDC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(16),
              ),
            ),

            child: Text(
              speechText,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  // button capsule template
  Widget _buildActionCapsule(String label, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4495A7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onTap,
      child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}