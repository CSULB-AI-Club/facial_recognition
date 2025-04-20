import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConnectionsPage extends StatelessWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    double myWidth = MediaQuery.sizeOf(context).width;
    double myHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Connections'),
        centerTitle: true,
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
            Padding(
              padding: EdgeInsets.only(top: 20, left: 15),
              child: Text(
                'Connected Institutions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: myHeight * 0.02),
            StreamBuilder<QuerySnapshot>(
              stream: null,
              builder: (context, snapshot) {
                return Column(
                  children: [
                    connectionOption('CSULB', 'assets/icons/CSULB.svg', context),
                    connectionOption('Fandango', 'assets/icons/fandango.svg', context),
                    connectionOption('Disneyland', 'assets/icons/DisneyLand.svg', context),
                    connectionOption('TicketMaster', 'assets/icons/ticketmaster.svg', context),
                    connectionOption('Add New Institution', 'assets/icons/add_institution.svg', context, isAddNew: true),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget connectionOption(String title, String assetPath, BuildContext context, {bool isAddNew = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.95,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            // Add navigation or functionality here
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isAddNew ? Colors.green : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(assetPath, height: 24, width: 24, color: isAddNew ? Colors.white : Colors.black),
              SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: isAddNew ? Colors.white : Colors.black,
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