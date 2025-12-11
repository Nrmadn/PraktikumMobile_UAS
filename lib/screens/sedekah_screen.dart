import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/json_service.dart';
import '../services/firebase/firebase_sedekah_service.dart'; // ✅ TAMBAH
import '../widgets/bottom_navigation.dart';
import '../providers/theme_provider.dart';

class SedekahScreen extends StatefulWidget {
  const SedekahScreen({Key? key}) : super(key: key);

  @override
  State<SedekahScreen> createState() => _SedekahScreenState();
}

class _SedekahScreenState extends State<SedekahScreen> {
  int selectedNavIndex = 0;
  late TextEditingController jumlahController;
  late TextEditingController keteranganController;
  bool isLoading = true;
  bool isSaving = false;

  List<Map<String, dynamic>> sedekahHistory = [];
  List<String> sedekahCategories = [];
  Map<String, dynamic> tips = {};
  int totalSedekah = 0;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    jumlahController = TextEditingController();
    keteranganController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    jumlahController.dispose();
    keteranganController.dispose();
    super.dispose();
  }

  // LOAD DATA
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      if (userId.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // ✅ Load dari Firebase + static data
      final results = await Future.wait([
        FirebaseSedekahService.getSedekahByUserId(userId), // ✅ FIREBASE
        JsonService.getSedekahCategories(),
        JsonService.getSedekahTips(),
        FirebaseSedekahService.getTotalSedekahThisMonth(userId), // ✅ FIREBASE
      ]);

      final history = results[0] as List<Map<String, dynamic>>;

      // Format tanggal
      final formattedHistory = history.map((item) {
        try {
          final date = DateTime.parse(item['timestamp']);
          return {
            ...item,
            'tanggal': DateFormat('dd MMM yyyy').format(date),
          };
        } catch (e) {
          return item;
        }
      }).toList();

      setState(() {
        sedekahHistory = formattedHistory;
        sedekahCategories = results[1] as List<String>;
        tips = results[2] as Map<String, dynamic>;
        totalSedekah = results[3] as int; // ✅ DARI FIREBASE
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
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

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  bool _validateInput() {
    if (jumlahController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah sedekah harus diisi'),
          backgroundColor: warningColor,
        ),
      );
      return false;
    }

    if (keteranganController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keterangan sedekah harus diisi'),
          backgroundColor: warningColor,
        ),
      );
      return false;
    }

    final jumlah = int.tryParse(jumlahController.text.replaceAll(',', ''));
    if (jumlah == null || jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah sedekah harus berupa angka positif'),
          backgroundColor: warningColor,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> handleAddSedekah() async {
    if (!_validateInput()) return;

    setState(() {
      isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      final jumlah = int.parse(jumlahController.text.replaceAll(',', ''));
      final keterangan = keteranganController.text;

      // ✅ SAVE TO FIREBASE
      final success = await FirebaseSedekahService.createSedekah(
        userId: userId,
        jumlah: jumlah,
        keterangan: keterangan,
        category: selectedCategory,
      );

      if (success) {
        // ✅ Reload data from Firebase
        await _loadData();

        jumlahController.clear();
        keteranganController.clear();
        setState(() {
          selectedCategory = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sedekah berhasil dicatat di Firebase!'),
              backgroundColor: successColor,
            ),
          );
        }
      } else {
        throw Exception('Failed to save sedekah');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan sedekah: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _handleDeleteSedekah(String sedekahId) async {
    try {
      // ✅ DELETE FROM FIREBASE
      final success = await FirebaseSedekahService.deleteSedekah(sedekahId);

      if (success) {
        await _loadData(); // Reload data

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sedekah berhasil dihapus'),
              backgroundColor: successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus sedekah: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  void _showCategoryPicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? darkCardBackgroundColor : cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Kategori',
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: isDark ? darkTextColor : textColor,
              ),
            ),
            const SizedBox(height: paddingMedium),
            ...sedekahCategories.map((category) => ListTile(
                  title: Text(
                    category,
                    style: TextStyle(color: isDark ? darkTextColor : textColor),
                  ),
                  trailing: selectedCategory == category
                      ? const Icon(Icons.check, color: successColor)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                    Navigator.pop(context);
                  },
                )),
            ListTile(
              title: const Text(
                'Hapus Kategori',
                style: TextStyle(color: errorColor),
              ),
              trailing: const Icon(Icons.clear, color: errorColor),
              onTap: () {
                setState(() {
                  selectedCategory = null;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
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
          title: const Text('Sedekah'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
      appBar: AppBar(
        title: const Text('Sedekah'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Text(
                  'Tracking Sedekah',
                  style: TextStyle(
                    fontSize: fontSizeXLarge,
                    fontWeight: FontWeight.bold,
                    color: isDark ? darkTextColor : textColor,
                  ),
                ),
                const SizedBox(height: paddingSmall),
                Text(
                  'Catat setiap sedekah yang Anda lakukan',
                  style: TextStyle(
                    fontSize: fontSizeNormal,
                    color: isDark ? darkTextColorLight : textColorLight,
                  ),
                ),

                const SizedBox(height: paddingLarge),

                // TOTAL SEDEKAH
                Container(
                  padding: const EdgeInsets.all(paddingMedium),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [primaryColorLight, primaryColorDark]
                          : [primaryColor, primaryColorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(borderRadiusNormal),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Sedekah Bulan Ini',
                        style: TextStyle(
                          color: textColorWhite,
                          fontSize: fontSizeNormal,
                        ),
                      ),
                      const SizedBox(height: paddingSmall),
                      Text(
                        'Rp${_formatRupiah(totalSedekah)}',
                        style: const TextStyle(
                          color: textColorWhite,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: paddingSmall),
                      Text(
                        '${sedekahHistory.length} kali sedekah',
                        style: const TextStyle(
                          color: textColorWhite,
                          fontSize: fontSizeSmall,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: paddingLarge),

                // INPUT SEDEKAH
                Text(
                  'Tambah Sedekah',
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: isDark ? darkTextColor : textColor,
                  ),
                ),
                const SizedBox(height: paddingSmall),

                // Input Jumlah
                TextField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? darkTextColor : textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? darkCardBackgroundColor : Colors.white,
                    hintText: 'Masukkan jumlah sedekah (Rp)',
                    hintStyle: TextStyle(
                      color: isDark ? darkTextColorLight : textColorLighter,
                    ),
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: isDark ? darkTextColorLight : textColorLight,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? darkBorderColor : borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? darkBorderColor : borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? primaryColorLight : primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: paddingSmall),

                // Input Keterangan
                TextField(
                  controller: keteranganController,
                  style: TextStyle(color: isDark ? darkTextColor : textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? darkCardBackgroundColor : Colors.white,
                    hintText: 'Keterangan (misal: Sedekah ke masjid)',
                    hintStyle: TextStyle(
                      color: isDark ? darkTextColorLight : textColorLighter,
                    ),
                    prefixIcon: Icon(
                      Icons.description,
                      color: isDark ? darkTextColorLight : textColorLight,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? darkBorderColor : borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? darkBorderColor : borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      borderSide: BorderSide(
                        color: isDark ? primaryColorLight : primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: paddingSmall),

                // Category Selector
                InkWell(
                  onTap: () => _showCategoryPicker(isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: paddingMedium,
                      vertical: paddingNormal,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? darkCardBackgroundColor : Colors.white,
                      borderRadius: BorderRadius.circular(borderRadiusNormal),
                      border: Border.all(
                        color: isDark ? darkBorderColor : borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.category,
                          color: isDark ? darkTextColorLight : textColorLight,
                        ),
                        const SizedBox(width: paddingSmall),
                        Expanded(
                          child: Text(
                            selectedCategory ?? 'Pilih Kategori (Opsional)',
                            style: TextStyle(
                              color: selectedCategory != null
                                  ? (isDark ? darkTextColor : textColor)
                                  : (isDark
                                      ? darkTextColorLight
                                      : textColorLighter),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: isDark ? darkTextColorLight : textColorLight,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: paddingMedium),

                SizedBox(
                  width: double.infinity,
                  height: buttonHeightNormal,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : handleAddSedekah,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successColor,
                      disabledBackgroundColor: successColor.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadiusNormal),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Catat Sedekah',
                            style: TextStyle(
                              color: textColorWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: paddingLarge),

                // RIWAYAT SEDEKAH
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Sedekah',
                      style: TextStyle(
                        fontSize: fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: isDark ? darkTextColor : textColor,
                      ),
                    ),
                    if (sedekahHistory.isNotEmpty)
                      Text(
                        '${sedekahHistory.length} catatan',
                        style: TextStyle(
                          fontSize: fontSizeSmall,
                          color: isDark ? darkTextColorLight : textColorLight,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: paddingMedium),

                sedekahHistory.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(paddingLarge),
                          child: Text(
                            'Belum ada riwayat sedekah',
                            style: TextStyle(
                              fontSize: fontSizeNormal,
                              color:
                                  isDark ? darkTextColorLight : textColorLight,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: sedekahHistory.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: paddingMedium),
                            child: Dismissible(
                              key: Key(item['id'].toString()),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: isDark
                                        ? darkCardBackgroundColor
                                        : cardBackgroundColor,
                                    title: Text(
                                      'Hapus Sedekah',
                                      style: TextStyle(
                                        color:
                                            isDark ? darkTextColor : textColor,
                                      ),
                                    ),
                                    content: Text(
                                      'Yakin ingin menghapus data sedekah ini?',
                                      style: TextStyle(
                                        color: isDark
                                            ? darkTextColorLight
                                            : textColorLight,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          'Batal',
                                          style: TextStyle(
                                            color: isDark
                                                ? primaryColorLight
                                                : primaryColor,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: errorColor),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) =>
                                  _handleDeleteSedekah(item['id']),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.only(right: paddingMedium),
                                decoration: BoxDecoration(
                                  color: errorColor,
                                  borderRadius:
                                      BorderRadius.circular(borderRadiusNormal),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              child: _buildSedekahCard(item, isDark),
                            ),
                          );
                        }).toList(),
                      ),

                const SizedBox(height: paddingLarge),

                // TIPS SEDEKAH
                if (tips.isNotEmpty)
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
                          tips['title']?.toString() ?? '💰 Tips Sedekah',
                          style: TextStyle(
                            fontSize: fontSizeNormal,
                            fontWeight: FontWeight.w600,
                            color: isDark ? darkTextColor : textColor,
                          ),
                        ),
                        const SizedBox(height: paddingSmall),
                        if (tips['items'] != null)
                          ...(tips['items'] as List<dynamic>).map((tip) {
                            return Padding(
                              padding: const EdgeInsets.only(top: paddingSmall),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: TextStyle(
                                      fontSize: fontSizeSmall,
                                      color: isDark
                                          ? darkTextColorLight
                                          : textColorLight,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      tip.toString(),
                                      style: TextStyle(
                                        fontSize: fontSizeSmall,
                                        color: isDark
                                            ? darkTextColorLight
                                            : textColorLight,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),

                const SizedBox(height: paddingLarge),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: selectedNavIndex,
        onTap: handleNavigation,
      ),
    );
  }

  Widget _buildSedekahCard(Map<String, dynamic> item, bool isDark) {
    return Card(
      elevation: 2,
      color: isDark ? darkCardBackgroundColor : cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
      ),
      child: Padding(
        padding: const EdgeInsets.all(paddingMedium),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(borderRadiusNormal),
              ),
              child: const Icon(
                Icons.favorite,
                color: successColor,
                size: iconSizeNormal,
              ),
            ),
            const SizedBox(width: paddingNormal),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['keterangan'].toString(),
                    style: TextStyle(
                      fontSize: fontSizeMedium,
                      fontWeight: FontWeight.w600,
                      color: isDark ? darkTextColor : textColor,
                    ),
                  ),
                  const SizedBox(height: paddingSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isDark ? darkTextColorLight : textColorLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['tanggal'].toString(),
                        style: TextStyle(
                          fontSize: fontSizeSmall,
                          color: isDark ? darkTextColorLight : textColorLight,
                        ),
                      ),
                    ],
                  ),
                  if (item['category'] != null) ...[
                    const SizedBox(height: paddingSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: paddingSmall,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(borderRadiusSmall),
                        border: Border.all(color: infoColor),
                      ),
                      child: Text(
                        item['category'].toString(),
                        style: const TextStyle(
                          fontSize: fontSizeSmall,
                          color: infoColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Amount
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: paddingSmall,
                vertical: paddingXSmall,
              ),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(borderRadiusSmall),
              ),
              child: Text(
                'Rp${_formatRupiah(item['jumlah'] as int)}',
                style: const TextStyle(
                  fontSize: fontSizeSmall,
                  color: successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
