//import 'package:facial_recognition/pages/add_ticket.dart';
import 'package:facial_recognition/pages/camera.dart';
import 'package:facial_recognition/pages/login.dart';
import 'package:facial_recognition/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facial_recognition/pages/face_setup.dart';
import 'package:facial_recognition/pages/settings.dart';
import 'package:facial_recognition/pages/widgets/hold_button.dart';
import 'package:flutter/services.dart';
//import 'package:facial_recognition/models/tickets.dart';

class HomePage extends StatelessWidget{
  final String uid;
  const HomePage({super.key, required this.uid});
  //List <Tickets> tickets = [];
  

  Future<void> activateTicket() async {
    // Simulate a network call to activate the ticket
    // DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    // var detection = userDoc.data()?['detection'] ?? false;
    // await Future.delayed(Duration(seconds: 1));
    FirebaseFirestore.instance.collection('users').doc(uid).update({
        'detection': true,
      });
      await Future.delayed(Duration(seconds: 15));
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'detection': false,
      });
    // Here you would typically call your activation function
    // For example:
    // await activateTicket(ticketId);
  }

  void showActivationPopup(BuildContext context, String ticketName, String ticket_description, String status) {
  showDialog(
    context: context,
    barrierDismissible: true, // User must confirm
    builder: (context) {
      bool isLoading = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Activate Ticket", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ticketName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                SizedBox(height: 10),
                Text(
                  ticket_description,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  "Are you sure you want to activate this ticket?",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
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
                    : HoldToConfirmButton(
                        holdDuration: Duration(seconds: 2),
                        onConfirmed: () async{
                          setState(() {
                            isLoading = true;
                          });
                          HapticFeedback.mediumImpact();
                          // Simulate a network call
                          await Future.delayed(Duration(seconds: 1));
                          // Here you would typically call your activation function
                          // For example:
                          
                          setState(() {
                            isLoading = false;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Ticket Activated!", textAlign: TextAlign.center,)),
                          );
                        },
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
                      padding: const EdgeInsets.only(left: 25,),
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
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.778,
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
                      tickets.sort((a, b){
                        final aDate = (a.data() as Map<String, dynamic>)['status'] ?? '';
                        final bDate = (b.data() as Map<String, dynamic>)['status'] ?? '';
                        int TicketSort(String status){
                          switch(status){
                            case 'Active':
                              return 0;
                            case 'Upcoming':
                              return 1;
                            case 'Expired':
                              return 2;
                            default:
                              return 3;
                          }
                        }
                        return TicketSort(aDate).compareTo(TicketSort(bDate));
                      });
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
                            final status = data['status'] ?? 'Unknown Status';
                            return ticketObject(ticket_name, context, ticket_id, description, status);
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
Widget ticketObject(String title, BuildContext context, String ticket_id, String description, String status) {
  bool isDisabled = (status == 'Expired' || status == 'Upcoming');
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
        onTap: isDisabled ? null: 
        () {
          showActivationPopup(context, title, description, status);
        },
        child: Row(
          children: [
            // Stub on left
            Container(
              width: 60,
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDisabled? Colors.grey: Colors.black),),
                    SizedBox(height: 10),
                    Text(description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: isDisabled? Colors.grey: Colors.black)),
                    Text("Status: $status",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDisabled? Colors.grey: Colors.black)),
                    SizedBox(height: 10),
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
