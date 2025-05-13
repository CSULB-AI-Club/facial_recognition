
import 'package:facial_recognition/pages/institution_page.dart';
import 'package:facial_recognition/pages/login.dart';
import 'package:flutter/material.dart';


class SettingsPage extends StatelessWidget {
  final String uid;
  const SettingsPage({super.key, required this.uid});
  // const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    double myWidth = MediaQuery.sizeOf(context).width;
    double myHeight = MediaQuery.sizeOf(context).height;

    void _showLogoutDialog(BuildContext context) {
      showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text("Log Out"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: Text("Log Out", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close the dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LogIn()),
                (route) => false, // Clear navigation stack
              );
            },
          ),
        ],
      );
    },
  );
}


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
                settingOption('Profile', Icons.person, context,() => Navigator.push(context, MaterialPageRoute(builder: (context) => InstitutionPage()))),
                settingOption('Privacy & Security', Icons.lock, context,() => Navigator.push(context, MaterialPageRoute(builder: (context) => InstitutionPage()))),
                settingOption('Connect to Insitution', Icons.connect_without_contact , context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => InstitutionPage()))),
                settingOption('Log Out', Icons.exit_to_app, context, () => _showLogoutDialog (context), isLogout: true,),
                //Navigator.push(context, MaterialPageRoute(builder: (context) => LogIn())), isLogout: true),
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