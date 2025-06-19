import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:qwickyprofessional/widgets/colors.dart';
import 'package:qwickyprofessional/widgets/google_maps.dart';
import 'package:qwickyprofessional/widgets/main_button.dart';
import 'package:location/location.dart';

class BookingCard extends StatefulWidget {
  final dynamic booking;
  final int serviceId;
  final Map<String, dynamic> userData;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final Function(String, String) onPinSubmit;
  final VoidCallback onComplete;
  final TextEditingController pinController;
  final bool isPinVerified;

  const BookingCard({
    super.key,
    required this.booking,
    required this.serviceId,
    required this.userData,
    required this.onAccept,
    required this.onReject,
    required this.onPinSubmit,
    required this.onComplete,
    required this.pinController,
    required this.isPinVerified,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  String _serviceDuration = '';
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _fetchServiceDurationAndUser();
  }

  Future<void> _fetchServiceDurationAndUser() async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      
      // Fetch service details
      final serviceResponse = await http.get(
        Uri.parse('$apiUrl/services'),
        headers: {'Content-Type': 'application/json'},
      );

      if (serviceResponse.statusCode == 200) {
        final List<dynamic> services = jsonDecode(serviceResponse.body);
        final service = services.firstWhere(
          (service) => service['service_id'] == widget.serviceId,
          orElse: () => null,
        );

        if (service != null) {
          final minutes = int.parse(service['service_duration']);
          final hours = (minutes / 60).floor();
          final remainingMinutes = minutes % 60;
          setState(() {
            _serviceDuration = hours > 0
                ? '$hours hr${hours > 1 ? 's' : ''} ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}'
                : '$remainingMinutes min';
          });
        }
      } else {
        print('Failed to fetch services: ${serviceResponse.statusCode}');
      }

      // Fetch user details
      final userResponse = await http.get(
        Uri.parse('$apiUrl/users/${widget.booking['user_id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (userResponse.statusCode == 200) {
        final user = jsonDecode(userResponse.body);
        setState(() {
          _phoneNumber = user['phone_number'] ?? 'N/A';
        });
      } else {
        print('Failed to fetch user: ${userResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching service duration or user: $e');
    }
  }

  Future<void> _openMaps() async {
    // Check if location services are enabled
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are required to view the route')),
        );
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required to view the route')),
        );
        return;
      }
    }

    // Get user address from userData
    final userAddress =
        '${widget.userData['address_line'] ?? ''}, ${widget.userData['city'] ?? ''}, ${widget.userData['state'] ?? ''}, ${widget.userData['postal_code'] ?? ''}';
    if (userAddress.trim().isEmpty || userAddress == ', , , ') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User location not available')),
      );
      return;
    }

    // Show map dialog
    showDialog(
      context: context,
      builder: (context) => MapDialogWidget(
        userAddress: userAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final userName = widget.userData.isNotEmpty
        ? '${widget.userData['first_name'] ?? ''} ${widget.userData['last_name'] ?? ''}'.trim()
        : 'User ID: ${widget.booking['user_id']}';

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.symmetric(vertical: height * 0.01),
      child: Padding(
        padding: EdgeInsets.all(height * 0.015),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_pin, size: height * 0.03, color: AppColors.primaryColor),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Text(
                    '${widget.booking['address_line'] ?? 'N/A'}, ${widget.booking['city'] ?? 'N/A'}, ${widget.booking['state'] ?? 'N/A'}',
                    style: TextStyle(fontSize: height * 0.02),
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.01),
            Row(
              children: [
                Icon(Icons.access_time, size: height * 0.03, color: AppColors.primaryColor),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Text(
                    'Today at ${widget.booking['scheduled_time']}',
                    style: TextStyle(fontSize: height * 0.02),
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.01),
            Row(
              children: [
                Icon(Icons.phone, size: height * 0.03, color: AppColors.primaryColor),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Text(
                    'Phone Number: $_phoneNumber',
                    style: TextStyle(fontSize: height * 0.02),
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.01),
            Row(
              children: [
                Icon(Icons.person, size: height * 0.03, color: AppColors.primaryColor),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Text(
                    userName,
                    style: TextStyle(fontSize: height * 0.02),
                  ),
                ),
                Icon(Icons.currency_rupee, size: height * 0.023, color: AppColors.primaryColor),
                Text(
                  '${widget.booking['total_amount']}',
                  style: TextStyle(fontSize: height * 0.023),
                ),
              ],
            ),
            SizedBox(height: height * 0.01),
            Row(
              children: [
                Icon(Icons.timer, size: height * 0.03, color: AppColors.primaryColor),
                SizedBox(width: width * 0.02),
                Text(
                  'Duration: $_serviceDuration',
                  style: TextStyle(fontSize: height * 0.02),
                ),
              ],
            ),
            SizedBox(height: height * 0.015),
            if (widget.booking['status'] == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: SizedBox(
                      width: width * 0.6,
                      child: Transform.scale(
                        scale: 0.9,
                        child: MainButton(
                          text: 'Accept',
                          onPressed: widget.onAccept,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  Flexible(
                    child: SizedBox(
                      width: width * 0.6,
                      child: Transform.scale(
                        scale: 0.9,
                        child: MainButton(
                          text: 'Reject',
                          onPressed: widget.onReject,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (widget.booking['status'] == 'accepted') ...[
              SizedBox(
                width: double.infinity,
                child: MainButton(
                  text: 'View Location in Maps',
                  onPressed: _openMaps,
                  color: AppColors.primaryColor,
                ),
              ),
              if (!widget.isPinVerified) ...[
                SizedBox(height: height * 0.01),
                Container(
                  width: double.infinity, 
                  padding: EdgeInsets.all(width * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: widget.pinController,
                          decoration: InputDecoration(
                            labelText: 'PIN',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppColors.primaryColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: height * 0.02),
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      Flexible(
                        flex: 2,
                        child: SizedBox(
                          child: Transform.scale(
                            scale: 0.9,
                            child: MainButton(
                              text: 'Submit PIN',
                              onPressed: () => widget.onPinSubmit(widget.pinController.text, widget.booking['booking_pin']),
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.isPinVerified)
                Padding(
                  padding: EdgeInsets.only(top: height * 0.01),
                  child: SizedBox(
                    width: double.infinity,
                    child: MainButton(
                      text: 'Mark as Completed',
                      onPressed: widget.onComplete,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}