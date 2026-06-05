import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'library_page.dart';

class InputPage extends StatefulWidget {
  final String inputType; // 'Text', 'Voice', or 'Camera'

  const InputPage({super.key, required this.inputType});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isRecording = false; 
  String _audioTranscriptPlaceholder = "Your live speech transcription will materialize here after recording...";

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4495A7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Capture ${widget.inputType}',
          style: const TextStyle(color: Color(0xFF4495A7), fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildDynamicInputContent(), 
        ),
      ),
    );
  }

  // Central Controller for layouts
  Widget _buildDynamicInputContent() {
    switch (widget.inputType) {
      case 'Camera':
        return _buildCameraLayout();
      case 'Voice':
        return _buildVoiceLayout();
      case 'Text':
      default:
        return _buildTextLayout();
    }
  }

  // text layout
  Widget _buildTextLayout() {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCDCDC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _textController,
              maxLines: null,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Dump your unedited raw thoughts right here...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSyncButton(() async{
          // to prevent users from saving blank notes
          if (_textController.text.trim().isEmpty){
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please write out your thoughts before syncing!')),
            );
            return;
          }

          try{
            // open a direct link to the cloud 'notes' folder
            await FirebaseFirestore.instance.collection('notes').add({
              'title': 'Text Capture Log', // Ozo will auto-generate titles here later
              'summary': _textController.text.trim(), // sends your exact input
              'type': 'Text', // this tells the library page to draw it as a text-style card
              'createdAt': FieldValue.serverTimestamp(), // Exact server-side sync time
            }); 

            // to clear out the typing canvas box
            _textController.clear();

            // alert success msg
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to your Library')),
            );

            // sends the user to the library so they can see their note
            // used pushReplacement instead of push since if the user then hit "back" on the Library Page, they would awkwardly land right back on the text entry form they just filled out.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LibraryPage()),
            );

          }catch(error){
            // Catches any network drops or database connection dropouts
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cloud sync failed: $error')),
            );
          }
        }),
      ],
    );
  }

  // camera layout
  Widget _buildCameraLayout() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const  Color(0xFFDCDCDC),
              borderRadius: BorderRadius.circular(16),
              // 💡 FIX: Swapped .withValues to universally safe .withOpacity
              border: Border.all(color: const Color(0xFF4495A7).withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Icon(Icons.camera_alt_outlined, size: 64, color: Color(0xFF4495A7)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildEditToolButton(Icons.crop, 'Crop', () => print('Trigger native cropper overlay...')),
            _buildEditToolButton(Icons.edit_note, 'Annotate', () => print('Open sketch board overlay...')),
            _buildEditToolButton(Icons.rotate_right, 'Rotate', () => print('Rotate image matrix...')),
          ],
        ),
        const SizedBox(height: 24),
        _buildSyncButton(() {
          print('Processing image elements...');
        }),
      ],
    );
  }

  // voice layout
  Widget _buildVoiceLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _isRecording = !_isRecording),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // 💡 FIX: Swapped out opacity methods here as well
              color: _isRecording ? Colors.red.withValues(alpha: 0.2) : const Color(0xFF4495A7).withValues(alpha: 0.2),
              border: Border.all(color: _isRecording ? Colors.red : const Color(0xFF4495A7), width: 3),
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              size: 40,
              color: _isRecording ? Colors.red : const Color(0xFF4495A7),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isRecording ? 'RECORDING VOICE...' : 'Tap to Start Recording',
          style: TextStyle(
            color: _isRecording ? Colors.red : const Color(0xFF4495A7),
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        
        Container(
          width: double.infinity,
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const  Color(0xFFDCDCDC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _audioTranscriptPlaceholder,
            style: const TextStyle(color: Color(0xFF4495A7), fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: 24),
        _buildSyncButton(() {
          print('Processing audio transcript pipeline...');
        }),
      ],
    );
  }

  Widget _buildSyncButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4495A7),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: const Text('Add to library', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEditToolButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4495A7), size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}