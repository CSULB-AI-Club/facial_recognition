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
  const HomePage({super.key, required this.uid});
  //List <Tickets> tickets = [];

  void showActivationPopup(BuildContext context, String ticketName) {
  showDialog(
    context: context,
    barrierDismissible: false, // User must confirm
    builder: (context) {
      bool isLoading = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Activate Ticket", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Are you sure you want to activate \"$ticketName\"?",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                isLoading
                    ? Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text("Activating ticket...")
                        ],
                      )
                    : ElevatedButton(
                        onPressed: () {
                          setState(() => isLoading = true);

                          Future.delayed(Duration(seconds: 3), () {
                            Navigator.pop(context);
                            // TODO: Place ticket activation logic here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ticket "$ticketName" activated!')),
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text("Activate Now", style: TextStyle(fontSize: 18)),
                      ),
              ],
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context){
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
                    Padding(padding: EdgeInsets.only(left: 15),
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
            Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Container(
                  width: 1000,
                  height: 670,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                    colors: [Color.fromRGBO(30, 90, 112, 1), Color.fromRGBO(57, 171, 214, 1)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      topRight: Radius.circular(20),
                    )
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('tickets').where("user_id", isEqualTo: uid).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final tickets= snapshot.data!.docs;
                      if(tickets.isEmpty){
                        return Center(
                          child: Text(
                            'No Tickets Found',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: tickets.length,
                        itemBuilder: (context, index){
                          try {
                            final ticket = tickets[index];
                            final data = ticket.data() as Map<String, dynamic>;
                            // print(data);
                            final ticket_name = data['name'] ?? 'Unknown Ticket';
                            final ticket_id = data['ticket_id'] ?? 'Unknown Ticket ID';
                            final description = data['description'] ?? 'No description available'; 
                            print(ticket_name);
                            return ticketObject(ticket_name, context, ticket_id, description);
                          } catch (e) {
                            return Center(child: Text('Error loading ticket'));
                          }
                        }
                      );// Return an empty widget or appropriate fallback widget
                    }
                  )
                ),
              )
          ],
        ),
      );

        
  }
Widget ticketObject(String title, BuildContext context, String ticket_id, String description) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
    width: double.infinity,
    height: 150,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
    ),
    child: Material( // Needed to show ripple effect inside decorated container
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showActivationPopup(context, title);
        },
        child: Row(
          children: [
            // Stub on left
            Container(
              width: 80,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),

            // Ticket info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text(description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
                builder: (context) => SettingsPage(uid: uid)));
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
                title: Text('Setup Face ID'),
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
              builder: (context) =>  SettingsPage(uid: uid)),
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