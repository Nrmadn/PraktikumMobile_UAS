import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ⬅️ TAMBAHKAN
import 'package:targetibadah_gamifikasi/services/firebase/firebase_target_service.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/target_service.dart';
import '../services/gamification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart'; // ⬅️ TAMBAHKAN

class AddTargetScreen extends StatefulWidget {
  const AddTargetScreen({Key? key}) : super(key: key);

  @override
  State<AddTargetScreen> createState() => _AddTargetScreenState();
}

class _AddTargetScreenState extends State<AddTargetScreen> {
  // 📋 VARIABLES
  late TextEditingController nameController;
  late TextEditingController noteController;
  String selectedCategory = categoryPrayer;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> categories = [
    categoryPrayer,
    categoryQuran,
    categoryCharity,
    categoryZikir,
    categoryOther,
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    noteController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  String? validateTargetName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama target tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Nama target minimal 3 karakter';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context, bool isDark) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDark ? primaryColorLight : primaryColor,
              onPrimary: textColorWhite,
              onSurface: isDark ? darkTextColor : textColor,
            ),
            dialogBackgroundColor:
                isDark ? darkCardBackgroundColor : cardBackgroundColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void handleSaveTarget() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId') ?? '';

        if (userId.isEmpty) {
          throw Exception('User not logged in');
        }

        // ✅ CREATE TARGET MENGGUNAKAN FIREBASE
        final success = await FirebaseTargetService.createTarget(
          userId: userId,
          name: nameController.text.trim(),
          category: selectedCategory,
          note: noteController.text.trim(),
          targetDate: selectedDate,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Target berhasil ditambahkan!'),
              backgroundColor: successColor,
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to save target');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⬅️ GET THEME STATE
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
      appBar: AppBar(
        title: const Text(addTargetTitle),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(paddingMedium),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAMA TARGET INPUT
                  CustomTextField(
                    label: targetName,
                    hint: 'Contoh: Sholat Subuh tepat waktu',
                    controller: nameController,
                    prefixIcon: Icons.task_alt,
                    validator: validateTargetName,
                  ),

                  const SizedBox(height: paddingMedium),

                  // KATEGORI DROPDOWN
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetCategory,
                        style: TextStyle(
                          fontSize: fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: isDark ? darkTextColor : textColor,
                        ),
                      ),
                      const SizedBox(height: paddingSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: paddingMedium,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? darkBorderColor : borderColor,
                          ),
                          borderRadius:
                              BorderRadius.circular(borderRadiusNormal),
                          color: isDark
                              ? darkCardBackgroundColor
                              : cardBackgroundColor,
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCategory,
                          underline: const SizedBox(),
                          dropdownColor: isDark
                              ? darkCardBackgroundColor
                              : cardBackgroundColor,
                          style: TextStyle(
                            color: isDark ? darkTextColor : textColor,
                          ),
                          items: categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCategory = newValue ?? categoryPrayer;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: paddingMedium),

                  // TANGGAL TARGET
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Target',
                        style: TextStyle(
                          fontSize: fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: isDark ? darkTextColor : textColor,
                        ),
                      ),
                      const SizedBox(height: paddingSmall),
                      GestureDetector(
                        onTap: () => _selectDate(context, isDark),
                        child: Container(
                          padding: const EdgeInsets.all(paddingMedium),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? darkBorderColor : borderColor,
                            ),
                            borderRadius:
                                BorderRadius.circular(borderRadiusNormal),
                            color: isDark
                                ? darkCardBackgroundColor
                                : cardBackgroundColor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: isDark
                                        ? primaryColorLight
                                        : primaryColor,
                                    size: iconSizeNormal,
                                  ),
                                  const SizedBox(width: paddingNormal),
                                  Text(
                                    _formatDate(selectedDate),
                                    style: TextStyle(
                                      fontSize: fontSizeNormal,
                                      color: isDark ? darkTextColor : textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: isDark
                                    ? darkTextColorLight
                                    : textColorLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: paddingMedium),

                  // CATATAN INPUT
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetNote,
                        style: TextStyle(
                          fontSize: fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: isDark ? darkTextColor : textColor,
                        ),
                      ),
                      const SizedBox(height: paddingSmall),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        minLines: 3,
                        style: TextStyle(
                          color: isDark ? darkTextColor : textColor,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark
                              ? darkCardBackgroundColor
                              : cardBackgroundColor,
                          hintText: 'Tambahkan catatan (opsional)',
                          hintStyle: TextStyle(
                            color:
                                isDark ? darkTextColorLight : textColorLighter,
                          ),
                          contentPadding: const EdgeInsets.all(paddingMedium),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(borderRadiusNormal),
                            borderSide: BorderSide(
                              color: isDark ? darkBorderColor : borderColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(borderRadiusNormal),
                            borderSide: BorderSide(
                              color: isDark ? darkBorderColor : borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(borderRadiusNormal),
                            borderSide: BorderSide(
                              color: isDark ? primaryColorLight : primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: paddingLarge),

                  // CATEGORY PREVIEW
                  Container(
                    padding: const EdgeInsets.all(paddingMedium),
                    decoration: BoxDecoration(
                      color: (isDark ? primaryColorLight : primaryColor)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      border: Border.all(
                        color: isDark ? primaryColorLight : primaryColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pratinjau Target:',
                          style: TextStyle(
                            fontSize: fontSizeNormal,
                            fontWeight: FontWeight.w600,
                            color: isDark ? darkTextColor : textColor,
                          ),
                        ),
                        const SizedBox(height: paddingSmall),
                        Text(
                          nameController.text.isEmpty
                              ? 'Nama target akan muncul di sini'
                              : nameController.text,
                          style: TextStyle(
                            fontSize: fontSizeMedium,
                            fontWeight: FontWeight.w600,
                            color: isDark ? darkTextColor : textColor,
                          ),
                        ),
                        const SizedBox(height: paddingSmall),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: paddingSmall,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark ? primaryColorLight : primaryColor,
                                borderRadius:
                                    BorderRadius.circular(borderRadiusSmall),
                              ),
                              child: Text(
                                selectedCategory,
                                style: const TextStyle(
                                  color: textColorWhite,
                                  fontSize: fontSizeSmall,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: paddingSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: paddingSmall,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(borderRadiusSmall),
                                border: Border.all(color: accentColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(selectedDate),
                                    style: TextStyle(
                                      color: isDark ? darkTextColor : textColor,
                                      fontSize: fontSizeSmall,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: paddingLarge),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedCustomButton(
                          text: cancelButton,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: paddingNormal),
                      Expanded(
                        child: CustomButton(
                          text: saveButton,
                          onPressed: handleSaveTarget,
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: paddingMedium),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
