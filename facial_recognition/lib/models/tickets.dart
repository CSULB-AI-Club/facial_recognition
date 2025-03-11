import 'package:flutter/material.dart';

class Tickets {
  String name;
  String time;
  Color boxColor;

  Tickets({
    required this.name,
    required this.time,
    required this.boxColor,
  });

  static List<Tickets> getTickets() {
    List<Tickets> tickets = [];

    tickets.add(
      Tickets(
        name: 'SWRC Pass', 
        time: '24/7',
        boxColor: Color(0xD9D9D9D9),
        )
    );
    tickets.add(
      Tickets(
        name: 'Captain America', 
        time: '6:00pm',
        boxColor: Color(0xD9D9D9D9)
        )
    );

    tickets.add(
      Tickets(
        name: 'Disneyland', 
        time: '24/7',
        boxColor: Color(0xD9D9D9D9)
        )
    );  
      
    return tickets; 

  }
}
