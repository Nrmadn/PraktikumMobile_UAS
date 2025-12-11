import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ⬅️ TAMBAHKAN
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/target_ibadah_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/target_service.dart';
import '../providers/theme_provider.dart'; // ⬅️ TAMBAHKAN
import 'package:targetibadah_gamifikasi/services/firebase/firebase_target_service.dart';

class EditTargetScreen extends StatefulWidget {
  const EditTargetScreen({Key? key}) : super(key: key);

  @override
  State<EditTargetScreen> createState() => _EditTargetScreenState();
}

class _EditTargetScreenState extends State<EditTargetScreen> {
  late TextEditingController nameController;
  late TextEditingController noteController;
  late TargetIbadah targetData;
  String selectedCategory = categoryPrayer;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool dataLoaded = false;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is TargetIbadah) {
        setState(() {
          targetData = args;
          nameController.text = targetData.name;
          noteController.text = targetData.note;
          selectedCategory = targetData.category;
          selectedDate = targetData.targetDate;
          dataLoaded = true;
        });
      }
    });
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
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  void handleUpdateTarget() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // ✅ GUNAKAN FIREBASE UNTUK UPDATE
        final success = await FirebaseTargetService.updateTarget(
          targetId: targetData.id,
          name: nameController.text.trim(),
          category: selectedCategory,
          note: noteController.text.trim(),
          targetDate: selectedDate,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Target berhasil diupdate!'),
              backgroundColor: successColor,
            ),
          );
          Navigator.pop(context, true); // ✅ return true agar refresh
        } else {
          throw Exception('Failed to update target');
        }
      } catch (e) {
        print('❌ Error updating target: $e'); // ✅ tambahkan log
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: errorColor,
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
        title: const Text(editTargetTitle),
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
                    hint: 'Masukkan nama target',
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

                  // INFORMASI TARGET - SIMPLE VERSION
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
                          'Informasi Target:',
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: paddingSmall),
                        Wrap(
                          spacing: paddingSmall,
                          runSpacing: paddingSmall,
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
                                mainAxisSize: MainAxisSize.min,
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

                  // INFO DEMO MODE
                  Container(
                    padding: const EdgeInsets.all(paddingMedium),
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      border: Border.all(color: warningColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: warningColor,
                          size: iconSizeNormal,
                        ),
                        const SizedBox(width: paddingSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mode Demo',
                                style: TextStyle(
                                  fontSize: fontSizeNormal,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? darkTextColor : textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Data akan tersedia di versi lengkap',
                                style: TextStyle(
                                  fontSize: fontSizeSmall,
                                  color: isDark
                                      ? darkTextColorLight
                                      : textColorLight,
                                ),
                              ),
                            ],
                          ),
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
                          text: updateButton,
                          onPressed: handleUpdateTarget,
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
