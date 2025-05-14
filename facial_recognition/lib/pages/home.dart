//import 'package:facial_recognition/pages/add_ticket.dart';
import 'package:facial_recognition/pages/institution_page.dart';
import 'package:facial_recognition/pages/login.dart';
import 'package:facial_recognition/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facial_recognition/pages/face_setup.dart';
import 'package:facial_recognition/pages/widgets/hold_button.dart';
import 'package:flutter/services.dart';
import 'package:facial_recognition/services/ticket_service.dart';
import 'dart:async';
//import 'package:facial_recognition/models/tickets.dart';

class HomePage extends StatefulWidget {
  final String uid;
  const HomePage({super.key, required this.uid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Track active tickets and their timers
  Map<String, Timer> _ticketTimers = {};
  Map<String, DateTime> _expiryTimes = {};

  @override
  void dispose() {
    // Cancel all running timers when the page is disposed
    _ticketTimers.forEach((_, timer) => timer.cancel());
    super.dispose();
  }

  Future<void> activateTicket(String ticketId) async {
    try {
      print("Activating ticket $ticketId for user ${widget.uid}");
      
      // Call the API to activate the ticket
      final result = await TicketService.activateTicket(ticketId, widget.uid);
      print("API response: $result");
      
      // Get the expiry time from the API response
      final expiresAt = DateTime.parse(result['expires_at']);
      final durationMinutes = result['expires_in_minutes'] as int;
      
      print("Ticket activated successfully. Expires in $durationMinutes minutes at $expiresAt");
      
      // Update the UI to show the countdown
      setState(() {
        _expiryTimes[ticketId] = expiresAt;
      });

      // Set up a timer to update the countdown every second
      _ticketTimers[ticketId]?.cancel();  // Cancel any existing timer
      _ticketTimers[ticketId] = Timer.periodic(Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        final now = DateTime.now();
        if (now.isAfter(expiresAt)) {
          // Timer has expired
          print("Ticket $ticketId activation expired");
          timer.cancel();
          if (mounted) {
            setState(() {
              _expiryTimes.remove(ticketId);
            });
          }
        } else {
          // Just trigger a rebuild to update the countdown
          if (mounted) {
            setState(() {});
          }
        }
      });
    } catch (e) {
      print('Error activating ticket: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to activate ticket: ${e.toString()}",
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red.shade800,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper method to format remaining time
  String formatRemainingTime(DateTime expiryTime) {
    final now = DateTime.now();
    final difference = expiryTime.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Check if a ticket is currently active (has an active timer)
  bool isTicketActive(String ticketId) {
    return _expiryTimes.containsKey(ticketId) && 
           DateTime.now().isBefore(_expiryTimes[ticketId]!);
  }

  void showActivationPopup(BuildContext context, String ticketName, String ticket_id, String ticket_description, String status) {
    // Return early if ticket is not active
    if (status.toLowerCase() != 'active') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.toLowerCase() == 'upcoming' 
                ? "This ticket is not yet available for activation." 
                : "This ticket has expired and cannot be activated.",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red.shade800,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // If ticket is already active, show a message and don't allow reactivation
    if (isTicketActive(ticket_id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "This ticket is already active",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.blue.shade800,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with colored background
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade800,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Activate Ticket", 
                            style: TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            ticketName,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Ticket details
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Parse description into sections for better display
                          ...ticket_description.split('\n').map((line) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                line,
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            )
                          ).toList(),
                          
                          SizedBox(height: 16),
                          
                          // Status indicator
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: status.toLowerCase() == 'active' 
                                ? Colors.green.shade100 
                                : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: status.toLowerCase() == 'active' 
                                  ? Colors.green
                                  : Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              "Status: $status",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: status.toLowerCase() == 'active' 
                                  ? Colors.green.shade800
                                  : Colors.grey.shade800,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          Text(
                            "Hold the button below to activate this ticket for entry",
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 20),
                          
                          isLoading
                            ? Column(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "Activating ticket...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                ],
                              )
                            : HoldToConfirmButton(
                                holdDuration: Duration(seconds: 2),
                                onConfirmed: () async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  HapticFeedback.mediumImpact();
                                  try {
                                    await activateTicket(ticket_id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Ticket Activated! Please proceed to the checkpoint.",
                                          textAlign: TextAlign.center,
                                        ),
                                        backgroundColor: Colors.green.shade800,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  } catch (e) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                },
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 252, 251, 251),
        body: 
        Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData){
                  return Center(child: CircularProgressIndicator());
                }
                final userData = snapshot.data!;
return Column(
  children: [
    SizedBox(height: 0.175 * MediaQuery.of(context).devicePixelRatio * 160),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
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
              child: Opacity(
                opacity: 0.85,
                child: SvgPicture.asset(
                  'assets/icons/user_avatar.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Welcome, ${userData['first_name']}',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          blinkeyPopUp(context),
        ],
      ),
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
                    stream: FirebaseFirestore.instance.collection('tickets').where("user_id", isEqualTo: widget.uid).snapshots(),
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
                            case 'active':
                              return 0;
                            case 'upcoming':
                              return 1;
                            case 'expired':
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
                            
                            // Use the document ID as the ticket ID if 'ticket_id' field is not present
                            final ticket_id = data['ticket_id'] ?? ticket.id;
                            
                            final description = data['description'] ?? 'No description available'; 
                            final status = data['status'] ?? 'Unknown Status';
                            
                            // Extract additional information
                            final validFrom = data['valid_from'] ?? '';
                            final validUntil = data['valid_until'] ?? '';
                            final institutionName = data['institution_name'] ?? '';
                            final accessedCount = data['accessed_count']?.toString() ?? '0';
                            
                            // Format date information if available
                            String dateInfo = '';
                            if (validFrom.isNotEmpty && validUntil.isNotEmpty) {
                              if (validFrom == validUntil) {
                                dateInfo = 'Valid on: $validFrom';
                              } else {
                                dateInfo = 'Valid: $validFrom to $validUntil';
                              }
                            }
                            
                            // Include institution name and date info in description if available
                            String enhancedDescription = description;
                            if (institutionName.isNotEmpty) {
                              enhancedDescription = '$institutionName\n$enhancedDescription';
                            }
                            if (dateInfo.isNotEmpty) {
                              enhancedDescription = '$enhancedDescription\n$dateInfo';
                            }
                            
                            // Add debug print for ticket ID
                            print("Rendering ticket: $ticket_name with ID: $ticket_id");
                            
                            return ticketObject(ticket_name, context, ticket_id, enhancedDescription, status);
                          } catch (e) {
                            print("Error rendering ticket: $e");
                            return Center(child: Text('Error loading ticket'));
                          }
                        }
                      );
                    }
                  )
                ),
              )
          ],
        ),
    );
  }

