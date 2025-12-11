import 'package:flutter/material.dart';
import '../constants.dart';

//  CUSTOM BUTTON WIDGET
// Widget tombol yang bisa digunakan di berbagai halaman
// dengan style yang konsisten

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double width;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final IconData? prefixIcon;
  final EdgeInsets padding;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = primaryColor,
    this.textColor = textColorWhite,
    this.width = double.infinity,
    this.height = buttonHeightNormal,
    this.borderRadius = borderRadiusNormal,
    this.isLoading = false,
    this.prefixIcon,
    this.padding = const EdgeInsets.symmetric(
      horizontal: paddingNormal,
      vertical: paddingSmall,
    ),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withOpacity(0.5),
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefixIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: paddingSmall),
                      child: Icon(
                        prefixIcon,
                        color: textColor,
                        size: iconSizeNormal,
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSizeMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

//  OUTLINED BUTTON VARIANT

class OutlinedCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color borderColor;
  final Color textColor;
  final double width;
  final double height;
  final double borderRadius;
  final IconData? prefixIcon;
  final EdgeInsets padding;

  const OutlinedCustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.borderColor = primaryColor,
    this.textColor = primaryColor,
    this.width = double.infinity,
    this.height = buttonHeightNormal,
    this.borderRadius = borderRadiusNormal,
    this.prefixIcon,
    this.padding = const EdgeInsets.symmetric(
      horizontal: paddingNormal,
      vertical: paddingSmall,
    ),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          side: BorderSide(color: borderColor, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefixIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: paddingSmall),
                child: Icon(
                  prefixIcon,
                  color: textColor,
                  size: iconSizeNormal,
                ),
              ),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TEXT BUTTON VARIANT

class TextCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final IconData? prefixIcon;

  const TextCustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.textColor = primaryColor,
    this.fontSize = fontSizeMedium,
    this.fontWeight = FontWeight.w600,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefixIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: paddingSmall),
              child: Icon(
                prefixIcon,
                color: textColor,
                size: iconSizeNormal,
              ),
            ),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}

// ICON BUTTON VARIANT

class IconCustomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  const IconCustomButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = primaryColor,
    this.iconColor = textColorWhite,
    this.size = 48,
    this.iconSize = iconSizeNormal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Icon(
            icon,
            color: iconColor,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}