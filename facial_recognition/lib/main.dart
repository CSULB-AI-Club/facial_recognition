import 'package:facial_recognition/pages/logo.dart';
import 'package:flutter/material.dart';
import 'package:facial_recognition/pages/login.dart';
//import 'package:firebase_core/firebase_core.dart';

void main() async{
  //WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp(options: 
  //DefaultFirebaseOptions.currentPlatform);
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
<<<<<<< Updated upstream
      home: LogIn()
=======
      //home: BlinkeyLogo(),
      home: BlinkeyReveal(),
      routes: {
        '/home': (context) => LogIn(), // Define the login route if needed
      },
>>>>>>> Stashed changes
    );
  }
}