import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'library_page.dart';
import 'dart:io'; // Needed to handle image file paths
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:convert';

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

  //camera hardware tracking variables
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  File? _capturedImageFile; // holds the final, cropped image file

  @override
  void initState(){
    super.initState();
    // to get the camera started as soon as the user taps the camera option
    if(widget.inputType == 'Camera'){
      _initializeCameraSystem();
    }
  }

  Future<void> _initializeCameraSystem() async {
    try{
      // to fetch the physical list of available lenses on the device
      _cameras = await availableCameras();

      if (_cameras != null && _cameras!.isNotEmpty){
        // setup the controller to use the main rear camera with high resolution
        _cameraController = CameraController(
          _cameras![0], // Default back-facing camera lens
          ResolutionPreset.high,
          enableAudio: false, // don't need microphone access
        );

        // to complete the physical hardware connection 
        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    }catch(e){
      print("Camera hardware initialization failure: $e");
    }
  }

  // Action A: Freezes the lens array matrix frame stream and writes file data to cache
  Future<void> _snapPhotoCaptureAction() async {
    if (!_isCameraInitialized || _cameraController == null || _cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile rawPhotoFile = await _cameraController!.takePicture();
      // Instantly push this captured string file target into the native image cropper system
      await _cropImageAction(rawPhotoFile.path);
    } catch (e) {
      print("Error executing image freeze capture frame: $e");
    }
  }

  // Action B: Launches native phone UI layout box to let users crop, scale, and align their document
  Future<void> _cropImageAction(String rawFilePath) async {
    try {
      final CroppedFile? croppedDataFile = await ImageCropper().cropImage(
        sourcePath: rawFilePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Align & Crop Document',
            toolbarColor: const Color(0xFF4495A7),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Align & Crop Document',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (croppedDataFile != null) {
        setState(() {
          _capturedImageFile = File(croppedDataFile.path); // Freezes cropped path into state preview display!
        });
      }
    } catch (e) {
      print("Image cropper compilation exception instance: $e");
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _cameraController?.dispose(); // turn off physical lens sensor to save battery
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
              border: Border.all(color: const Color(0xFF4495A7).withValues(alpha: 0.3)),
            ),
            clipBehavior: Clip.antiAlias, // keeps the live camera edges rounded inside the card
            child: _buildCameraViewportSelector(),
          ),
        ),
        const SizedBox(height: 20),
        
        // options control row (only active if an image has been snapped)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildEditToolButton(
              Icons.crop, 
              'Crop', 
              _capturedImageFile == null ? null : () => _cropImageAction(_capturedImageFile!.path)
            ),
            _buildEditToolButton(
              Icons.refresh_rounded, 
              'Retake', 
              _capturedImageFile == null ? null : () {
                setState(() => _capturedImageFile = null); // Wipes file and wakes back up live lens feed
              }
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSyncButton(() async{
          if (_capturedImageFile == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please snap a photo capture frame first!')),
            );
            return;
          }

          try{
            // convert image file bytes into a text string
            final List<int> imageBytes = await _capturedImageFile!.readAsBytes();
            final String base64ImageString = base64Encode(imageBytes);

            // opens a direct pipeline to the firestore notes library collection
            await FirebaseFirestore.instance.collection('notes').add({
              'title': 'Camera Capture Log', // Ozo will auto-generate titles here later
              'summary': 'Visual document scan saved to vault.',
              'imageData': base64ImageString, // this is the image inside the database as text
              'type': 'Camera', // tells the library grid to draw an image card layout
              'createdAt': FieldValue.serverTimestamp(),
            });

            //success alert msg
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image successfully synced to your Library!')),
            );

            // send the user to the library page to see their new img card
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const LibraryPage()),
            );
          }catch(error){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cloud image sync failed: $error')),
            );

          }
        }),
      ],
    );
  }

  // to switch between live view and review

  Widget _buildCameraViewportSelector() {
    // Mode A: User has already snapped and cropped their file context image
    if (_capturedImageFile != null) {
      return Image.file(_capturedImageFile!, fit: BoxFit.contain);
    }

    // Mode B: Hardware is still spinning up, show a clean loading indicator wheel
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4495A7)));
    }

    // Mode C: Lens is completely ready, overlay a shutter action trigger onto the live screen feed Matrix!
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        
        // Immersive overlay translucent frame shutter action key node
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _snapPhotoCaptureAction,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Center(
                  child: Icon(Icons.camera, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        )
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

  Widget _buildEditToolButton(IconData icon, String label, VoidCallback? onTap) {
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