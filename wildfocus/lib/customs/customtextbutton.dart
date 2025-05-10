import 'package:flutter/material.dart';
import 'customcolors.dart';

class CustomTextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonText;
  final Color textColor;
  final TextStyle textStyle;

  const CustomTextButton({
    super.key,
    required this.onPressed,
    required this.buttonText,
    this.textColor = CustomColors.primaryText,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(buttonText, style: textStyle.copyWith(color: textColor)),
    );
  }
}