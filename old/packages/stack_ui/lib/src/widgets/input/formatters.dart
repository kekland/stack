import 'package:flutter/services.dart';

class E164TextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only digits and a leading '+' character
    final String newText = newValue.text.replaceAll(RegExp(r'[^0-9+]'), '');

    // Ensure the first character is '+' if it exists
    if (newText.isNotEmpty && newText[0] != '+') {
      return TextEditingValue(
        text: '+$newText',
        selection: TextSelection.collapsed(offset: newText.length + 1),
      );
    }

    // Limit the length to 16 characters (including '+')
    if (newText.length > 16) {
      return oldValue;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
