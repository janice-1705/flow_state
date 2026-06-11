import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'library_page.dart';
import 'dart:io'; // Needed to handle image and audio file paths
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:convert';
import 'package:record/record.dart'; // to access physical microphone streams
import 'package:path_provider/path_provider.dart'; // finds safe directory folders on device
import 'package:flow_state/services/ozo_service.dart'; // 💡 Adjust path if your project folder name is different


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

  late final AudioRecorder _audioRecorder;
  String? _localAudioPath;

  //camera hardware tracking variables
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  File? _capturedImageFile; // holds the final, cropped image file

  @override
  void initState(){
    super.initState();

    // to initialize the AudioRecorder instance on startup
    _audioRecorder = AudioRecorder();
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

  // -- Audio Recorder Methods --

  // action A - Verifies platform privileges, spins up sensor array, and hooks stream to temp directory

  Future<void> _startRecordingAudio() async{
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath = '${tempDir.path}/flow_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Initialize microphone hardware recording channel
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), 
          path: filePath
        );

        setState(() {
          _isRecording = true;
          _localAudioPath = filePath;
          _audioTranscriptPlaceholder = "Listening intently to your voice stream... Tap stop to seal note.";
        });
        print("Recording hardware active. Streaming to: $filePath");
      }
    } catch (e) {
      print("Microphone sensor connection failure: $e");
    }
  }

  // action B: Cuts power to input pin, flushes data to memory, and displays validation state

  Future<void> _stopRecordingAudio() async {
    try {
      final String? path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _localAudioPath = path;
        _audioTranscriptPlaceholder = "Voice note recorded successfully! [Stored at: ...${path?.split('/').last}]\n\nReady to sync data to your cloud vault library.";
      });
      print("Audio file capture locked locally at: $_localAudioPath");
    } catch (e) {
      print("Error shutting down audio session safely: $e");
    }
  }


  // --- Camera Pipeline methods -----

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
    _audioRecorder.dispose(); // close background stream channels to prevent memory leaks
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
          final String rawThoughts = _textController.text.trim();
          // to prevent users from saving blank notes
          if (rawThoughts.isEmpty){
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please write out your thoughts before syncing!')),
            );
            return;
          }

          try{
            // to show a loading msg so that the user knows Ozo is thinking
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ozo is organizing your thoughts...'),
                duration: Duration(seconds: 2),
              ),
            );
            // pass raw data to ozo
            final Map<String, dynamic> ozoResult = await OzoService.processBrainDump(rawThoughts);

            // extract the structured JSON layers Ozo generated
            final String aiTitle = ozoResult['title'] ?? 'Text Capture Log';
            final String aiSummary = ozoResult['summary'] ?? rawThoughts;

            // open a direct link to the cloud 'notes' folder
            await FirebaseFirestore.instance.collection('notes').add({
              'title': aiTitle, // AI generated title
              'summary': aiSummary, // AI generated summary
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ozo is analyzing your document image...'), duration: Duration(seconds: 2)),
            );

            // Convert image file bytes into a text string
            final List<int> imageBytes = await _capturedImageFile!.readAsBytes();
            final String base64ImageString = base64Encode(imageBytes);

            // TALK TO OZO VISION: Let Gemini process the document image!
            final Map<String, dynamic> ozoResult = await OzoService.processImageCapture(base64ImageString);

            // Opens a direct pipeline to the firestore notes library collection
            await FirebaseFirestore.instance.collection('notes').add({
              'title': ozoResult['title'] ?? 'Camera Capture Log', // ⚡ AI Generated!
              'summary': ozoResult['summary'] ?? 'Visual document scan saved.', // ⚡ AI Generated!
              'imageData': base64ImageString, 
              'type': 'Camera', 
              'createdAt': FieldValue.serverTimestamp(),
            });

            if (!mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LibraryPage()));
          }catch(error){
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ozo image sync failed: $error'),
              ),
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
          onTap: _isRecording ? _stopRecordingAudio : _startRecordingAudio,
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
        _buildSyncButton(() async{
          // gaurd criteria: ensures a real asset path exists in memory cache
          if (_localAudioPath == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please record a voice audio snippet first!')),
            );
            return;
          }

          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ozo is organizing your audio data...'), duration: Duration(seconds: 2)),
            );

            // Create your base context identifier string
            final String rawVoiceDataText = "Audio recording log file sitting locally at: $_localAudioPath. Extract a creative layout summary from this action signature.";

            // 🧠 TALK TO OZO: Let Gemini process the audio signature context!
            final Map<String, dynamic> ozoResult = await OzoService.processBrainDump(rawVoiceDataText);

            await FirebaseFirestore.instance.collection('notes').add({
              'title': ozoResult['title'] ?? 'Voice Note Log', // ⚡ AI Generated!
              'summary': ozoResult['summary'] ?? rawVoiceDataText, // ⚡ AI Generated!
              'audioPath': _localAudioPath, 
              'type': 'Voice',
              'createdAt': FieldValue.serverTimestamp(),
            });

            if (!mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LibraryPage()));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ozo voice sync failed: $e')));
          }
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