import 'package:eyeblinkdetectface/index.dart'; // Package import
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';


class FaceSetup extends StatefulWidget {
  final String email;
  final String password;
  const FaceSetup({super.key, required this.email, required this.password});

  @override
  State<FaceSetup> createState() => _FaceSetupState();
}

class _FaceSetupState extends State<FaceSetup> with WidgetsBindingObserver {

  bool _isProcessing = false; // To show loading/prevent double taps
  final bool _startWithInfo = true; // Keep your config options
  final bool _allowAfterTimeOut = false; // Keep your config options
  final List<M7LivelynessStepItem> _verificationSteps = []; // Keep your steps
  int _timeOutDuration = 60; // Keep your config options


  @override
  void initState() {
    super.initState();
    _initValues();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (mounted) {
        _triggerLivenessDetection();
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // cameraController?.dispose(); // Remove camera controller disposal
    super.dispose();
  }

  // --- didChangeAppLifecycleState (can likely be removed if not managing camera) ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Logic related to cameraController removed
    // You might need other lifecycle logic here depending on your app needs
  }


  // --- Initialize package configuration ---
  void _initValues() {
    // Configure steps (ensure it matches your requirement, e.g., one blink)
    _verificationSteps.clear(); // Clear previous steps if re-initializing
    _verificationSteps.add(
      M7LivelynessStepItem(
        step: M7LivelynessStep.blink,
        title: 'Blink to Capture', // Updated title
        isCompleted: false,
      ),
    );

    // Configure the package instance
    Eyeblinkdetectface.instance.configure(
      contourColor: Colors.blue, // Optional contour color
      thresholds: [
        // Threshold for the first blink step
        M7BlinkDetectionThreshold(
          leftEyeProbability: 0.25,
          rightEyeProbability: 0.25,
        ),
        // Add matching threshold if you added a second blink step
        // M7BlinkDetectionThreshold(
        //   leftEyeProbability: 0.25,
        //   rightEyeProbability: 0.25,
        // ),
      ],
    );
  }

  // --- Trigger Liveness Detection Flow ---
  Future<void> _triggerLivenessDetection() async {
    if (_isProcessing) return; // Prevent multiple triggers

    setState(() => _isProcessing = true);

    // Configure detection parameters
    final config = M7DetectionConfig(
      steps: _verificationSteps, // Use the initialized steps
      startWithInfoScreen: _startWithInfo,
      maxSecToDetect: _timeOutDuration == 100 ? 2500 : _timeOutDuration, // Handle timeout
      allowAfterMaxSec: _allowAfterTimeOut,
      captureButtonColor: Colors.red, // Optional button color
    );

    // Start detection - this presents the package's UI
    final String? responseImagePath = await Eyeblinkdetectface.instance.detectLivelyness(
      context,
      config: config,
    );

    // Handle the response
    if (responseImagePath != null && mounted) {
      print("Liveness check successful, image captured at: $responseImagePath");
      File capturedImageFile = File(responseImagePath);
      // Upload the single image captured by the package
      // Passing email/password from widget properties
      await _uploadImages(capturedImageFile, widget.email, widget.password, 0); // Use index 0 for single image or adjust as needed

      // Navigate after successful upload
      if (mounted) {
        Navigator.pushNamed(context, '/home');
      }

    } else {
      // Handle cancellation or failure
      print("Liveness check cancelled or failed.");
      if (mounted) {
        // Optionally navigate back or show a message
        Navigator.pop(context); // Example: go back if cancelled
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }


  // --- Upload Image ---
  Future<void> _uploadImages(File imageFile, String email, String password, int numEmbeddings) async {
    // Check if the widget is still mounted before proceeding
    if (!mounted) return;

    print("Attempting to upload image: ${imageFile.path}");
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.124:5001/upload'), // Ensure IP is correct and reachable
      );

      // Attach the file
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      // Add fields
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['num_embeddings'] = numEmbeddings.toString(); // Or handle appropriately

      var response = await request.send();

      // Read response body for more details (optional)
      var responseBody = await response.stream.bytesToString();
      print("Response Status: ${response.statusCode}");
      print("Response Body: $responseBody");


      if (response.statusCode == 200) {
        print("Upload successful!");
        // Consider showing success feedback to the user
      } else {
        print("Upload failed: ${response.reasonPhrase} - Body: $responseBody");
        if (mounted) {
          // Show error message to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${response.reasonPhrase ?? "Unknown error"}')),
          );
        }
      }
    } catch (e) {
      print("Error uploading image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Face Setup'),
      ),
      body: _buildUI(), // Updated UI method
    );
  }

  // --- Simplified UI ---
  Widget _buildUI() {
    // Since the package handles the camera view during detection,
    // this widget can show instructions or a loading indicator.
    return Center(
      child: _isProcessing
          ? const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text("Starting Face Detection..."),
        ],
      )
          : Column( // Or just show instructions/loading immediately triggered by initState
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Preparing face detection...",
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // You could have a button here if you don't want it auto-start
          // ElevatedButton(
          //   onPressed: _triggerLivenessDetection,
          //   child: const Text("Start Face Scan"),
          // ),
          const CircularProgressIndicator(), // Show loading as it starts automatically
        ],
      ) ,
    );
  }


}