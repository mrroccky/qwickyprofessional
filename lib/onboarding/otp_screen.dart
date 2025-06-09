import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:pinput/pinput.dart';
import 'package:qwickyprofessional/Main/location_permission_screen.dart';
import 'package:qwickyprofessional/widgets/colors.dart';
import 'package:qwickyprofessional/widgets/main_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String twilioAccountSid;
  final String twilioAuthToken;
  final String twilioServiceSid;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.twilioAccountSid,
    required this.twilioAuthToken,
    required this.twilioServiceSid,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _verificationError;
  bool _verificationSuccessful = false;

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _verificationError = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });

    try {
      // Encode credentials for Basic Auth
      final String basicAuth =
          'Basic ${base64Encode(utf8.encode('${widget.twilioAccountSid}:${widget.twilioAuthToken}'))}';

      // Create request to Twilio Verify API to check the OTP
      final response = await http.post(
        Uri.parse(
          'https://verify.twilio.com/v2/Services/${widget.twilioServiceSid}/VerificationCheck',
        ),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'To': widget.phoneNumber, 'Code': _otpController.text},
      );

      // Check response
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'approved') {
        // OTP verified successfully
        setState(() {
          _verificationSuccessful = true;
        });

        // Store isLoggedIn flag and phone number in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('phoneNumber', widget.phoneNumber);

        print('OTP verified for phone: ${widget.phoneNumber}');

        if (mounted && _verificationSuccessful) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number verified successfully!'),
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to LocationPermissionScreen
          await Future.delayed(const Duration(milliseconds: 300));
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LocationPermissionScreen()),
          );
        }
      } else {
        setState(() {
          _verificationError =
              responseData['message'] ?? 'Failed to verify OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _verificationError = 'An error occurred: $e';
      });
    } finally {
      if (mounted && !_verificationSuccessful) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });

    try {
      final String basicAuth =
          'Basic ${base64Encode(utf8.encode('${widget.twilioAccountSid}:${widget.twilioAuthToken}'))}';

      final response = await http.post(
        Uri.parse(
          'https://verify.twilio.com/v2/Services/${widget.twilioServiceSid}/Verifications',
        ),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': widget.phoneNumber,
          'Channel': 'sms',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP resent successfully!')),
          );
          _otpController.clear();
        }
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          _verificationError =
              responseData['message'] ?? 'Failed to resend OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _verificationError = 'An error occurred while resending OTP: $e';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).size.height * 0.03;
    final height = MediaQuery.of(context).size.height;

    final defaultPinTheme = PinTheme(
      width: height * 0.1,
      height: height * 0.08,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[100],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(height * 0.02),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topPadding),
              Center(
                child: Lottie.asset(
                  'assets/otp-img.json',
                  width: height * 0.4,
                  height: height * 0.4,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: height * 0.03),
              Text(
                'Please enter the verification code we just sent you',
                style: TextStyle(fontSize: height * 0.036, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: height * 0.04),
              Padding(
                padding: EdgeInsets.only(left: height * 0.04, right: height * 0.04),
                child: Pinput(
                  controller: _otpController,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor, width: 2),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[100],
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    setState(() {
                      _verificationError = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 5),
              if (_verificationError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _verificationError!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: height * 0.12),
              MainButton(
                text: _isVerifying ? '' : 'Verify',
                onPressed: _isVerifying ? null : _verifyOtp,
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : null,
              ),
              SizedBox(height: height * 0.01),
              TextButton(
                onPressed: _isVerifying ? null : _resendOtp,
                child: const Text('Didn\'t receive code? Resend'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}