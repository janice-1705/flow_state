import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:math';
import 'focus_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {

  // this connects a pointer pipeline to the notes collection in the cloud database
  final Stream<QuerySnapshot> _notesStream = 
      FirebaseFirestore.instance.collection('notes').snapshots();

  // brand color palette
  final List<Color> _brandPalette = [
    const Color(0xFFBBE5ED), // Light soft teal
    const Color(0xFF90C2CE), // Mid soft teal
    const Color(0xFF70B2C1), // Deep soft teal
    const Color(0xFFEBFFEE), // soft mint accent
    const Color(0xFFD4F2F7), // Icy sky blue accent
  ];

  // mock data representing notes with varying summary lengths to show dynamic adjustment
  final List<Map<String, dynamic>> _notes = [
    {
    'title': 'SaaS Hook Ideas',
    'summary': 'A collection of high-converting hooks for the new dashboard product launch campaign.',
    'color': const Color(0xFFBBE5ED),
    'hasImage': true,
    },
    {
      'title': 'Voice Note Log',
      'summary': 'Audio brainstorming session about the app onboarding flow redesign.',
      'color': const Color(0xFF90C2CE),
      'hasAudio': true,
    },
    {
      'title': 'App Layout Spec',
      'summary': 'Short structural doc.',
      'color': const Color(0xFF70B2C1),
      'hasImage': false,
    },
    {
      'title': 'Marketing Strategy',
      'summary': 'Detailed notes covering our target distribution channels and D2C ad budget allocations for Q3.',
      'color': const Color(0xFFBBE5ED),
      'hasImage': true,
    },
    {
      'title': 'Design Checklist',
      'summary': 'Review typography pairings and line-height values before exporting assets.',
      'color': const Color(0xFF90C2CE),
      'hasAudio': true,
    },
  ];

  final List<String> _topics = ['All', 'SaaS Work', 'Personal Tech', 'Design Copy', 'Audio Snippets'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Search Bar and filter row
              _buildSearchBarRow(),

              const SizedBox(height: 20,),

              // Horizontal sliding topics bar
              const Text(
                'Topics:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4495A7),
                ),
              ),

              const SizedBox(height: 8),
              _buildHorizontalTopicsList(),

              const SizedBox(height: 24),

              // Grid Header: Recents
              const Text(
                'Recents',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4495A7),
                ),
              ),

              const SizedBox(height: 16),

              // Dynamic pinterest style grid overview; connected to firebase
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _notesStream,
                  builder: (context, snapshot){

                    //to handle background connection errors
                    if (snapshot.hasError){
                      return const Center(
                        child: Text(
                          'Error loading cloud vault.',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    // show a loading spinner only on the very first cold launch lookup
                    if (snapshot.connectionState == ConnectionState.waiting){
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF4495A7)),
                      );
                    }

                    //extract the list of documents safetly
                    final cloudDocs = snapshot.data?.docs ?? [];

                    // fallback placeholder if firebase collection is completely empty
                    if(cloudDocs.isEmpty){
                      return const Center(
                        child: Text(
                          'No notes found in the cloud database.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      physics: const BouncingScrollPhysics(),
                      itemCount: cloudDocs.length, // uses cloud array length
                      itemBuilder: (context, index){
                        // extract map data out of the individual document snapshot
                        final doc = cloudDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildDynamicNoteBox(data, index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // bottom nav bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // component module: search and filter layout
  Widget _buildSearchBarRow(){
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFFD9D9D9).withValues(alpha:0.44),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text('Search', style: TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(
            Icons.tune_rounded, 
            color: Color(0xFF4495A7),
            size: 26,
          ),
          onPressed: () {
            print('Filter panel toggled');
          },
        ),
      ],
    );
  }

  // component module: Horizontal Sliding Topic Capsules
  Widget _buildHorizontalTopicsList(){
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _topics.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index){
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                // alternating capsule colors
                color: index == 0 ? const Color(0xFF4495A7) : const Color(0xFFBBE5ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _topics[index],
                style: TextStyle(
                  color: index == 0? Colors.white : const Color(0xFF4495A7),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // component module: dynamic height note card component
  Widget _buildDynamicNoteBox(Map<String, dynamic> note, int index){

    //Deterministic randomization -> uses the grid index to cycle through the brand colors

    final Color assignedColor = _brandPalette[index % _brandPalette.length];

    return Container(
      decoration: BoxDecoration(
        color: assignedColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          // header title next to 3-dot icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF225B66)),
                ),
              ),
              GestureDetector(
                onTap: () => print('${note['title']} options clicked!'),
                child: const Icon(Icons.more_horiz, color: Color(0xFF225B66), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom thumbnail/img icon space

          if(note['hasImage'] == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image_outlined, color: Color(0xFF225B66), size: 28),
              ),
            ),

            if (note['hasAudio'] == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.mic_rounded, color: Color(0xFF225B66), size: 20),
                  const SizedBox(width: 6),
                  Text('Audio file', style: TextStyle(color: const Color(0xFF225B66).withValues(alpha: 0.8), fontSize: 12)),
                ],
              ),
            ),

            // Dynamic text-box -> auto summary block
            Text(
            note['summary'],
            style: const TextStyle(fontSize: 13, color: Color(0xFF225B66), height: 1.3),
          ),
        ],
      ),
    );
  }

  // component module: bottom nav bar
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFECECEC), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Color(0xFF4495A7), size: 26),
            onPressed: () => Navigator.pop(context), // Pops back home 
          ),
          const Text(
            'Library',
            style: TextStyle(color: Color(0xFF4495A7), fontWeight: FontWeight.bold, fontSize: 15),
          ),

          // focus icon to navigate to focus page
          IconButton(
            icon: const Icon(Icons.center_focus_weak_rounded, color: Color(0xFF4495A7), size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FocusPage()),
              );
            },
          ),
        ],
      ),
    );
  }

}