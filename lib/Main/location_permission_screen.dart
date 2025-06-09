// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:qwickyprofessional/Main/home_screen.dart';
import 'package:qwickyprofessional/Main/profile_screen.dart';
import 'package:qwickyprofessional/Main/service_choose.dart';
import 'package:qwickyprofessional/models/service_model.dart';
import 'package:qwickyprofessional/provider/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> with SingleTickerProviderStateMixin {
  String _status = 'Fetching your location.';
  String? _address;
  late AnimationController _dotsController;
  final String? _locationIqApiKey = dotenv.env['GMAP_LOCATION_API_KEY'];

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
      _requestLocationPermission();
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');
      print('Retrieved phone number from SharedPreferences: $phoneNumber');

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final formattedPhone = phoneNumber.trim().replaceAll(RegExp(r'\s+'), '');
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        print('Fetching user data for phone: $formattedPhone');
        await userProvider.checkUserByPhone(formattedPhone);
        print('User data after fetch: ${userProvider.userData}');

        // Verify userId in SharedPreferences
        final userId = prefs.getString('userId');
        if (userId != null) {
          print('Confirmed userId in SharedPreferences: $userId');
        } else {
          print('Error: userId not found in SharedPreferences after checkUserByPhone');
          return;
        }

        // Load cart items from service_items_id
        final userData = userProvider.userData;
        if (userData != null && userData['service_items_id'] != null) {
          final List<dynamic> serviceItemsId = jsonDecode(userData['service_items_id']);
          final List<ServiceModel> services = [];
          for (var serviceId in serviceItemsId) {
            final service = await _fetchServiceById(serviceId);
            if (service != null) {
              services.add(service);
            }
          }
        } else {
          print('No service_items_id found in userData: $userData');
        }
      } else {
        print('Error: No phone number found in SharedPreferences');
      }
    } catch (e, stackTrace) {
      print('Error fetching user data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<ServiceModel?> _fetchServiceById(int serviceId) async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/services/$serviceId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Fetched service data: $jsonData');

        // Handle description field: check if it's a string or list
        String description;
        if (jsonData['description'] is String) {
          final List<dynamic> descriptionList = jsonDecode(jsonData['description']);
          description = descriptionList.join('\n');
        } else if (jsonData['description'] is List<dynamic>) {
          description = (jsonData['description'] as List<dynamic>).join('\n');
        } else {
          description = jsonData['description']?.toString() ?? '';
        }

        // Handle main_description field: check if it's a string or list
        String mainDescription;
        if (jsonData['main_description'] is String) {
          final List<dynamic> mainDescriptionList = jsonDecode(jsonData['main_description']);
          mainDescription = mainDescriptionList.join('\n');
        } else if (jsonData['main_description'] is List<dynamic>) {
          mainDescription = (jsonData['main_description'] as List<dynamic>).join('\n');
        } else {
          mainDescription = jsonData['main_description']?.toString() ?? '';
        }

        return ServiceModel(
          serviceId: jsonData['service_id'] as int,
          title: jsonData['service_title'],
          description: description,
          mainDescription: mainDescription,
          image: jsonData['service_image'],
          serviceType: jsonData['service_type'],
          serviceDuration: jsonData['service_duration'],
          price: double.parse(jsonData['service_price'].toString()),
          isActive: (jsonData['is_active'] as int) == 1,
          createdAt: DateTime.parse(jsonData['created_at']),
          categoryId: jsonData['category_id'],
          location: jsonData['location'] as String?,
        );
      }
      print('Failed to fetch service $serviceId: ${response.statusCode}');
      return null;
    } catch (e, stackTrace) {
      print('Error fetching service $serviceId: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print("Location service enabled: $serviceEnabled");

    if (!serviceEnabled) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Enable Location Services'),
          content: const Text('Location services are disabled. Please enable them to continue.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();

                // Wait for a short duration before checking again
                await Future.delayed(const Duration(seconds: 2));
                bool serviceEnabledAfter = await Geolocator.isLocationServiceEnabled();
                print("Service enabled after returning from settings: $serviceEnabledAfter");

                _requestLocationPermission();
              },
              child: const Text('Enable'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print("Requested permission status: $permission");
      if (permission == LocationPermission.denied) {
        _showPermissionDialog('Location permission is required to proceed.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Permission permanently denied");
      _showPermissionDialog(
        'Location permissions are permanently denied. Please enable them in settings.',
        openSettings: true,
      );
      return;
    }

    print("Permission granted. Fetching location...");
    _fetchLocation();
  }

  Future<bool> _checkProfessionalStatus() async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userData?['user_id']?.toString();

      if (userId == null) {
        print('Error: user_id not found in userData');
        return false;
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
          // Check if uploaded_file is not null
          return userProfessional['uploaded_file'] != null;
        }
        print('No professional record found for user_id: $userId');
        return false;
      } else {
        print('Failed to fetch professionals: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error checking professional status: $e');
      return false;
    }
  }

  Future<void> _fetchLocation() async {
    try {
      print("Calling Geolocator.getCurrentPosition...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("Position received: ${position.latitude}, ${position.longitude}");

      double lat = position.latitude;
      double lon = position.longitude;

      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lon&key=$_locationIqApiKey';

      final response = await http.get(Uri.parse(url));
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          String address = data['results'][0]['formatted_address'] ?? 'Unknown address';
          print("Fetched address: $address");

          // Extract city name from address_components
          String? cityName;
          final addressComponents = data['results'][0]['address_components'] as List<dynamic>;
          for (var component in addressComponents) {
            final types = component['types'] as List<dynamic>;
            if (types.contains('locality')) {
              cityName = component['long_name'] as String;
              break;
            } else if (types.contains('administrative_area_level_2') && cityName == null) {
              cityName = component['long_name'] as String;
            } else if (types.contains('administrative_area_level_1') && cityName == null) {
              cityName = component['long_name'] as String;
            }
          }
          cityName ??= 'Unknown';
          print("Extracted city name: $cityName");

          setState(() {
            _address = address;
            _status = address;
          });

          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final userData = userProvider.userData;

            // Check professional status (service selected and file uploaded)
            bool isProfessionalComplete = await _checkProfessionalStatus();

            if (userData != null && userData.isNotEmpty && isProfessionalComplete) {
              // All conditions met: user data exists, service selected, file uploaded
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            } else if (userData != null && userData.isNotEmpty) {
              // User data exists, but service or verification incomplete
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => ServiceChoose(
                    address: address,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            } else {
              // User data does not exist
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => ProfileScreen(
                    address: address,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }
          }
        } else {
          print("Failed to fetch address from API: ${data['status']}");
          setState(() {
            _status = 'Failed to fetch address';
          });
        }
      } else {
        print("Failed to fetch address from API: ${response.statusCode}");
        setState(() {
          _status = 'Failed to fetch address';
        });
      }
    } catch (e, stackTrace) {
      print("Error fetching location: $e");
      print("Stack trace: $stackTrace");
      setState(() {
        _status = 'Error: $e';
      });
      _showPermissionDialog('Failed to fetch location. Please try again.');
    }
  }

  void _showPermissionDialog(String message, {bool openSettings = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (openSettings) {
                Geolocator.openAppSettings();
              } else {
                _requestLocationPermission();
              }
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/locationpin.json',
              width: height * 0.4,
              height: height * 0.4,
              fit: BoxFit.contain,
            ),
            SizedBox(height: height * 0.03),
            AnimatedBuilder(
              animation: _dotsController,
              builder: (context, child) {
                int dots = (_dotsController.value * 4).floor() % 4;
                return Text(
                  _address == null ? '$_status${'.' * dots}' : _status,
                  style: TextStyle(
                    fontSize: height * 0.025,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}