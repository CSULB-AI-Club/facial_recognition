import 'package:facial_recognition/pages/logo.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:facial_recognition/pages/login.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:facial_recognition/pages/home.dart';
import 'package:facial_recognition/pages/face_setup.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
      //home: LogIn(),
      home: BlinkeyReveal(),
    );
  }
}