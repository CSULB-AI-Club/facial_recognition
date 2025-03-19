//import 'package:facial_recognition/pages/add_ticket.dart';
import 'package:facial_recognition/pages/camera.dart';
import 'package:facial_recognition/pages/login.dart';
import 'package:facial_recognition/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
//import 'package:facial_recognition/models/tickets.dart';

class HomePage extends StatelessWidget{
  HomePage({super.key});
  //List <Tickets> tickets = [];



  @override
  Widget build(BuildContext context){
    double myWidth = MediaQuery.sizeOf(context).width;
    double myHeight = MediaQuery.sizeOf(context).height;
    //tickets = Tickets.getTickets();
    return Scaffold(
        appBar: appBar(context),
        body: 
        Container(
          height: myHeight,
          width: myWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromRGBO(30, 90, 112, 1),Color.fromRGBO(57, 171, 214, 1)],
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(45), topRight: Radius.circular(45)),
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                    EdgeInsets.only(top: 20, left: 15),
                  child: 
                      Text('Tickets/Passes:',
                        style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
              ),
              ),
                  ),
                SizedBox(height: myHeight * 0.02),
                Column(
                  children: 
                [
                  Align(
                    alignment: Alignment(0.8,0),
                  child:ElevatedButton(onPressed: (){}, 
                  child: Text('Edit')
                  ),),
                  SizedBox(height:35),
                  SizedBox( 
                  width: myWidth*0.95,
                  height: myHeight*0.19,
                  child:ElevatedButton(onPressed: (){
                  Navigator.push(context, 
                  MaterialPageRoute(builder: (context) => Camera()));
                
              } , 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20) ),
                      
                  ),
                  child: Text('Ticket 1'),
                  ),),
                  SizedBox(height: 30),
                  SizedBox( 
                  width: myWidth*0.95,
                  height: myHeight*0.19,
                  child:ElevatedButton(onPressed: (){
                  Navigator.push(context, 
                  MaterialPageRoute(builder: (context) => Camera()));
                
              } ,  
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20) ),
                  ),
                  child: Text('Ticket 2'),
                  ),),

                  SizedBox(height: 30,),
                  SizedBox( 
                  width: myWidth*0.95,
                  height: myHeight*0.19,
                  child:ElevatedButton(onPressed: (){
                  Navigator.push(context, 
                  MaterialPageRoute(builder: (context) => Camera()));
                
              } , 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                      
                  ),
                  child: Text('Ticket 3'),
                  ),),
                ],)
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
              builder: (context) =>  Settings()),
            );
          }
          if (value == 2){
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
            value: 2,
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