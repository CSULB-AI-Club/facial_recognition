import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUp extends StatefulWidget {
  @override
  State<SignUp> createState() => _SigninState();
}

class _SigninState extends State<SignUp> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  Future<void> signUp() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirm = confirmController.text.trim();
    if (password != confirm) {
      print("Passwords do not match");
      return;
    }
    else {
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/create_user'),
          headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password
        }),
        );
        if (response.statusCode == 200) {
          print("Registration Successful");
          Navigator.pushNamed(context, '/home');
        }
        else {
          print("Registration Failed");
        }
      } 
      catch (e) {
        print("Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context){
    return Material(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, 
          children: [
            SizedBox(height: 125),
            Text("Register", 
              textAlign: TextAlign.center,
              style: TextStyle(
              color: Colors.black,
              fontSize: 50,
              fontWeight: FontWeight.bold,
              ),),
            Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
              //EMAIL TEXTFIELD
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                  hintText: 'Enter E-mail',
                  labelStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  hintStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Opacity(
                      opacity: 0.5,
                      child: SvgPicture.asset('assets/icons/mail.svg'),)
                  )
                ),
              ),
            ),
            Padding(
              //PASSWORD TEXTFIELD
              padding: EdgeInsets.only(top:10, left:20, right:20, bottom: 10),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: 'Enter Password',
                  labelStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  hintStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Opacity(
                      opacity: 0.5,
                      child: SvgPicture.asset('assets/icons/key.svg'),)
                  )
                ),
              )
            ),
            Padding(
              //CONFIRM PASSWORD TEXTFIELD
              padding: EdgeInsets.only(top:10, left:20, right:20, bottom:10),
              child: TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter Password',
                  labelStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  hintStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Opacity(
                      opacity: 0.5,
                      child: SvgPicture.asset('assets/icons/key.svg'),)
                  )
                ),
              )
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () => signUp(),
              child: Container(
                width: 200,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xff9F1FFF),
                  border: Border.all(
                    color: Color.fromARGB(255, 192, 113, 253),
                    width: 5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text("Register", style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
                ),
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text("Back to Log In", style: TextStyle(
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
