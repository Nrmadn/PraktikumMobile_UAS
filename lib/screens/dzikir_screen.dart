import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ⬅️ TAMBAHKAN
import '../constants.dart';
import '../services/json_service.dart';
import '../widgets/bottom_navigation.dart';
import '../providers/theme_provider.dart'; // ⬅️ TAMBAHKAN

class DzikirScreen extends StatefulWidget {
  const DzikirScreen({Key? key}) : super(key: key);

  @override
  State<DzikirScreen> createState() => _DzikirScreenState();
}

class _DzikirScreenState extends State<DzikirScreen> {
  int selectedNavIndex = 0;
  int counter = 0;
  String selectedDzikir = 'Subhanallah';
  bool isLoading = true;

  List<Map<String, dynamic>> dzikirList = [];
  Map<String, String> benefits = {};

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  // LOAD DATA dari JSON
  Future<void> _loadJsonData() async {
    try {
      final results = await Future.wait([
        JsonService.getDzikirList(),
        JsonService.getDzikirBenefits(),
      ]);

      setState(() {
        dzikirList = results[0] as List<Map<String, dynamic>>;
        benefits = results[1] as Map<String, String>;
        isLoading = false;
        
        // Set selected dzikir pertama jika ada data
        if (dzikirList.isNotEmpty) {
          selectedDzikir = dzikirList[0]['name'].toString();
        }
      });
    } catch (e) {
      print('Error loading JSON data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleNavigation(int index) {
    setState(() {
      selectedNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/progress');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/progress_home');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/setting');
        break;
    }
  }

  void incrementCounter() {
    setState(() {
      counter++;
    });
  }

  void decrementCounter() {
    if (counter > 0) {
      setState(() {
        counter--;
      });
    }
  }

  void resetCounter() {
    setState(() {
      counter = 0;
    });
  }

  // Get selected dzikir details
  Map<String, dynamic>? getSelectedDzikirDetails() {
    try {
      return dzikirList.firstWhere(
        (dzikir) => dzikir['name'].toString() == selectedDzikir,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⬅️ GET THEME STATE
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
        appBar: AppBar(
          title: const Text('Tasbih'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final selectedDzikirDetails = getSelectedDzikirDetails();

    return Scaffold(
      backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
      appBar: AppBar(
        title: const Text('Tasbih'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // HEADER
                      Text(
                        'Tasbih Counter',
                        style: TextStyle(
                          fontSize: fontSizeXLarge,
                          fontWeight: FontWeight.bold,
                          color: isDark ? darkTextColor : textColor,
                        ),
                      ),
                      const SizedBox(height: paddingSmall),
                      Text(
                        'Hitung dzikir Anda',
                        style: TextStyle(
                          fontSize: fontSizeNormal,
                          color: isDark ? darkTextColorLight : textColorLight,
                        ),
                      ),

                      const SizedBox(height: paddingLarge),

                      // DZIKIR SELECTOR
                      dzikirList.isEmpty
                          ? Text(
                              'Tidak ada data dzikir',
                              style: TextStyle(
                                color: isDark ? darkTextColorLight : textColorLight,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: paddingMedium,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? darkCardBackgroundColor : cardBackgroundColor,
                                border: Border.all(
                                  color: isDark ? darkBorderColor : borderColor,
                                ),
                                borderRadius: BorderRadius.circular(borderRadiusNormal),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedDzikir,
                                underline: const SizedBox(),
                                dropdownColor: isDark ? darkCardBackgroundColor : cardBackgroundColor,
                                style: TextStyle(
                                  color: isDark ? darkTextColor : textColor,
                                ),
                                items: dzikirList.map((dzikir) {
                                  return DropdownMenuItem<String>(
                                    value: dzikir['name'].toString(),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                dzikir['name'].toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? darkTextColor : textColor,
                                                ),
                                              ),
                                              if (dzikir['arabicText'] != null)
                                                Text(
                                                  dzikir['arabicText'].toString(),
                                                  style: TextStyle(
                                                    fontSize: fontSizeSmall,
                                                    color: isDark ? darkTextColorLight : textColorLight,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedDzikir = newValue ?? 'Subhanallah';
                                    counter = 0;
                                  });
                                },
                              ),
                            ),

                      const SizedBox(height: paddingLarge),

                      // DZIKIR ARABIC TEXT & MEANING
                      if (selectedDzikirDetails != null) ...[
                        Container(
                          padding: const EdgeInsets.all(paddingMedium),
                          decoration: BoxDecoration(
                            color: (isDark ? primaryColorLight : primaryColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(borderRadiusNormal),
                            border: Border.all(
                              color: isDark ? primaryColorLight : primaryColor,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (selectedDzikirDetails['arabicText'] != null)
                                Text(
                                  selectedDzikirDetails['arabicText'].toString(),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? primaryColorLight : primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: paddingSmall),
                              if (selectedDzikirDetails['meaning'] != null)
                                Text(
                                  selectedDzikirDetails['meaning'].toString(),
                                  style: TextStyle(
                                    fontSize: fontSizeNormal,
                                    color: isDark ? darkTextColor : textColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              if (selectedDzikirDetails['description'] != null) ...[
                                const SizedBox(height: paddingSmall),
                                Text(
                                  selectedDzikirDetails['description'].toString(),
                                  style: TextStyle(
                                    fontSize: fontSizeSmall,
                                    color: isDark ? darkTextColorLight : textColorLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: paddingLarge),
                      ],

                      // COUNTER DISPLAY
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark 
                              ? [primaryColorLight, primaryColorDark]
                              : [primaryColor, primaryColorDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? primaryColorLight : primaryColor).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                counter.toString(),
                                style: const TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.bold,
                                  color: textColorWhite,
                                ),
                              ),
                              const SizedBox(height: paddingSmall),
                              Text(
                                selectedDzikir,
                                style: const TextStyle(
                                  fontSize: fontSizeMedium,
                                  color: textColorWhite,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              // Recommended count
                              if (selectedDzikirDetails != null &&
                                  selectedDzikirDetails['recommendedCount'] != null) ...[
                                const SizedBox(height: paddingSmall),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: paddingSmall,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(borderRadiusSmall),
                                  ),
                                  child: Text(
                                    'Target: ${selectedDzikirDetails['recommendedCount']}x',
                                    style: const TextStyle(
                                      fontSize: fontSizeSmall,
                                      color: textColorWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: paddingLarge),

                      // COUNTER BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: decrementCounter,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: errorColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: errorColor.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.remove,
                                color: textColorWhite,
                                size: 40,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: incrementCounter,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: successColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: successColor.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: textColorWhite,
                                size: 50,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: resetCounter,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: warningColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: warningColor.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.refresh,
                                color: textColorWhite,
                                size: 40,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: paddingLarge),

                      // INFO BOX - Benefits
                      if (benefits.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(paddingMedium),
                          decoration: BoxDecoration(
                            color: infoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(borderRadiusNormal),
                            border: Border.all(color: infoColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                benefits['title'] ?? '🔿 Manfaat Dzikir',
                                style: TextStyle(
                                  fontSize: fontSizeNormal,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? darkTextColor : textColor,
                                ),
                              ),
                              const SizedBox(height: paddingSmall),
                              Text(
                                benefits['description'] ??
                                    'Dzikir adalah mengingat Allah dengan hati, lidah, dan perbuatan.',
                                style: TextStyle(
                                  fontSize: fontSizeSmall,
                                  color: isDark ? darkTextColorLight : textColorLight,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: selectedNavIndex,
        onTap: handleNavigation,
      ),
    );
  }
}