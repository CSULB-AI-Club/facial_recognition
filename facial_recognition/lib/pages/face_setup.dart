import 'package:camera/camera.dart';
import 'package:facial_recognition/pages/camera.dart';
import 'package:eyeblinkdetectface/index.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:facial_recognition/pages/home.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:facial_recognition/utils/detection_utils.dart';
import "package:flutter/services.dart";

class FaceSetup extends StatefulWidget {
  final String uid;
  final String home_camera;
  const FaceSetup({super.key, required this.uid, required this.home_camera});

  @override
  State<FaceSetup> createState() => _FaceSetupState();
}

class _FaceSetupState extends State<FaceSetup> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  int selectedCameraIndex = 0;
  bool _isProcessing = false;
  bool _isBusy = false;
  bool _didCloseEyes = false;
  final List<M7LivelynessStepItem> _verificationSteps = [];

  @override
  void initState() {
    super.initState();
    _initValues();
    _setupCameraController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (cameraController == null || !cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cameraController?.stopImageStream();
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController();
    }
  }

  void _initValues() {
    _verificationSteps.clear();
    _verificationSteps.add(
      M7LivelynessStepItem(
        step: M7LivelynessStep.blink,
        title: 'Blink to Capture',
        isCompleted: false,
      ),
    );
    Eyeblinkdetectface.instance.configure(
      contourColor: Colors.blue,
      thresholds: [
        M7BlinkDetectionThreshold(
          leftEyeProbability: 0.25,
          rightEyeProbability: 0.25,
        ),
      ],
    );
  }

  Future<void> _setupCameraController() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        cameraController = CameraController(
          cameras[selectedCameraIndex],
          ResolutionPreset.max,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
        );
        await cameraController?.initialize();
        if (mounted) {
          setState(() {});
          cameraController?.startImageStream(_processCameraImage);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera initialization failed: $e')),
        );
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || _isProcessing || _verificationSteps[0].isCompleted) return;
    _isBusy = true;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isBusy = false;
      return;
    }

    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
      ),
    );
    final faces = await faceDetector.processImage(inputImage);
    faceDetector.close();

    if (faces.isNotEmpty) {
      await DetectionUtils.detect(
        face: faces.first,
        step: M7LivelynessStep.blink,
        onCompleteStep: (step) async {
          _verificationSteps[0] = _verificationSteps[0].copyWith(isCompleted: true);
          await _takePicture();
        },
        onStartProcessing: () {
          setState(() => _isProcessing = true);
        },
        onSetDidCloseEyes: () {
          if (!_didCloseEyes) {
            setState(() => _didCloseEyes = true);
          }
        },
      );

      // Check for eyes reopening to complete blink
      if (_didCloseEyes &&
          (faces.first.leftEyeOpenProbability ?? 1.0) > 0.75 &&
          (faces.first.rightEyeOpenProbability ?? 1.0) > 0.75) {
        _verificationSteps[0] = _verificationSteps[0].copyWith(isCompleted: true);
        await _takePicture();
      }
    }

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (cameraController == null) return null;
    final camera = cameras[selectedCameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      final orientation = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      }[cameraController!.value.deviceOrientation] ?? 0;
      rotation = InputImageRotationValue.fromRawValue(
        camera.lensDirection == CameraLensDirection.front
            ? (sensorOrientation + orientation) % 360
            : (sensorOrientation - orientation + 360) % 360,
      );
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _takePicture() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;
    setState(() => _isProcessing = true);
    try {
      await cameraController?.stopImageStream();
      final XFile image = await cameraController!.takePicture();
      File pictureFile = File(image.path);
      await _uploadImages(pictureFile, widget.uid, 0);
      print("Photo Saved: ${image.path}");
      if (mounted) {
        if (widget.home_camera == 'camera') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => Camera(uid: widget.uid)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(uid: widget.uid)));
        }
      }
    } catch (e) {
      print("Error capturing photo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _uploadImages(File imageFile, String uid, int numEmbeddings) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5001/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      request.fields['uid'] = uid;
      request.fields['num_embeddings'] = numEmbeddings.toString();
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print("Response Status: ${response.statusCode}");
      print("Response Body: $responseBody");
      if (response.statusCode == 200) {
        print("Upload successful!");
      } else {
        print("Upload failed: ${response.reasonPhrase}");
        if (mounted) {
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

  void _switchCamera() {
    if (cameras.length > 1) {
      selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;
      _setupCameraController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Face Setup'),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.fitWidth,
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.65,
                width: MediaQuery.sizeOf(context).width,
                child: CameraPreview(cameraController!),
              ),
            ),
            if (_isProcessing)
              const CircularProgressIndicator()
            else
              Text(
                _didCloseEyes ? 'Open your eyes to complete blink' : 'Blink to capture your photo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Container()),
                if (cameras.length > 1)
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, size: 50),
                    onPressed: _isProcessing ? null : _switchCamera,
                  )
                else
                  Expanded(child: Container()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}