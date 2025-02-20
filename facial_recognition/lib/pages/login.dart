import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
class LogIn extends StatelessWidget {
  const LogIn({super.key});

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
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
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
            SizedBox(height: 10),
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
              onTap: () => print("Log In"),
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
              onTap:() => print("Wants to make Account"),
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