Widget ticketObject(String title, BuildContext context, String ticket_id, String description, String status) {
  bool isDisabled = (status.toLowerCase() == 'expired' || status.toLowerCase() == 'upcoming');
  bool isTicketCurrentlyActive = isTicketActive(ticket_id);
  
  // Get the appropriate status color
  Color getStatusColor() {
    if (isTicketCurrentlyActive) {
      return Colors.blue.shade700; // Special color for actively running timer
    }
    
    switch(status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'upcoming':
        return Colors.amber;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isDisabled ? null : () {
          showActivationPopup(context, title, ticket_id, description, status);
        },
        child: Column(
          children: [
            // Top section with institution color and name
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: getStatusColor().withOpacity(0.15),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Institution logo/icon placeholder
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTicketCurrentlyActive ? Icons.timer : Icons.confirmation_number_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  // Ticket name
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.grey.shade600 : Colors.black,
                      ),
                    ),
                  ),
                  // Status chip or active timer
                  isTicketCurrentlyActive
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                formatRemainingTime(_expiryTimes[ticket_id]!),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: getStatusColor(),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ],
              ),
            ),
            
            // Middle divider with ticket perforation
            Container(
              height: 2,
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  30,
                  (index) => Expanded(
                    child: Container(
                      height: 2,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      color: index % 2 == 0 ? Colors.grey.shade300 : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom section with ticket details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDisabled ? Colors.grey : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Action button or active timer status
                  if (isTicketCurrentlyActive)
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Active - Expires in ${formatRemainingTime(_expiryTimes[ticket_id]!)}",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Action button for active tickets - only shown for active tickets that are not currently activated
                  else if (status.toLowerCase() == 'active')
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          showActivationPopup(context, title, ticket_id, description, status);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getStatusColor(),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text("Activate Ticket"),
                      ),
                    ),
                  
                  // Display different text for upcoming/expired tickets
                  if (status.toLowerCase() == 'upcoming')
                    Center(
                      child: Text(
                        "Available Soon",
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (status.toLowerCase() == 'expired')
                    Center(
                      child: Text(
                        "Ticket Expired",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

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
              Navigator.of(dialogContext).pop(); // Close dialog
            },
          ),
          TextButton(
            child: Text("Log Out", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LogIn()),
                (route) => false,
              );
            },
          ),
        ],
      );
    },
  );
}

  Padding blinkeyPopUp(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
          icon: SvgPicture.asset('assets/icons/hamburger_menu.svg', height: 25, width: 25),
          onSelected:(value){
            if (value == 1){
              Navigator.of(context).push(
                MaterialPageRoute(
                builder: (context) => FaceSetup(uid: widget.uid, home_camera: 'camera')));
            }
            if (value == 2){
              Navigator.of(context).push(
                MaterialPageRoute(
                builder: (context) => SettingsPage(uid: widget.uid)));
            }
            if (value == 3){
              Navigator.of(context).push(
                MaterialPageRoute(
                builder: (context) => InstitutionPage()));
            }
            if (value == 4){
              _showLogoutDialog(context);
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
                leading: SvgPicture.asset('assets/icons/connect.svg', height: 24, width: 24),
                title: Text('Connect Institution'),
              ),
            ),
            PopupMenuItem(
              value: 4,
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
}
