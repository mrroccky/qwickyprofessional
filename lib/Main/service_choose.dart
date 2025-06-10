import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:qwickyprofessional/provider/user_provider.dart';
import 'package:qwickyprofessional/widgets/main_button.dart';
import 'package:qwickyprofessional/Main/verification_screen.dart';
import 'package:qwickyprofessional/Main/home_screen.dart';

class ServiceChoose extends StatefulWidget {
  final String address;
  const ServiceChoose({super.key, required this.address});

  @override
  State<ServiceChoose> createState() => _ServiceChooseState();
}

class _ServiceChooseState extends State<ServiceChoose> {
  List<dynamic> _services = [];
  int? _selectedServiceId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/services'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> allServices = jsonDecode(response.body);
        // Filter out services with category_id equal to 4
        setState(() {
          _services = allServices.where((service) => service['category_id'].toString() != '4').toList();
          _isLoading = false;
        });
      } else {
        print('Failed to fetch services: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load services')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectService(int serviceId, UserProvider userProvider) async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final userId = userProvider.userData?['user_id']?.toString();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Check if a professional record already exists for the user
      final checkResponse = await http.get(
        Uri.parse('$apiUrl/professionals'),
        headers: {'Content-Type': 'application/json'},
      );

      if (checkResponse.statusCode == 200) {
        final List<dynamic> professionals = jsonDecode(checkResponse.body);
        final existingProfessional = professionals.firstWhere(
          (professional) => professional['user_id'].toString() == userId,
          orElse: () => null,
        );

        if (existingProfessional != null) {
          final professionalId = existingProfessional['professional_id'];
          print('Existing professional found with ID: $professionalId');

          // If uploaded_file is not null, navigate to HomeScreen
          if (existingProfessional['uploaded_file'] != null) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(address: widget.address,),
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
            return;
          }

          // If uploaded_file is null, navigate to VerificationScreen
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => VerificationScreen(
                professionalId: professionalId,
                address: widget.address,
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
          return;
        }
      } else {
        print('Failed to check professionals: ${checkResponse.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check existing records: ${checkResponse.statusCode}')),
        );
        return;
      }

      // No existing professional record, create a new one
      final response = await http.post(
        Uri.parse('$apiUrl/professionals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'user_id': userId,
          'status': 'pending',
          'uploaded_file': null,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final professionalId = responseData['professional_id'];
        print('Professional created with ID: $professionalId');

        // Navigate to VerificationScreen with professionalId
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => VerificationScreen(
              professionalId: professionalId,
              address: widget.address,
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
        print('Failed to create professional: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select service: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error selecting service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Choose Your Service'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(height * 0.02),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      final isSelected = _selectedServiceId == service['service_id'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedServiceId = isSelected ? null : service['service_id'];
                          });
                        },
                        child: Card(
                          elevation: isSelected ? 8 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: isSelected ? Colors.green : Colors.black,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    service['service_image'] ?? '',
                                    height: height * 0.2,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                SizedBox(height: height * 0.01),
                                Center(
                                  child: Text(
                                    service['service_title'] ?? 'No Title',
                                    style: TextStyle(
                                      fontSize: height * 0.025,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedServiceId != null)
                  Padding(
                    padding: EdgeInsets.all(height * 0.02),
                    child: MainButton(
                      text: 'Continue',
                      onPressed: () => _selectService(
                        _selectedServiceId!,
                        Provider.of<UserProvider>(context, listen: false),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}