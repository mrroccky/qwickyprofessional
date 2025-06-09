import 'package:flutter/material.dart';
import 'dart:async';

import 'package:qwickyprofessional/onboarding/phone_number_screen.dart';
import 'package:qwickyprofessional/widgets/colors.dart';
import 'package:qwickyprofessional/widgets/main_button.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Sample slide data (replace with your actual content)
  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/slider1.png',
      'title': 'Welcome to Qwicky Pro',
      'description': 'Join a trusted platform to offer your skills and earn on your schedule.',
    },
    {
      'image': 'assets/slider2.png',
      'title': 'Flexible Work Opportunities',
      'description': "Choose jobs that fit your availability and location. You're in control.",
    },
    {
      'image': 'assets/slider3.png',
      'title': 'Trusted & Secure Platform',
      'description': 'We ensure client verification and secure, timely payments for every job.',
    },
    {
      'image': 'assets/slider4.png',
      'title': 'Expand Your Client Base',
      'description': 'Promote your services and grow your reputation with reviews and ratings.',
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _slides.length - 1) {
      setState(() {
        _currentPage++;
      });
      //animation to move to the next page when button is clicked
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to the next screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PhoneNumberScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Slider
              SizedBox(
                height: screenHeight * 0.8,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image (40% of screen width/height)
                        Image.asset(
                          _slides[index]['image']!,
                          width: screenWidth * 0.55,
                          height: screenHeight * 0.55,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.image_not_supported,
                            size: 100,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Bold title
                        Text(
                          _slides[index]['title']!,
                          style:TextStyle(
                            fontSize: screenHeight * 0.033,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        // Regular description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _slides[index]['description']!,
                            style: TextStyle(
                              fontSize: screenHeight * 0.025,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Spacer(),
              // Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index ? AppColors.primaryColor : AppColors.borderColor,
                    ),
                  );
                }),
              ),
              SizedBox(height: screenHeight * 0.05),
              // Using your MainButton implementation with proper width
              MainButton(
                text: _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                onPressed: _onNextPressed,
              ),
              SizedBox(height: screenHeight * 0.04),
            ],
          ),
          // Skip button
          Positioned(
            top: screenHeight * 0.05,
            right: screenHeight * 0.03,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to HomeScreen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const PhoneNumberScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                 minimumSize: Size(0, 30),
              ),
              child:Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenHeight * 0.02,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}