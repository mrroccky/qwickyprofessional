import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qwickyprofessional/widgets/main_button.dart';
import 'package:qwickyprofessional/Main/home_screen.dart';
import 'package:qwickyprofessional/widgets/field_boxes.dart';

class VerificationScreen extends StatefulWidget {
  final int professionalId;
  final String address;

  const VerificationScreen({
    super.key,
    required this.professionalId,
    required this.address,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String? _uploadedFileBase64;
  String? _selectedDocumentType;
  Uint8List? _imageBytes;
  final _bioController = TextEditingController();
  final _experienceYearsController = TextEditingController();

  @override
  void dispose() {
    _bioController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final ext = file.path.toLowerCase();
        if (!ext.endsWith('.jpg') && !ext.endsWith('.jpeg') && !ext.endsWith('.png')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only JPG, JPEG, or PNG images are allowed')),
          );
          return;
        }

        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        final base64Data = 'data:$mimeType;base64,$base64String';

        print('Selected file: ${file.path}, size: ${bytes.length} bytes, Base64 length: ${base64Data.length}');

        setState(() {
          _uploadedFileBase64 = base64Data;
          _selectedDocumentType = documentType;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print('Error picking document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking document: $e')),
      );
    }
  }

  Future<void> _updateProfessional() async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      if (_uploadedFileBase64 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
        return;
      }

      final requestBody = {
        'status': 'pending',
        'document_type': _selectedDocumentType ?? 'document',
        'uploaded_file': _uploadedFileBase64,
        'bio': _bioController.text.isNotEmpty ? _bioController.text : null,
        'experience_years': _experienceYearsController.text.isNotEmpty ? _experienceYearsController.text : null,
      };

      print('Sending request to $apiUrl/professionals/${widget.professionalId} with body: $requestBody');

      final response = await http.put(
        Uri.parse('$apiUrl/professionals/${widget.professionalId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final responseBody = response.body;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification submitted successfully!')),
        );

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
      } else {
        print('Failed to update professional: ${response.statusCode}');
        print('Response body: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit verification: ${response.statusCode} - $responseBody')),
        );
      }
    } catch (e) {
      print('Error updating professional: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: height * 0.02),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: height * 0.02),
              const Text(
                'Verification',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: height * 0.01),
              const Text(
                'Please provide your details and upload an image (JPG, JPEG, PNG)',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: height * 0.04),
              FieldBoxes(
                controller1: _bioController,
                label1: 'Bio',
                icon1: Icons.description,
                maxLines1: 3,
                validator1: (value) => null, // Optional field
              ),
              SizedBox(height: height * 0.02),
              FieldBoxes(
                controller1: _experienceYearsController,
                label1: 'Experience Years',
                icon1: Icons.work_history,
                keyboardType1: TextInputType.text,
                validator1: (value) => null, // Optional field
              ),
              SizedBox(height: height * 0.02),
              _buildDocumentCard('PAN Card', height, width),
              SizedBox(height: height * 0.02),
              _buildDocumentCard('Aadhaar', height, width),
              SizedBox(height: height * 0.02),
              _buildDocumentCard('Driving License', height, width),
              if (_uploadedFileBase64 != null && _imageBytes != null) ...[
                SizedBox(height: height * 0.03),
                Text(
                  'Uploaded: ${_selectedDocumentType ?? ''} (Status: Pending)',
                  style: TextStyle(
                    fontSize: height * 0.02,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: height * 0.02),
                Image.memory(
                  _imageBytes!,
                  height: height * 0.2,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: height * 0.02),
                MainButton(
                  text: 'Submit Verification',
                  onPressed: _updateProfessional,
                ),
              ],
              SizedBox(height: height * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(String title, double height, double width) {
    return GestureDetector(
      onTap: () => _pickDocument(title),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: Container(
          width: width * 0.9,
          padding: EdgeInsets.all(height * 0.03),
          child: Row(
            children: [
              Icon(
                Icons.image,
                size: height * 0.05,
                color: Colors.black,
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: height * 0.022,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    Text(
                      'Upload Image (JPG, JPEG, PNG)',
                      style: TextStyle(
                        fontSize: height * 0.016,
                        color: Colors.grey,
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
}
