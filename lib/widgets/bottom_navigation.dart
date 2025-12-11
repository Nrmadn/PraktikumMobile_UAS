import 'package:flutter/material.dart';
import '../constants.dart';

// BOTTOM NAVIGATION WIDGET
// Widget navigation bar di bagian bawah layar
// Digunakan untuk navigate ke berbagai halaman

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: cardBackgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textColorLight,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: navHome,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule),
          label: navSchedule,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: navCalendar,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: navProfile,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: navSetting,
        ),
      ],
    );
  }
}

//  CUSTOM BOTTOM NAVIGATION VARIANT

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: paddingNormal,
            vertical: paddingSmall,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) => GestureDetector(
                onTap: () => onTap(index),
                child: _buildNavItem(
                  item: items[index],
                  isActive: currentIndex == index,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BottomNavItem item,
    required bool isActive,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: isActive ? paddingMedium : paddingSmall,
        vertical: paddingSmall,
      ),
      decoration: BoxDecoration(
        color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            color: isActive ? primaryColor : textColorLight,
            size: iconSizeNormal,
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: fontSizeSmall,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? primaryColor : textColorLight,
            ),
          ),
        ],
      ),
    );
  }
}

//  BOTTOM NAV ITEM MODEL

class BottomNavItem {
  final IconData icon;
  final String label;

  BottomNavItem({
    required this.icon,
    required this.label,
  });
}