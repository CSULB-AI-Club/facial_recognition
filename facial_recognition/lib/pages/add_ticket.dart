import 'package:flutter/material.dart';

class AddTicket extends StatelessWidget{
  const AddTicket({super.key}) ;


  @override
Widget build(BuildContext context){
    double myWidth = MediaQuery.sizeOf(context).width;
    double myHeight = MediaQuery.sizeOf(context).height;
    return Scaffold(
        appBar: appBar(context),
        body: 
        Container(
          height: myHeight,
          width: myWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromRGBO(30, 90, 112, 1),Color.fromRGBO(57, 171, 214, 1)]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(45), topRight: Radius.circular(45)),
          ),
          
              ),
              );
              }
    AppBar appBar(BuildContext context) {
    return AppBar(
        title: Text('Add Ticket'),
        centerTitle: true,
        
        
      );
  }
}