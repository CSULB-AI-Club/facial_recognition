import 'package:facial_recognition/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:facial_recognition/pages/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facial_recognition/pages/institution_connect.dart';


class InstitutionsPage extends StatefulWidget {
  final String uid;
  const InstitutionsPage({super.key, required this.uid});

  @override
  State<InstitutionsPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<InstitutionsPage> {
  @override
  Widget build(BuildContext context) {
    double myWidth = MediaQuery.sizeOf(context).width;
    double myHeight = MediaQuery.sizeOf(context).height;
    return Scaffold(
      appBar: AppBar(
        title: Text("Institutions"),
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
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('institutions').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              final institutions = snapshot.data!.docs;
              return ListView.builder(
                itemCount: institutions.length,
                itemBuilder: (context, index) {
                  
                  final institution = institutions[index];
                  final data = institution.data();
          
                  if (data == null || data is! Map<String, dynamic>) {
                    return SizedBox();
                  }

                                
                  return connectionOption(
                    data['name'] ?? 'Unknown Institution',
                    context,
                    data['institution_id'] ?? 'Unknown ID',
                    data['api_key'] ?? 'Unknown API Key',
                  );
                  
                },
              );
            }
          ),
        )
      )
    );
  }
    Widget connectionOption(String title, BuildContext context, inst_id, api_Key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.95,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InstitutionConnect(
                  institution_id: inst_id,
                  uid: widget.uid,
                  institution_name: title,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: Colors.black,
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