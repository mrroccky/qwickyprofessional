import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:qwickyprofessional/widgets/colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qwickyprofessional/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  int? _professionalId;
  int? _serviceId;
  Map<int, Map<String, dynamic>> _userData = {};
  Map<int, String> _serviceDurations = {};

  @override
  void initState() {
    super.initState();
    _fetchProfessionalData();
  }

  Future<void> _fetchProfessionalData() async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userData?['user_id']?.toString();

      if (userId == null) {
        print('Error: user_id not found in userData');
        setState(() => _isLoading = false);
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
          setState(() {
            _professionalId = userProfessional['professional_id'];
            _serviceId = userProfessional['service_id'];
            _isLoading = false;
          });
          print('Professional data fetched: professionalId=$_professionalId, serviceId=$_serviceId');
          _fetchHistoryBookings();
        } else {
          print('No professional record found for user_id: $userId');
          setState(() => _isLoading = false);
        }
      } else {
        print('Failed to fetch professionals: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching professional data: $e');
      setState(() => _isLoading = false);
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
        setState(() {
          _userData[userId] = user;
        });
      } else {
        print('Failed to fetch user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchServiceDuration(int serviceId) async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/services'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> services = jsonDecode(response.body);
        final service = services.firstWhere(
          (service) => service['service_id'] == serviceId,
          orElse: () => null,
        );

        if (service != null) {
          final minutes = int.parse(service['service_duration']);
          final hours = (minutes / 60).floor();
          final remainingMinutes = minutes % 60;
          final duration = hours > 0
              ? '$hours hr${hours > 1 ? 's' : ''} ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}'
              : '$remainingMinutes min';
          setState(() {
            _serviceDurations[serviceId] = duration;
          });
        }
      } else {
        print('Failed to fetch services: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching service duration: $e');
    }
  }

  Future<void> _fetchHistoryBookings() async {
    if (_professionalId == null) return;

    try {
      print('Fetching history with professionalId: $_professionalId');
      setState(() => _isLoading = true);
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/bookings?professionalId=$_professionalId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> bookings = jsonDecode(response.body);
        print('Raw bookings response: $bookings');
        for (var booking in bookings) {
          if (!_userData.containsKey(booking['user_id'])) {
            await _fetchUserData(booking['user_id']);
          }
          if (!_serviceDurations.containsKey(booking['service_id'])) {
            await _fetchServiceDuration(booking['service_id']);
          }
        }
        setState(() {
          _bookings = bookings
              .where((b) =>
                  b['professional_id'] == _professionalId &&
                  ['accepted', 'completed'].contains(b['status']))
              .toList();
          print('Filtered bookings: $_bookings');
          _isLoading = false;
        });
      } else {
        print('Failed to fetch history bookings: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching history bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking History',
                    style: TextStyle(
                      fontSize: height * 0.028,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, size: height * 0.035, color: AppColors.primaryColor,
                  ),
                  onPressed: _fetchHistoryBookings,)
                ],
              ),
              SizedBox(height: height * 0.02),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _bookings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset(
                                  'assets/no-history.json',
                                  width: height * 0.3,
                                  height: height * 0.3,
                                ),
                                SizedBox(height: height * 0.02),
                                Text(
                                  'No booking history available',
                                  style: TextStyle(
                                    fontSize: height * 0.022,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _bookings.length,
                            itemBuilder: (context, index) {
                              final booking = _bookings[index];
                              return HistoryCard(
                                booking: booking,
                                userData: _userData[booking['user_id']] ?? {},
                                serviceDuration: _serviceDurations[booking['service_id']] ?? 'N/A',
                              );
                            },
                          ),
              ),
            ],
      ),
      ),
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  final dynamic booking;
  final Map<String, dynamic> userData;
  final String serviceDuration;

  const HistoryCard({
    super.key,
    required this.booking,
    required this.userData,
    required this.serviceDuration,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final width = MediaQuery.sizeOf(context).width;
    final userName = userData.isNotEmpty
        ? '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim()
        : 'User ID: ${booking['user_id']}';
    final isAccepted = booking['status'] == 'accepted';
    final statusColor = isAccepted ? Colors.yellow[700] : Colors.green[700];

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(vertical: height * 0.01),
      child: Padding(
        padding: EdgeInsets.all(height * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    userName,
                    style: TextStyle(
                      fontSize: height * 0.022,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.005),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAccepted ? 'Accepted' : 'Completed',
                    style: TextStyle(
                      fontSize: height * 0.018,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.01),
            Row(
              children: [
                Icon(Icons.location_pin, size: height * 0.025, color: AppColors.primaryColor),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Text(
                    '${booking['address_line'] ?? 'N/A'}, ${booking['city'] ?? 'N/A'}, ${booking['state'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: height * 0.018,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.008),
            Row(
              children: [
                Icon(Icons.access_time, size: height * 0.025, color: AppColors.primaryColor),
                SizedBox(width: width * 0.02),
                Text(
                  'Today at ${booking['scheduled_time']}',
                  style: TextStyle(
                    fontSize: height * 0.018,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.008),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer, size: height * 0.025, color: AppColors.primaryColor),
                    SizedBox(width: width * 0.02),
                    Text(
                      'Duration: $serviceDuration',
                      style: TextStyle(
                        fontSize: height * 0.018,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.currency_rupee, size: height * 0.025, color: AppColors.primaryColor),
                    Text(
                      '${booking['total_amount']}',
                      style: TextStyle(
                        fontSize: height * 0.025,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}