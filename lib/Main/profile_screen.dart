import 'package:flutter/material.dart';
import 'package:qwickyprofessional/widgets/profile_form.dart';

class ProfileScreen extends StatelessWidget {
  final String address;
  const ProfileScreen({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ProfileFormWidget(address: address,isModal: false,),
    );
  }
}