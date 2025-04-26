import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:facial_recognition/pages/login.dart';
import 'package:facial_recognition/pages/face_setup.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: FaceSetup(uid: "S08V3BiGm7hrpvxvjwnnjfcjUyn2", home_camera: "home"), // Change to your desired initial page
    );
  }
}