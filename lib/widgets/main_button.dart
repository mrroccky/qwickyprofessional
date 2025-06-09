import 'package:flutter/material.dart';
import 'package:qwickyprofessional/widgets/colors.dart';

class MainButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? child;
  const MainButton({super.key, required this.text, required this.onPressed,this.child,});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal:  MediaQuery.of(context).size.height * 0.02), 
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.08,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
          ),
          child:child?? Text(
            text,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.height * 0.03,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      )
    );
  }
}
