import 'package:flutter/material.dart';
import 'customcolors.dart';

InputDecoration customInputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: CustomColors.hintText),
    filled: true,
    fillColor: CustomColors.textfieldFill,
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    prefixIconColor: CustomColors.iconColor,
    errorStyle: const TextStyle(color: CustomColors.error),
  );
}
