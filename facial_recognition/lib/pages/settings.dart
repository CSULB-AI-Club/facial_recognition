import 'package:facial_recognition/pages/insitution_page.dart';
import 'package:facial_recognition/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double myWidth = MediaQuery.sizeOf(context).width;
    double myHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: false,
      ),
      body: Container(
        height: myHeight,
        width: myWidth,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromRGBO(30, 90, 112, 1), Color.fromRGBO(57, 171, 214, 1)],
          ),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(45), topRight: Radius.circular(45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: myHeight * 0.02),
            Column(
              children: [
                settingOption('Profile', Icons.person, context,() => Navigator.push(context, MaterialPageRoute(builder: (context) => InsitutionPage()))),
                settingOption('Privacy & Security', Icons.lock, context,() => Navigator.push(context, MaterialPageRoute(builder: (context) => InsitutionPage()))),
                settingOption('Connect to Insitution', Icons.connect_without_contact , context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => InsitutionPage()))),
                settingOption('Log Out', Icons.exit_to_app, context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => LogIn())), isLogout: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget settingOption(String title, IconData icon, BuildContext context, VoidCallback onPressed, {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.95,
        height: 60,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLogout ? Colors.red : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: isLogout ? Colors.white : Colors.black),
              SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: isLogout ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}