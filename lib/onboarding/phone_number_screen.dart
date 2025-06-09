// ignore_for_file: unused_field, unnecessary_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qwickyprofessional/onboarding/otp_screen.dart';
import 'package:qwickyprofessional/widgets/colors.dart';
import 'package:qwickyprofessional/widgets/main_button.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _phoneNumber = '';
  String? _errorMessage;
  String _completePhoneNumber = '';
  bool _agreeToTerms = true;

  // Twilio credentials
  final String? _twilioAccountSid = dotenv.env['TWILIO_ACCOUNT_SID'];
  final String? _twilioAuthToken = dotenv.env['TWILIO_AUTH_TOKEN'];
  final String? _twilioServiceSid = dotenv.env['TWILIO_SERVICE_SID'];

  Future<void> _sendOtp() async {
    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'Please agree to the terms and conditions to continue';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validate form
      if (_formKey.currentState!.validate()) {
        // Encode credentials for Basic Auth
        final String basicAuth =
            'Basic ${base64Encode(utf8.encode('$_twilioAccountSid:$_twilioAuthToken'))}';

        // request to Twilio Verify API
        final response = await http.post(
          Uri.parse(
            'https://verify.twilio.com/v2/Services/$_twilioServiceSid/Verifications',
          ),
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {'To': _completePhoneNumber, 'Channel': 'sms'},
        );

        // Check response
        if (response.statusCode == 200 || response.statusCode == 201) {
          // OTP sent successfully, navigate to verification screen
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => OtpVerificationScreen(
                      phoneNumber: _completePhoneNumber,
                      twilioAccountSid: _twilioAccountSid!,
                      twilioAuthToken: _twilioAuthToken!,
                      twilioServiceSid: _twilioServiceSid!,
                    ),
              ),
            );
          }
        } else {
          // Handle error
          final Map<String, dynamic> responseData = json.decode(response.body);
          setState(() {
            _errorMessage =
                responseData['message'] ??
                'Failed to send OTP. Please try again.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).size.height * 0.03;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topPadding),
              Padding(
                padding: EdgeInsets.all(height * 0.03),
                child: Center(
                  child: Lottie.asset(
                    'assets/phonescreen.json',
                    width: height * 0.3,
                    height: height * 0.3,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: height * 0.03),
              Padding(
                padding: EdgeInsets.only(
                  left: height * 0.04,
                  right: height * 0.04,
                ),
                child:Text(
                  'Enter your mobile number to continue',
                  style: TextStyle(fontSize: height * 0.04, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: height * 0.04),
              Padding(
                padding: EdgeInsets.only(
                  left: height * 0.04,
                  right: height * 0.04,
                ),
                child: IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    counterText: '',
                  ),
                  initialCountryCode: 'IN',
                  onChanged: (phone) {
                    setState(() {
                      _phoneNumber = phone.number;
                      _completePhoneNumber = phone.completeNumber;
                    });
                  },
                  validator: (phone) {
                    if (phone == null || phone.number.isEmpty) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.only(
                  left: height * 0.04,
                  right: height * 0.04,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? true;
                        });
                      },
                      activeColor: AppColors.primaryColor,
                    ),
                    Flexible(
                      // Use Flexible instead of Expanded
                      fit: FlexFit.loose,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 12.0,
                        ), // Align text with checkbox
                        child: Text(
                          'By agreeing, you accept our Terms of Service and Privacy Policy',
                          style: TextStyle(
                            fontSize: height * 0.02,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: height * 0.08),
              MainButton(
                text: _isLoading ? '' : 'Send OTP',
                onPressed: _isLoading ? null : _sendOtp,
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
