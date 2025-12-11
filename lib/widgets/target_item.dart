import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/target_ibadah_model.dart';

// TARGET ITEM WIDGET
// Widget untuk menampilkan satu item target di list
// Menampilkan: nama, kategori, checkbox, edit, delete

class TargetItem extends StatelessWidget {
  final TargetIbadah target;
  final Function(bool?)? onCheckboxChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCompletedToday;

  const TargetItem({
    Key? key,
    required this.target,
    this.onCheckboxChanged,
    this.onEdit,
    this.onDelete,
    this.isCompletedToday = false,
  }) : super(key: key);

  // Helper function untuk mendapatkan warna kategori
  Color _getCategoryColor() {
    switch (target.category) {
      case 'Sholat':
        return const Color(0xFF4CAF50); // Hijau
      case 'Qur\'an':
        return const Color(0xFF2196F3); // Biru
      case 'Sedekah':
        return const Color(0xFFFF9800); // Orange
      case 'Dzikir':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF757575); // Abu-abu
    }
  }

  // Helper function untuk mendapatkan icon kategori
  IconData _getCategoryIcon() {
    switch (target.category) {
      case 'Sholat':
        return Icons.mosque;
      case 'Qur\'an':
        return Icons.menu_book;
      case 'Sedekah':
        return Icons.favorite;
      case 'Dzikir':
        return Icons.favorite_border;
      default:
        return Icons.task_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();
    final categoryIcon = _getCategoryIcon();

    return Card(
      margin: const EdgeInsets.only(bottom: paddingNormal),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadiusNormal),
          // Tambahkan border di kiri jika completed
          border: isCompletedToday
              ? const Border(
                  left: BorderSide(
                    color: successColor,
                    width: 4,
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(paddingNormal),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isCompletedToday,
                  onChanged: onCheckboxChanged,
                  activeColor: successColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: paddingNormal),
              // Content (Nama, Kategori)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Target
                    Text(
                      target.name,
                      style: TextStyle(
                        fontSize: fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: isCompletedToday ? textColorLight : textColor,
                        decoration: isCompletedToday
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Kategori Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: paddingSmall,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(borderRadiusSmall),
                        border: Border.all(color: categoryColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryIcon,
                            size: iconSizeSmall,
                            color: categoryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            target.category,
                            style: TextStyle(
                              fontSize: fontSizeSmall,
                              fontWeight: FontWeight.w500,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Catatan jika ada
                    if (target.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: paddingSmall),
                        child: Text(
                          target.note,
                          style: const TextStyle(
                            fontSize: fontSizeSmall,
                            color: textColorLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: paddingSmall),
              // Action Buttons (Edit & Delete)
              PopupMenuButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: textColorLight,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: onEdit,
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                 ),
                  ),
                  PopupMenuItem(
                    onTap: onDelete,
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: errorColor),
                        SizedBox(width: 8),
                        Text(
                          'Hapus',
                          style: TextStyle(color: errorColor),
                        ),
                      ],
                    ),
               ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  TARGET ITEM SKELETON/LOADING

class TargetItemSkeleton extends StatelessWidget {
  const TargetItemSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: paddingNormal),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusNormal),
      ),
      child: Padding(
        padding: const EdgeInsets.all(paddingNormal),
        child: Row(
          children: [
            // Checkbox skeleton
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: paddingNormal),
            // Content skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama skeleton
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: paddingSmall),
                  // Kategori skeleton
                  Container(
                    height: 20,
                    width: 100,
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  EMPTY STATE WIDGET

class EmptyTargetState extends StatelessWidget {
  final String message;
  final String? subMessage;
  final IconData icon;
  final VoidCallback? onAddButtonPressed;

  const EmptyTargetState({
    Key? key,
    this.message = 'Tidak ada target ibadah',
    this.subMessage = 'Mulai dengan menambahkan target ibadah baru',
    this.icon = Icons.task_alt,
    this.onAddButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSizeLarge,
            color: textColorLighter,
          ),
          const SizedBox(height: paddingMedium),
          Text(
            message,
            style: const TextStyle(
              fontSize: fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: textColorLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (subMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: paddingSmall),
              child: Text(
                subMessage!,
                style: const TextStyle(
                  fontSize: fontSizeNormal,
                  color: textColorLighter,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (onAddButtonPressed != null)
            Padding(
              padding: const EdgeInsets.only(top: paddingMedium),
              child: ElevatedButton.icon(
                onPressed: onAddButtonPressed,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Target'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: paddingMedium,
                    vertical: paddingSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}