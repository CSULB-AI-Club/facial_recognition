import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:facial_recognition/pages/signup.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  _LogInState createState() => _LogInState();
}
class _LogInState extends State<LogIn> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  Future<void> signIn() async{
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    try {

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/authenticate'), //sends to the backend
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password
        }),
        
      );
      if (response.statusCode == 200) {
        print("Login Successful");
        Navigator.pushNamed(context, '/home');
      }
      else {
        print("Login Failed");
      }
    }
    catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, 
          children: [
            SizedBox(height: 200),
            Text("Welcome", 
              style: TextStyle(
              color: Colors.black,
              fontSize: 60,
              fontWeight: FontWeight.bold,
              height: 0.9),),
            Text("2FACE", style: TextStyle(
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.normal),),
            Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
              //EMAIL TEXTFIELD
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(15),
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                  hintText: 'Enter E-mail',
                  labelStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  hintStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Opacity(
                    opacity: 0.5,
                    child: SvgPicture.asset('assets/icons/mail.svg')),
                  ),
                )
              )
            ),
            Padding(
              //PASSWORD TEXTFIELD
              padding: EdgeInsets.only(top: 10, left: 20, right: 20),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(15),
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: 'Enter Password',
                  labelStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  hintStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Opacity(
                    opacity: 0.5,
                    child: SvgPicture.asset('assets/icons/key.svg')),
                  ),
                )
              )
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 25),
                GestureDetector(
                  onTap:() => print("Forgot Password"),
                  child: 
                    Text("Forgot your password?", style: TextStyle(
                    color: Color(0xff9F1FFF),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    
                  ))
                ),
              ],
            ),
            SizedBox(height: 50),
            GestureDetector(
              onTap: () => signIn(),
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
                  child: Text("Log In", style: TextStyle(
                    color: Colors.white, 
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                    ))
                ),
              ),
            ),
            SizedBox(height: 5),
            GestureDetector(
              onTap:() => Navigator.push(context, MaterialPageRoute(builder: (context) => SignUp())),
              child: Text("Create an Account", style: TextStyle(
                color: Color(0xff9F1FFF),
                fontSize: 15,
                fontWeight: FontWeight.bold
              ))
            )
          ],
        )
      )
    );
  }
}
