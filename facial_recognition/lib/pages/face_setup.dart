
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class FaceSetup  extends StatefulWidget{
  const FaceSetup({super.key});


  @override
  State<FaceSetup> createState() => _FaceSetupState();

}

class _FaceSetupState extends State<FaceSetup> with WidgetsBindingObserver{
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  int selectedCameraIndex = 0;
  bool _isCapturingBurst = false;


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
        File picture_File = File(picture.path);
        await _uploadImages(File(picture_File.path));
        print("Burst Photo $i Saved: ${picture.path}");
      } catch (e) {
        print("Error in burst capture: $e");
        break;
      }
      await Future.delayed(Duration(milliseconds: interval));
    }
    setState(() => _isCapturingBurst = false);
    Navigator.pushNamed(context, '/home');
  }

  Future<void> _uploadImages(File imageFile) async {
    try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.0.163:5001/upload'),
    );

    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

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
    super.initState();
    _setupCameraController();
  }

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
            onPressed: _isCapturingBurst ? null : () => _captureBurstPhotos(3, 100),
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


