import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qwickyprofessional/widgets/booking_card.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qwickyprofessional/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';

class JobRequestsScreen extends StatefulWidget {
  const JobRequestsScreen({super.key});

  @override
  State<JobRequestsScreen> createState() => _JobRequestsScreenState();
}

class _JobRequestsScreenState extends State<JobRequestsScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  int? _professionalId;
  int? _serviceId;
  Map<int, TextEditingController> _pinControllers = {};
  Map<int, bool> _pinVerified = {};
  Map<int, Map<String, dynamic>> _userData = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchProfessionalData();
    // Set up auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      print('Auto-refresh timer fired at ${DateTime.now()}');
      _fetchPendingBookings();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks
    print('Disposing JobRequestsScreen, canceling timer');
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchProfessionalData() async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userData?['user_id']?.toString();

      if (userId == null) {
        print('Error: user_id not found in userData');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('$apiUrl/professionals'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> professionals = jsonDecode(response.body);
        final userProfessional = professionals.firstWhere(
          (professional) => professional['user_id'].toString() == userId,
          orElse: () => null,
        );

        if (userProfessional != null) {
          if (mounted) {
            setState(() {
              _professionalId = userProfessional['professional_id'];
              _serviceId = userProfessional['service_id'];
              _isLoading = false;
            });
          }
          print('Professional data fetched: professionalId=$_professionalId, serviceId=$_serviceId');
          _fetchPendingBookings();
        } else {
          print('No professional record found for user_id: $userId');
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        print('Failed to fetch professionals: ${response.statusCode}');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching professional data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserData(int userId) async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _userData[userId] = user;
          });
        }
      } else {
        print('Failed to fetch user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchPendingBookings() async {
    if (_professionalId == null || _serviceId == null) return;

    try {
      print('Fetching bookings with professionalId: $_professionalId at ${DateTime.now()}');
      if (mounted) setState(() => _isLoading = true);
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/bookings/pending?professionalId=$_professionalId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> bookings = jsonDecode(response.body);
        // print('Fetched bookings: $bookings');
        for (var booking in bookings) {
          if (!_userData.containsKey(booking['user_id'])) {
            await _fetchUserData(booking['user_id']);
          }
          if (booking['status'] == 'pending') {
            _pinVerified.remove(booking['booking_id']);
            _pinControllers[booking['booking_id']]?.clear();
          }
        }
        if (mounted) {
          setState(() {
            _bookings = bookings.where((b) => b['service_id'] == _serviceId).toList();
            _isLoading = false;
          });
        }
      } else {
        print('Failed to fetch pending bookings: ${response.statusCode}');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching pending bookings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Job Requests',
                  style: TextStyle(
                    fontSize: height * 0.028,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: height * 0.035),
                  onPressed: _fetchPendingBookings,
                ),
              ],
            ),
            SizedBox(height: height * 0.02),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? Center(
                        child: Text(
                          'No pending job requests available',
                          style: TextStyle(fontSize: height * 0.022),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          _pinControllers[booking['booking_id']] ??= TextEditingController();
                          return BookingCard(
                            booking: booking,
                            serviceId: _serviceId!,
                            userData: _userData[booking['user_id']] ?? {},
                            onAccept: () => _handleAccept(booking['booking_id']),
                            onReject: () => _handleReject(booking['booking_id']),
                            onPinSubmit: (pin, bookingPin) => _handlePinSubmit(booking['booking_id'], pin, bookingPin),
                            onComplete: () => _handleComplete(booking['booking_id']),
                            pinController: _pinControllers[booking['booking_id']]!,
                            isPinVerified: _pinVerified[booking['booking_id']] ?? false,
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept(int bookingId) async {
    try {
      print('Accepting booking $bookingId with professionalId: $_professionalId');
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final response = await http.put(
        Uri.parse('$apiUrl/bookings/$bookingId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'accepted', 'professional_id': _professionalId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _bookings = _bookings
              .map((b) => b['booking_id'] == bookingId
                  ? {...b, 'status': 'accepted', 'professional_id': _professionalId}
                  : b)
              .toList();
          _pinVerified.remove(bookingId); // Reset PIN verification
          _pinControllers[bookingId]?.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking accepted successfully')),
        );
        // Show dialog after acceptance
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PIN Required'),
            content: const Text('Please enter the 4-digit PIN provided by the user when you arrive at their location.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to accept booking';
        print('Failed to accept booking: ${response.statusCode} - $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      print('Error accepting booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handleReject(int bookingId) async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final response = await http.delete(
        Uri.parse('$apiUrl/bookings/$bookingId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'professionalId': _professionalId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _bookings = _bookings.where((b) => b['booking_id'] != bookingId).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking rejected successfully')),
        );
      } else {
        print('Failed to reject booking: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject booking: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error rejecting booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handlePinSubmit(int bookingId, String enteredPin, String actualPin) async {
    if (enteredPin == actualPin) {
      setState(() {
        _pinVerified[bookingId] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN verified successfully')),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invalid PIN'),
          content: const Text('The entered PIN is incorrect. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleComplete(int bookingId) async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final response = await http.put(
        Uri.parse('$apiUrl/bookings/$bookingId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'completed'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _bookings = _bookings.where((b) => b['booking_id'] != bookingId).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service marked as completed')),
        );
      } else {
        print('Failed to complete booking: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete booking: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error completing booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}