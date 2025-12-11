import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:targetibadah_gamifikasi/services/firebase/firebase_target_service.dart';
import '../constants.dart';
import '../models/target_ibadah_model.dart';
import '../services/json_service.dart';
import '../services/target_service.dart';
import '../services/gamification_service.dart';
import '../widgets/bottom_navigation.dart';
import '../providers/theme_provider.dart';

class ProgressHomeScreen extends StatefulWidget {
  const ProgressHomeScreen({Key? key}) : super(key: key);

  @override
  State<ProgressHomeScreen> createState() => _ProgressHomeScreenState();
}

class _ProgressHomeScreenState extends State<ProgressHomeScreen> {
  // VARIABLES
  int selectedNavIndex = 2;
  String selectedFilter = 'Semua';
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  List<TargetIbadah> targets = [];
  List<String> filterCategories = ['Semua'];

  @override
  void initState() {
    super.initState();
    _loadJsonData();
    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // LOAD DATA dari Firebase
  Future<void> _loadJsonData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      if (userId.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // ✅ LOAD TARGETS DARI FIREBASE
      final results = await Future.wait([
        FirebaseTargetService.getTargetsByUserId(userId),
        JsonService.getCategoryNames(),
      ]);

      setState(() {
        targets = results[0] as List<TargetIbadah>;
        final categories = results[1] as List<String>;
        filterCategories = ['Semua', ...categories];
        isLoading = false;
      });

      print('✅ Loaded ${targets.length} targets from Firebase');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // HANDLE NAVIGATION
  void handleNavigation(int index) {
    setState(() {
      selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/progress');
        break;
      case 2:
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
      case 4:
        Navigator.pushNamed(context, '/setting');
        break;
    }
  }

  // FILTER & SEARCH TARGETS
  List<TargetIbadah> getFilteredTargets() {
    List<TargetIbadah> filtered = targets;

    if (selectedFilter != 'Semua') {
      filtered = filtered.where((t) => t.category == selectedFilter).toList();
    }

    if (searchController.text.isNotEmpty) {
      filtered = filtered
          .where((t) => t.name
              .toLowerCase()
              .contains(searchController.text.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  // GET STATISTICS
  Map<String, int> getStatistics() {
    int total = targets.length;
    int completed = targets.where((t) => t.isCompleted).length;
    int today = targets.where((t) => t.isForToday()).length;
    int overdue = targets.where((t) => t.isOverdue()).length;

    return {
      'total': total,
      'completed': completed,
      'today': today,
      'overdue': overdue,
    };
  }

  // DELETE TARGET
  void handleDeleteTarget(String targetId) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? darkCardBackgroundColor : cardBackgroundColor,
          title: Text(
            'Hapus Target?',
            style: TextStyle(color: isDark ? darkTextColor : textColor),
          ),
          content: Text(
            'Target yang dihapus tidak bisa dikembalikan.',
            style:
                TextStyle(color: isDark ? darkTextColorLight : textColorLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style:
                    TextStyle(color: isDark ? primaryColorLight : primaryColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                // ✅ DELETE MENGGUNAKAN FIREBASE
                final success =
                    await FirebaseTargetService.deleteTarget(targetId);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Target berhasil dihapus'),
                      backgroundColor: successColor,
                    ),
                  );
                  await _loadJsonData(); // Reload
                }
              },
              child: const Text('Hapus', style: TextStyle(color: errorColor)),
            ),
          ],
        );
      },
    );
  }

  // HANDLE EDIT TARGET
  void handleEditTarget(TargetIbadah target) {
    Navigator.pushNamed(
      context,
      '/edit_target',
      arguments: target,
    ).then((result) {
      if (result != null) {
        _loadJsonData(); // Reload data setelah edit
      }
    });
  }

  // HANDLE ADD TARGET
  void handleAddTarget() {
    Navigator.pushNamed(context, '/add_target').then((result) {
      if (result != null) {
        _loadJsonData(); // Reload data setelah tambah target
      }
    });
  }

