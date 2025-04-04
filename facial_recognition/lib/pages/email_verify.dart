import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:facial_recognition/pages/face_setup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailVerify extends StatefulWidget {
  final String email;
  final String password;
  final String first_name;
  final String last_name;

  const EmailVerify({super.key, required this.email, required this.password, required this.first_name, required this.last_name});

  @override
  State<EmailVerify> createState() => _EmailVerifyState();
}

class _EmailVerifyState extends State<EmailVerify> {
  String verifyError = '';
  Future<void> VerifyEmail() async{
    setState((){
      verifyError = '';
    });
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: widget.email, password: widget.password);
    User? user = FirebaseAuth.instance.currentUser;

    if(user!= null){
      if(!user.emailVerified){
        setState((){
           verifyError = 'Email not verified, please check your email.';
        });
      }
      else{
        print("Email if verified, moving to camera page");
        final response = await http.post(
          Uri.parse('http://192.168.0.124:5001/create_user'),
          headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': widget.email,
          'password': widget.password,
          'first_name': widget.first_name,
          'last_name': widget.last_name
        }),
        );
        Navigator.push(context,  MaterialPageRoute(builder: (context) => FaceSetup(email: widget.email, password: widget.password)));
      }

    }
  }
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Color(0xff9F1FFF),
                  width: 2
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    SvgPicture.asset('assets/icons/mail.svg', width: 80, height:80),
                    Text("Verify your email address",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15
                    ),
                    ),
                    SizedBox(height: 10),
                    Divider(
                      color: Colors.grey,
                      thickness: 1,
                      indent: 30,
                      endIndent: 30,
                    ),
                    Padding(padding: EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 25), 
                    child: Text("An email has been sent to your account.\nPlease follow the instructions in email and click the button when verified.", 
                    textAlign: TextAlign.center,
                    )),
                    GestureDetector(
                      onTap: () => VerifyEmail(),
                      child: Container(
                        height: 60,
                        width: 200,
                        decoration: BoxDecoration(
                            color: Color(0xff9F1FFF),
                            border: Border.all(
                              color: Color.fromARGB(255, 192, 113, 253),
                              width: 5
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        child: Center(
                          child: Text("Verify Your Email", style: TextStyle(
                            color: Colors.white, 
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                            ))
                        ),
                      ),
                    ),
                    if(verifyError.isNotEmpty)
                      Text(
                        verifyError,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                )
              )
            )
          ],
        ),
      )

    );
  }
}