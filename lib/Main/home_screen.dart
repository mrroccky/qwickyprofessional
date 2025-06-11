import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:qwickyprofessional/Main/history_screen.dart';
import 'package:qwickyprofessional/Main/profile_screen.dart';
import 'package:qwickyprofessional/provider/user_provider.dart';
import 'package:qwickyprofessional/widgets/app_bar.dart';
import 'package:qwickyprofessional/widgets/colors.dart';
import 'package:qwickyprofessional/widgets/job_requests_screen.dart';
import 'package:qwickyprofessional/widgets/nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:qwickyprofessional/widgets/rating_part.dart';

class HomeScreen extends StatefulWidget {
  final String? address;

  const HomeScreen({super.key, required this.address});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isOnline = false;
  bool _isPending = true;
  bool _isLoading = true;
  int? _professionalId;

  @override
  void initState() {
    super.initState();
    _checkProfessionalStatus();
  }

  Future<void> _checkProfessionalStatus() async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userData?['user_id']?.toString();

      if (userId == null) {
        print('Error: user_id not found in userData');
        setState(() {
          _isLoading = false;
          _isPending = false;
        });
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
          print('Professional found: $userProfessional');
          setState(() {
            _isPending = userProfessional['status'] == 'pending';
            _isOnline = userProfessional['availability'] == 'online';
            _professionalId = userProfessional['professional_id'];
            _isLoading = false;
          });
        } else {
          print('No professional record found for user_id: $userId');
          setState(() {
            _isPending = false;
            _isLoading = false;
          });
        }
      } else {
        print('Failed to fetch professionals: ${response.statusCode}');
        setState(() {
          _isPending = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking professional status: $e');
      setState(() {
        _isPending = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAvailability(bool isOnline) async {
    if (_professionalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Professional ID not found')),
      );
      return;
    }

    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final response = await http.put(
        Uri.parse('$apiUrl/professionals/$_professionalId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'availability': isOnline ? 'online' : 'offline'}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Availability updated to ${isOnline ? 'Online' : 'Offline'}')),
        );
        setState(() {
          _isOnline = isOnline;
        });
      } else {
        print('Failed to update availability: ${response.statusCode}');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update availability: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error updating availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isPending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Lottie.asset(
              'assets/pending.json',
              width: MediaQuery.of(context).size.height * 0.4,
              height: MediaQuery.of(context).size.height * 0.4,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Center(
              child: Text(
                "Your verification is in progress. Please give us some time to verify your details.",
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.height * 0.026,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: height * 0.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: EdgeInsets.all(height * 0.015),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: width * 0.5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "You're Currently: ${_isOnline ? 'Online' : 'Offline'}",
                            style: TextStyle(
                              fontSize: height * 0.023,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          Row(
                            children: [
                              Container(
                                width: height * 0.01,
                                height: height * 0.05,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isOnline ? Colors.green : Colors.red,
                                ),
                              ),
                              SizedBox(width: width * 0.02),
                              Flexible(
                                child: Text(
                                  _isOnline
                                      ? 'Clients can book you now'
                                      : 'Clients will not be able to book you now',
                                  style: TextStyle(
                                    fontSize: height * 0.02,
                                    color: _isOnline ? Colors.green : Colors.red,
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isOnline,
                      onChanged: (value) => _updateAvailability(value),
                      activeColor: AppColors.primaryColor,
                      inactiveTrackColor: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: height * 0.01),
            Card(
              elevation: 4,
              color: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: width * 0.9,
                padding: EdgeInsets.all(height * 0.03),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Earnings',
                          style: TextStyle(
                            fontSize: height * 0.021,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        Text(
                          '₹ 5,000',
                          style: TextStyle(
                            fontSize: height * 0.035,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Image.asset(
                      'assets/income.png',
                      width: height * 0.08,
                      height: height * 0.08,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: height * 0.01),
            if (_professionalId != null)
              RatingPart(professionalId: _professionalId!),
            SizedBox(height:height * 0.01),
            const JobRequestsScreen(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildBody(),
      const HistoryScreen(),
      ProfileScreen(address: widget.address!),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(address: widget.address!),
      body: screens[_selectedIndex],
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}