  // TOGGLE COMPLETION
  void toggleTargetCompletion(String targetId, bool newValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      // ✅ UPDATE MENGGUNAKAN FIREBASE
      final success = await FirebaseTargetService.updateTargetCompletion(
        userId: userId,
        targetId: targetId,
        isCompleted: newValue,
      );

      if (success) {
        if (newValue) {
          final target = targets.firstWhere((t) => t.id == targetId);

          await JsonService.updateProgressOnTargetComplete(target.category);

          final todayTargets = targets.where((t) => t.isForToday()).length;
          final completedToday =
              targets.where((t) => t.isForToday() && t.isCompleted).length;

          await GamificationService.onTargetCompleted(
            userId: userId,
            completedToday: completedToday,
            totalToday: todayTargets,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Target selesai! Progress & poin diperbarui'),
              backgroundColor: successColor,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // ✅ RELOAD DATA DARI FIREBASE
        await _loadJsonData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gagal mengupdate target'),
            backgroundColor: errorColor,
          ),
        );
      }
    } catch (e) {
      print('❌ Error toggling target: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
        appBar: AppBar(
          title: const Text('Manajemen Target'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredTargets = getFilteredTargets();
    final stats = getStatistics();

    return Scaffold(
      backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
      appBar: AppBar(
        title: const Text('Manajemen Target'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // STATISTICS CARDS
            Container(
              padding: const EdgeInsets.all(paddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      stats['total']!.toString(),
                      Icons.task_alt,
                      primaryColor,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: paddingSmall),
                  Expanded(
                    child: _buildStatCard(
                      'Selesai',
                      stats['completed']!.toString(),
                      Icons.check_circle,
                      successColor,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: paddingSmall),
                  Expanded(
                    child: _buildStatCard(
                      'Hari Ini',
                      stats['today']!.toString(),
                      Icons.today,
                      accentColor,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: paddingSmall),
                  Expanded(
                    child: _buildStatCard(
                      'Terlambat',
                      stats['overdue']!.toString(),
                      Icons.warning,
                      errorColor,
                      isDark,
                    ),
                  ),
                ],
              ),
            ),

            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingMedium),
              child: TextField(
                controller: searchController,
                style: TextStyle(color: isDark ? darkTextColor : textColor),
                decoration: InputDecoration(
                  hintText: 'Cari target...',
                  hintStyle: TextStyle(
                    color: isDark ? darkTextColorLight : textColorLight,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? darkTextColorLight : textColorLight,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            color: isDark ? darkTextColorLight : textColorLight,
                          ),
                          onPressed: () {
                            searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor:
                      isDark ? darkCardBackgroundColor : cardBackgroundColor,
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
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: paddingMedium),

            // FILTER CATEGORIES
            SizedBox(
              height: 50,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: paddingMedium),
                  child: Row(
                    children: filterCategories.map((category) {
                      final isSelected = selectedFilter == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: paddingSmall),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (value) {
                            setState(() {
                              selectedFilter = category;
                            });
                          },
                          backgroundColor: isDark
                              ? darkCardBackgroundColor
                              : cardBackgroundColor,
                          selectedColor:
                              isDark ? primaryColorLight : primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? textColorWhite
                                : (isDark ? darkTextColor : textColor),
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? (isDark ? primaryColorLight : primaryColor)
                                : (isDark ? darkBorderColor : borderColor),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: paddingMedium),

            // TARGET LIST
            Expanded(
              child: filteredTargets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color:
                                isDark ? darkTextColorLight : textColorLighter,
                          ),
                          const SizedBox(height: paddingMedium),
                          Text(
                            searchController.text.isNotEmpty
                                ? 'Tidak ada target yang cocok'
                                : 'Tidak ada target',
                            style: TextStyle(
                              fontSize: fontSizeNormal,
                              color:
                                  isDark ? darkTextColorLight : textColorLight,
                            ),
                          ),
                          const SizedBox(height: paddingSmall),
                          TextButton.icon(
                            onPressed: handleAddTarget,
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Target'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: paddingMedium),
                      itemCount: filteredTargets.length,
                      itemBuilder: (context, index) {
                        final target = filteredTargets[index];
                        final isOverdue = target.isOverdue();
                        final isToday = target.isForToday();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: paddingNormal),
                          child: Card(
                            elevation: 2,
                            color: isDark
                                ? darkCardBackgroundColor
                                : cardBackgroundColor,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(borderRadiusNormal),
                              side: isOverdue
                                  ? const BorderSide(
                                      color: errorColor, width: 2)
                                  : BorderSide(
                                      color: isDark
                                          ? darkBorderColor
                                          : borderColor,
                                    ),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.all(paddingMedium),
                              leading: Checkbox(
                                value: target.isCompleted,
                                onChanged: (value) {
                                  toggleTargetCompletion(
                                      target.id, value ?? false);
                                },
                                activeColor: successColor,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    target.name,
                                    style: TextStyle(
                                      fontSize: fontSizeMedium,
                                      fontWeight: FontWeight.w600,
                                      decoration: target.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: target.isCompleted
                                          ? (isDark
                                              ? darkTextColorLight
                                              : textColorLight)
                                          : (isDark
                                              ? darkTextColor
                                              : textColor),
                                    ),
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
                                          color: isDark
                                              ? primaryColorLight
                                              : primaryColor,
                                          borderRadius: BorderRadius.circular(
                                              borderRadiusSmall),
                                        ),
                                        child: Text(
                                          target.category,
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
                                          color: isOverdue
                                              ? errorColor.withOpacity(0.1)
                                              : isToday
                                                  ? accentColor.withOpacity(0.1)
                                                  : infoColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                              borderRadiusSmall),
                                          border: Border.all(
                                            color: isOverdue
                                                ? errorColor
                                                : isToday
                                                    ? accentColor
                                                    : infoColor,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color: isOverdue
                                                  ? errorColor
                                                  : isToday
                                                      ? accentColor
                                                      : infoColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              target.getFormattedDate(),
                                              style: TextStyle(
                                                color: isOverdue
                                                    ? errorColor
                                                    : isToday
                                                        ? accentColor
                                                        : infoColor,
                                                fontSize: fontSizeSmall,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isOverdue)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: paddingSmall,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: errorColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                                borderRadiusSmall),
                                          ),
                                          child: const Text(
                                            'Terlambat',
                                            style: TextStyle(
                                              color: errorColor,
                                              fontSize: fontSizeSmall,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (target.note.isNotEmpty) ...[
                                    const SizedBox(height: paddingSmall),
                                    Text(
                                      target.note,
                                      style: TextStyle(
                                        fontSize: fontSizeSmall,
                                        color: isDark
                                            ? darkTextColorLight
                                            : textColorLight,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                              trailing: PopupMenuButton(
                                color: isDark
                                    ? darkCardBackgroundColor
                                    : cardBackgroundColor,
                                icon: Icon(
                                  Icons.more_vert,
                                  color: isDark ? darkTextColor : textColor,
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: isDark
                                              ? darkTextColor
                                              : textColor,
                                        ),
                                        const SizedBox(width: paddingSmall),
                                        Text(
                                          'Edit',
                                          style: TextStyle(
                                            color: isDark
                                                ? darkTextColor
                                                : textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Future.delayed(
                                        const Duration(milliseconds: 100),
                                        () => handleEditTarget(target),
                                      );
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: const Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 20, color: errorColor),
                                        SizedBox(width: paddingSmall),
                                        Text('Hapus',
                                            style:
                                                TextStyle(color: errorColor)),
                                      ],
                                    ),
                                    onTap: () {
                                      Future.delayed(
                                        const Duration(milliseconds: 100),
                                        () => handleDeleteTarget(target.id),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // FLOATING ACTION BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: handleAddTarget,
        backgroundColor: isDark ? primaryColorLight : primaryColor,
        child: const Icon(Icons.add, color: textColorWhite),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigation(
        currentIndex: selectedNavIndex,
        onTap: handleNavigation,
      ),
    );
  }

  // HELPER WIDGET - STAT CARD
  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(paddingSmall),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadiusNormal),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSizeSmall,
              color: isDark ? darkTextColorLight : textColorLight,
            ),
          ),
        ],
      ),
    );
  }
}