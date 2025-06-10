import 'package:flutter/material.dart';
import 'package:qwickyprofessional/widgets/colors.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, -2), // Shadow above for elevation
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.borderColor,
          backgroundColor: Colors.white,
          elevation: 12,
          items: [
            _buildNavItem(
              iconPath: 'assets/Home.png',
              fallbackIcon: Icons.home,
              label: 'Home',
              isSelected: selectedIndex == 0,
            ),
            _buildNavItem(
              iconPath: 'assets/History.png',
              fallbackIcon: Icons.history,
              label: 'History',
              isSelected: selectedIndex == 1,
            ),
            _buildNavItem(
              iconPath: 'assets/Profile.png',
              fallbackIcon: Icons.person,
              label: 'Profile',
              isSelected: selectedIndex == 2,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required String iconPath,
    required IconData fallbackIcon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: Transform.translate(
        offset: Offset(0, isSelected ? -2 : 0), // Elevate selected item upward
        child: Transform.scale(
          scale: isSelected ? 1.1 : 1.0,
          child: Builder(
            builder: (context) {
              try {
                return Image.asset(
                  iconPath,
                  width: 26,
                  height: 26,
                  color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
                );
              } catch (e) {
                print('Error loading SVG $iconPath: $e');
                return Icon(
                  fallbackIcon,
                  size: 28,
                  color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
                );
              }
            },
          ),
        ),
      ),
      label: label,
    );
  }
}