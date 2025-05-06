import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:facial_recognition/pages/email_verify.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SigninState();
}

class _SigninState extends State<SignUp> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  String passwordError = '';
  String emailError = '';
  String confirmError = '';
  String firstNameError = '';
  String lastNameError = '';
  Future<void> signUp() async {
    String firstname = firstnameController.text.trim();
    String lastname = lastnameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirm = confirmController.text.trim();
    setState(() {
      emailError = '';
      passwordError = '';
      confirmError = '';
      firstNameError = '';
      lastNameError = '';
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
    if (password != confirm) {
      setState(() {
        confirmError = 'Passwords do not match';
        passwordError = 'Passwords do not match';
      });
      return;
    }
    if (firstname.isEmpty){
      print('firstname empty');
      setState(() {
        firstNameError = 'Enter a first name';
      });
    }
    if(lastname.isEmpty){
      print('lastname is empty');
      setState(() {
        lastNameError = 'Enter a last name';
      });
    }
    else {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password
        );
        print("Sign Up Successful: ${userCredential.user}");
        await userCredential.user?.sendEmailVerification();
        print("Registration Successful. Verification Email Sent.");
        Navigator.push(context, MaterialPageRoute(builder: (context) => EmailVerify(email: email, password: password, first_name: firstname, last_name: lastname)));
      } 
      on FirebaseAuthException catch (e) {
        print("Error: ${e.code}");
        if(e.code == 'email-already-in-use'){
          setState(() {
            emailError = 'Email is already in use.';
          });
        }
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
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
              //FIRST NAME TEXTFIELD
              child: TextField(
                controller: firstnameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'First Name',
                  hintText: 'Enter First Name',
                  labelStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  hintStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                ),
              ),
            ),
            if(firstNameError.isNotEmpty)
              Text(
                firstNameError,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
              //LAST NAME TEXTFIELD
              child: TextField(
                controller: lastnameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Last Name',
                  hintText: 'Enter Last Name',
                  labelStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                  hintStyle: TextStyle(color: Colors.black.withValues(alpha: .3)),
                ),
              ),
            ),
            if(lastNameError.isNotEmpty)
              Text(
                lastNameError,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 5),
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
            if(emailError.isNotEmpty)
              Text(
                emailError,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            Padding(
              //PASSWORD TEXTFIELD
              padding: EdgeInsets.only(top:10, left:20, right:20, bottom: 5),
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
            if(passwordError.isNotEmpty)
              Text(
                passwordError,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            Padding(
              //CONFIRM PASSWORD TEXTFIELD
              padding: EdgeInsets.only(top:10, left:20, right:20, bottom: 5),
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
            if(confirmError.isNotEmpty)
              Text(
                confirmError,
                style: TextStyle(color: Colors.red, fontSize: 12),
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
