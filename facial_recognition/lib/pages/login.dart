import 'package:facial_recognition/pages/forget_password.dart';
import 'package:facial_recognition/pages/home.dart';
import 'package:facial_recognition/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
<<<<<<< Updated upstream
class LogIn extends StatelessWidget {
  const LogIn({super.key});

  @override
=======
import 'package:facial_recognition/pages/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  _LogInState createState() => _LogInState();
}
class _LogInState extends State<LogIn> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String emailError = '';
  String passwordError = '';
  Future<void> signIn() async{
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    setState(() {
      emailError = '';
      passwordError = '';
    });

    if(email.isEmpty){
      setState(() {
        emailError = 'Please enter an email';
      });
    }
    if(password.isEmpty){
      setState(() {
        passwordError = 'Please enter a password';
      });
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      User? user = FirebaseAuth.instance.currentUser;

      if(user != null){
        print("Login Successful");
        Navigator.pushNamed(context, '/home');
      }
    }
    on FirebaseAuthException catch (e) {
      print("Error: ${e.code}");
      if(e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'invalid-email'){
        print("Email or password is invalid");
        setState(() {
          emailError = 'email or password is invalid';
          passwordError = 'email or password is invalid';
        });
      }
    }
  }

  @override
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
<<<<<<< Updated upstream
            Text("2FACE", style: TextStyle(
=======
            Text("Blinkey", style: TextStyle(
>>>>>>> Stashed changes
=======
            Text("BLINKEY", style: TextStyle(
>>>>>>> Stashed changes
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.normal),),
            Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
<<<<<<< Updated upstream
=======
              //EMAIL TEXTFIELD
>>>>>>> Stashed changes
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(15),
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                  hintText: 'Enter E-mail',
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
<<<<<<< Updated upstream
            SizedBox(height: 10),
=======
            if(emailError.isNotEmpty)
              SizedBox(height: 5),
              Text(
                emailError,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
>>>>>>> Stashed changes
            Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(15),
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: 'Enter Password',
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
            if(passwordError.isNotEmpty)
              SizedBox(height: 5),
              Text(
                passwordError,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 25),
                GestureDetector(
                onTap: () {
                Navigator.push(context, 
                MaterialPageRoute(builder: (context) => ForgotPassword()));
                
              } ,
                  //print("Forgot Password"),
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
              onTap: () {
                Navigator.push(context, 
                MaterialPageRoute(builder: (context) => HomePage()));
                
              } ,
              //print("Log In"),
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
              onTap:() {
                Navigator.push(context, 
                MaterialPageRoute(builder: (context) => SignUp()));
              },
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