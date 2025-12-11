import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ⬅️ TAMBAHKAN
import '../constants.dart';
import '../providers/theme_provider.dart'; // ⬅️ TAMBAHKAN

// CUSTOM TEXT FIELD WIDGET dengan Dark Mode Support
class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final String? Function(String?)? validator;
  final int maxLines;
  final int minLines;
  final int? maxLength;
  final TextInputAction textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? backgroundColor;
  final EdgeInsets contentPadding;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.validator,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.borderColor, // ⬅️ NULLABLE
    this.focusedBorderColor, // ⬅️ NULLABLE
    this.backgroundColor, // ⬅️ NULLABLE
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: paddingMedium,
      vertical: paddingNormal,
    ),
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ⬅️ GET THEME STATE
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // ⬅️ DYNAMIC COLORS
    final dynamicBorderColor = widget.borderColor ?? (isDark ? darkBorderColor : borderColor);
    final dynamicFocusedBorderColor = widget.focusedBorderColor ?? (isDark ? primaryColorLight : primaryColor);
    final dynamicBackgroundColor = widget.backgroundColor ?? (isDark ? darkCardBackgroundColor : cardBackgroundColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: paddingSmall),
          child: Text(
            widget.label,
            style: TextStyle(
              color: isDark ? darkTextColor : textColor,
              fontSize: fontSizeMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Text Field
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          maxLines: _obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          style: TextStyle(
            color: isDark ? darkTextColor : textColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: dynamicBackgroundColor,
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: isDark ? darkTextColorLight : textColorLighter,
              fontSize: fontSizeNormal,
            ),
            contentPadding: widget.contentPadding,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: isDark ? darkTextColorLight : textColorLight,
                  )
                : null,
            suffixIcon: widget.suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      widget.suffixIcon,
                      color: isDark ? darkTextColorLight : textColorLight,
                    ),
                    onPressed: widget.onSuffixIconPressed ?? () {},
                  )
                : (widget.obscureText
                    ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: isDark ? darkTextColorLight : textColorLight,
                        ),
                        onPressed: _toggleObscureText,
                      )
                    : null),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadiusNormal),
              borderSide: BorderSide(color: dynamicBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadiusNormal),
              borderSide: BorderSide(color: dynamicBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadiusNormal),
              borderSide: BorderSide(
                color: dynamicFocusedBorderColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadiusNormal),
              borderSide: const BorderSide(
                color: errorColor,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadiusNormal),
              borderSide: const BorderSide(
                color: errorColor,
                width: 2,
              ),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

// SEARCH TEXT FIELD dengan Dark Mode
class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;
  final VoidCallback? onClear;

  const SearchTextField({
    Key? key,
    required this.controller,
    this.hint = 'Cari...',
    this.onChanged,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ⬅️ GET THEME STATE
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        color: isDark ? darkTextColor : textColor,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? darkCardBackgroundColor : cardBackgroundColor,
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? darkTextColorLight : textColorLighter,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingMedium,
          vertical: paddingNormal,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: isDark ? darkTextColorLight : textColorLight,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? darkTextColorLight : textColorLight,
                ),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide(
            color: isDark ? darkBorderColor : borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide(
            color: isDark ? darkBorderColor : borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide(
            color: isDark ? primaryColorLight : primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}

// TEXTAREA dengan Dark Mode
class TextArea extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  const TextArea({
    Key? key,
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 5,
    this.maxLength,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ⬅️ GET THEME STATE
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: paddingSmall),
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? darkTextColor : textColor,
              fontSize: fontSizeMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: 3,
          maxLength: maxLength,
          validator: validator,
          style: TextStyle(
            color: isDark ? darkTextColor : textColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? darkCardBackgroundColor : cardBackgroundColor,
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? darkTextColorLight : textColorLighter,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: paddingMedium,
              vertical: paddingMedium,
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
            counterText: '',
          ),
        ),
      ],
    );
  }
}