//import 'package:facial_recognition/pages/add_ticket.dart';
import 'package:facial_recognition/pages/camera.dart';
import 'package:facial_recognition/pages/login.dart';
import 'package:facial_recognition/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facial_recognition/pages/face_setup.dart';
import 'package:facial_recognition/pages/settings.dart';
//import 'package:facial_recognition/models/tickets.dart';

class HomePage extends StatelessWidget{
  final String uid;
  HomePage({super.key, required this.uid});
  //List <Tickets> tickets = [];



  @override
  Widget build(BuildContext context){
    double myWidth = MediaQuery.sizeOf(context).width;
    double myHeight = MediaQuery.sizeOf(context).height;
    //tickets = Tickets.getTickets();
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 252, 251, 251),
        body: 
        Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData){
                  return Center(child: CircularProgressIndicator());
                }
                final userData = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 0.175 * MediaQuery.of(context).devicePixelRatio * 160),
                    Padding(padding: EdgeInsets.only(left: 15, bottom: 5),
                    child: Row(
                      children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(5),
                          child: Opacity(opacity: 0.85,
                          child: SvgPicture.asset('assets/icons/user_avatar.svg', 
                          fit: BoxFit.cover))
                        )
                      ),
                      Spacer(),
                      blinkeyPopUp(context)
                    ],)
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25),
                      child: Opacity(opacity: 1,
                      child: Text('Welcome, ${userData['first_name']}', style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold), 
                      ))
                    ),
                    
                  ],
                );
              }
            ),
            //ticketing section for user
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('tickets').doc(uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                return SizedBox(); // Return an empty widget or appropriate fallback widget
              }
            )
          ],
        ),
      );

        
  }

  Padding blinkeyPopUp(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Theme(
        data: Theme.of(context).copyWith(
          popupMenuTheme: PopupMenuThemeData(
            color: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          )
        ),
        child: PopupMenuButton<int>(
          surfaceTintColor: Colors.white,
          icon: SvgPicture.asset('assets/icons/dots.svg', height: 30, width: 30),
          onSelected:(value){
            if (value == 1){
              Navigator.of(context).push(
                MaterialPageRoute(
                builder: (context) => FaceSetup(uid: uid)));
            }
            if (value == 2){
              Navigator.of(context).push(
                MaterialPageRoute(
                builder: (context) => SettingsPage()));
            }
            if (value == 3){
              Navigator.of(context).push(
                MaterialPageRoute(
                builder: (context) => LogIn()));
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: ListTile(
                leading: SvgPicture.asset('assets/icons/face_setup.svg', height: 24, width: 24),
                title: Text('Add Ticket/Pass'),
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: ListTile(
                leading: SvgPicture.asset('assets/icons/settings.svg', height: 24, width: 24),
                title: Text('Settings'),
              ),
            ),
            PopupMenuItem(
              value: 3,
              child: ListTile(
                leading: SvgPicture.asset('assets/icons/logout.svg', height: 24, width: 24),
                title: Text('Log out'),
                textColor: Colors.red,
              ),
            ),
          ],
          ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
        title: Text('Welcome User'),
        automaticallyImplyLeading: false,
        centerTitle: false,
        actions: [
        PopupMenuButton<int>(
        onSelected: (value){
        //  if (value == 1){
            //Navigator.of(context).push(
              //MaterialPageRoute(
              //builder: (context) => const AddTicket()),
          //  );
          //}
          if (value == 1){
            Navigator.of(context).push(
              MaterialPageRoute(
              //builder: (context) => const Settings()),
              builder: (context) =>  SettingsPage()),
            );
          }
          // if (value == 2){
          //   Navigator.of(context).push(
          //     MaterialPageRoute(
          //     builder: (context) => const FaceSetup(uid: uid)),
          //   );
          // }
          if (value == 3){
              Navigator.of(context).push(
              MaterialPageRoute(
              builder: (context) => LogIn()),
            );
          }
        },
        itemBuilder: (context)=>[
        //  PopupMenuItem(
        //    value: 1,
        //    child: ListTile(
        //      leading: SvgPicture.asset('assets/icons/add.svg', height: 24, width: 24),
        //      title: Text('Add Ticket/Pass'),
        //    ),
        //  ),
          PopupMenuItem(
            value: 1,
            child: ListTile(
              leading: SvgPicture.asset('assets/icons/settings.svg', height: 24, width: 24),
              title: Text('Settings'),
            ),
          ),
          PopupMenuItem(
            value: 3,
            child: ListTile(
              leading: SvgPicture.asset('assets/icons/logout.svg', height:24, width: 24) ,
              title: Text('Log out'),
              textColor: Colors.red,
            ),
          ),
              
        ],
        ),
    ],
        
      );
  }
}