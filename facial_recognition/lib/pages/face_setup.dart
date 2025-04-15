
import 'package:camera/camera.dart';
import 'package:facial_recognition/pages/camera.dart';
// import 'package:eyeblinkdetectface/index.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:eyeblinkdetectface/index.dart';

class FaceSetup  extends StatefulWidget{
  final String email;
  final String password;
  const FaceSetup({super.key, required this.email, required this.password});


  @override
  State<FaceSetup> createState() => _FaceSetupState();

}

class _FaceSetupState extends State<FaceSetup> with WidgetsBindingObserver{
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  int selectedCameraIndex = 0;
  bool _isCapturingBurst = false;
  // final bool_isLoading = false;
  // bool _startWithInfo = true;
  // bool _allowAfterTimeOut = false;
  // final List<M7LivelynessStepItem> _verificationSteps = [];
  // int _timeOutDuration = 60;



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if(cameraController == null || cameraController?.value.isInitialized ==false){
      return;
    }
    if(state == AppLifecycleState.inactive){
      cameraController?.dispose();
    }else if(state == AppLifecycleState.resumed){
      _setupCameraController();
    }
  }
  Future<void> _captureBurstPhotos(int count, int interval) async {
    if (cameraController == null || cameraController?.value.isInitialized == false) {
      return;
    }
    setState(() => _isCapturingBurst = true);
    for (int i = 0; i < count; i++) {
      try {
        XFile picture = await cameraController!.takePicture();
        File pictureFile = File(picture.path);
        await _uploadImages(File(pictureFile.path), widget.email, widget.password, i);
        print("Burst Photo $i Saved: ${picture.path}");
      } catch (e) {
        print("Error in burst capture: $e");
        break;
      }
      await Future.delayed(Duration(milliseconds: interval));
    }
    setState(() => _isCapturingBurst = false);
    Navigator.push(context,  MaterialPageRoute(builder: (context) => Camera(email: widget.email, password: widget.password)));
  }

  Future<void> _uploadImages(File imageFile, String email, String password, int numEmbeddings) async {
    try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.0.163:5001/upload'),
    );
    
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password
    );
    User? user = FirebaseAuth.instance.currentUser;

    request.fields['uid'] = user!.uid;
    request.fields['num_embeddings'] = numEmbeddings.toString();
    var response = await request.send();

    if (response.statusCode == 200) {
      print("Upload successful!");
    } else {
      print("Upload failed: ${response.reasonPhrase}");
    }
  } catch (e) {
    print("Error uploading image: $e");
  }

  }

  @override
  void initState(){
    // _initValues();
    super.initState();
    _setupCameraController();
    // WidgetsBinding.instance.addPostFrameCallback((_){
    //   detectBlink(context);
    // });
  }

  // void _initValues(){
  //   _verificationSteps.addAll(
  //     [
  //       M7LivelynessStepItem(
  //         step: M7LivelynessStep.blink,
  //         title: '1. Blink',
  //         isCompleted: false
  //       ),
  //       M7LivelynessStepItem(
  //         step: M7LivelynessStep.blink,
  //         title: '2. Blink',
  //         isCompleted: false
  //       ),
  //     ]
  //   );
  //   Eyeblinkdetectface.instance.configure(
  //     contourColor: Colors.blue,
  //     thresholds: [
  //       M7BlinkDetectionThreshold(
  //         leftEyeProbability: 0.25,
  //         rightEyeProbability: 0.25,
  //       ),
  //       M7BlinkDetectionThreshold(
  //         leftEyeProbability: 0.25,
  //         rightEyeProbability: 0.25,
  //       ),
  //     ]
  //   );
  // }

  // Future<void> detectBlink(BuildContext context) async {
  //   final config = M7DetectionConfig(
  //     steps: [
  //       M7LivelynessStepItem(
  //         step: M7LivelynessStep.blink, 
  //         title: 'Blink', 
  //         isCompleted: false,)
  //     ],
  //     startWithInfoScreen: _startWithInfo,
  //     maxSecToDetect: _timeOutDuration == 100? 2500: _timeOutDuration,
  //     allowAfterMaxSec: _allowAfterTimeOut,
  //     captureButtonColor: Colors.red,
  //     );
  //     final String? response = await Eyeblinkdetectface.instance.detectLivelyness(
  //       context, 
  //       config: config);
      
  //     if (response != null){
  //       print("Detected blinking, snapping pictures.");
  //       _captureBurstPhotos(3, 10);
  //     }
  // }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: _buildUI(),
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Face Setup'),
      ),
  );

}
Widget _buildUI(){
  if (cameraController == null || cameraController?.value.isInitialized == false){
    return const Center(child: CircularProgressIndicator(),);
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
          height: MediaQuery.sizeOf(context).height*0.65,
          width: MediaQuery.sizeOf(context).width,
          child: CameraPreview(
            cameraController!,
          ),
          )

        ),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(),
          ),
            IconButton(
            onPressed: _isCapturingBurst ? null : () => _captureBurstPhotos(3, 0),
            iconSize: 90,
            icon: const Icon(
            Icons.camera,
            color: Colors.red,
            ), 
          
          ),
          Expanded(child: Align(
            alignment: Alignment.center,
            child :IconButton(
            icon: const Icon(Icons.flip_camera_ios, size: 50),
            onPressed: _switchCamera, 
           ),
            ),),

            
          
      
        ],
      ),
      ],
    ),
  ),
  );
}

 Future<void> _setupCameraController() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      cameraController = CameraController(
        cameras[selectedCameraIndex],
        ResolutionPreset.max,
      );
      await cameraController?.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _switchCamera() {
    if (cameras.isNotEmpty) {
      selectedCameraIndex = (selectedCameraIndex + 1) % 2;
      _setupCameraController();
    }
  }
}


