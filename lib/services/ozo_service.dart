import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class OzoService {
  // Pulls the token securely passed from the terminal compile flag command line
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // Grounding configuration instructions to enforce precise JSON syntax shapes
  static const String _systemInstruction = '''
You are Ozo, an elite AI assistant integrated into a minimalist 'Second Brain' mobile vault application called flow_state.
Your job is to take a user's unedited raw thoughts, text dumps, or transcripts, and organize them perfectly according to the requested JSON schema layout.
''';

  /// Takes unedited text inputs and pipes them directly through the Gemini model with 503 retry safety
  static Future<Map<String, dynamic>> processBrainDump(String rawInput) async {
    if (_apiKey.isEmpty) {
      throw Exception("Gemini API Key configuration flag is missing! Ensure you compiled with --dart-define.");
    }

    int retryCount = 0;
    const int maxRetries = 3;

    while (true) {
      bool shouldRetry = false; // Controls loop iteration safely outside catch scope

      try {
        // Initialize the lightning-fast multimodal intelligence engine
        final model = GenerativeModel(
          model: 'gemini-2.5-flash', 
          apiKey: _apiKey,
          systemInstruction: Content.system(_systemInstruction),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json', // Forces engine to lock response to JSON format parsing
            responseSchema: Schema.object(
              properties: {
                'title': Schema.string(
                  description: 'A sharp, catchy, professional 3-5 word title summarizing the raw thoughts.',
                ),
                'summary': Schema.string(
                  description: 'A clean, beautifully formatted paragraph summarizing the core text.',
                ),
              },
              requiredProperties: ['title', 'summary'],
            ),
          ),
        );

        // Wrap the content with our structural persona instructions
        final content = [
          Content.text("Here is the raw unedited user dump to process:\n\n$rawInput"),
        ];

        final response = await model.generateContent(content);
        
        if (response.text != null) {
          print("Ozo response synthesized successfully!");
          return Map<String, dynamic>.from(
            dynamicDecodePlaceholder(response.text!) 
          );
        } else {
          throw Exception("Ozo generated an empty intelligence frame stream response.");
        }
      } catch (e) {
        // Toggle loop flag if a temporary server surge drops the connection
        if (e.toString().contains('503') && retryCount < maxRetries) {
          retryCount++;
          shouldRetry = true;
          print("⚠️ Gemini text cluster overloaded (503). Retrying attempt $retryCount/$maxRetries...");
        } else {
          print("Ozo intelligence link extraction fault: $e");
          rethrow;
        }
      }

      // Handle the physical sleep delay and retry jump outside the try-catch block limits
      if (shouldRetry) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
    }
  }

  // Quick fallback proxy to bypass JSON parsing dynamic casts within the service boundary
  static dynamic dynamicDecodePlaceholder(String source) {
    return jsonDecode(source);
  }

  /// Takes a Base64 image string, feeds it to Gemini, and extracts structured data with 503 retry safety
  static Future<Map<String, dynamic>> processImageCapture(String base64Image) async {
    if (_apiKey.isEmpty) {
      throw Exception("Gemini API Key missing! Build with --dart-define.");
    }

    int retryCount = 0;
    const int maxRetries = 3;

    while (true) {
      bool shouldRetry = false; // Controls loop iteration safely outside catch scope

      try {
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: _apiKey,
          systemInstruction: Content.system(_systemInstruction),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: Schema.object(
              properties: {
                'title': Schema.string(description: 'A sharp 3-5 word title for the captured document or scene.'),
                'summary': Schema.string(description: 'A meticulous transcription or summary of what is seen in the image.'),
              },
              requiredProperties: ['title', 'summary'],
            ),
          ),
        );

        // Convert the Base64 string back into raw image bytes for the Gemini API
        final Uint8List imageBytes = base64Decode(base64Image);

        final content = [
          Content.multi([
            // Feed the raw document bytes directly into the AI's vision matrix
            DataPart('image/jpeg', imageBytes),
            TextPart("Analyze this scanned document image. Extract its core text and structure it perfectly."),
          ]),
        ];

        final response = await model.generateContent(content);
        
        if (response.text != null) {
          return Map<String, dynamic>.from(jsonDecode(response.text!));
        } else {
          throw Exception("Ozo vision link returned empty data stream.");
        }
      } catch (e) {
        // Toggle loop flag if a temporary server surge drops the connection
        if (e.toString().contains('503') && retryCount < maxRetries) {
          retryCount++;
          shouldRetry = true;
          print("⚠️ Gemini vision cluster overloaded (503). Retrying attempt $retryCount/$maxRetries...");
        } else {
          print("Ozo vision extraction error: $e");
          rethrow;
        }
      }

      // Handle the physical sleep delay and retry jump outside the try-catch block limits
      if (shouldRetry) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
    }
  }
}