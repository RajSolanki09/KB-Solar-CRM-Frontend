import 'package:flutter/services.dart';

class FormValidators {
  // Phone number validation for Indian mobile numbers
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    String phone = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
    
    if (phone.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      return 'Please enter a valid Indian mobile number';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    String name = value.trim();
    
    if (name.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (name.length > 50) {
      return '$fieldName cannot exceed 50 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(name)) {
      return '$fieldName can only contain letters, spaces, and periods';
    }
    
    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    String email = value.trim();
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Number validation with range
  static String? validateNumber(String? value, {
    String fieldName = 'Field',
    bool required = true,
    double? min,
    double? max,
    bool allowZero = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$fieldName is required' : null;
    }
    
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
      return 'Please enter a valid number';
    }
    
    double? numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Please enter a valid number';
    }
    
    if (min != null && numValue < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && numValue > max) {
      return '$fieldName must be at most $max';
    }
    
    if (!allowZero && numValue <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }

  // Address validation
  static String? validateAddress(String? value, {String fieldName = 'Address'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    String address = value.trim();
    
    if (address.length < 5) {
      return '$fieldName must be at least 5 characters';
    }
    
    if (address.length > 200) {
      return '$fieldName cannot exceed 200 characters';
    }
    
    return null;
  }

  // Village/City validation
  static String? validateVillage(String? value, {String fieldName = 'Village'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    String village = value.trim();
    
    if (village.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (village.length > 50) {
      return '$fieldName cannot exceed 50 characters';
    }
    
    return null;
  }

  // Notes validation
  static String? validateNotes(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Notes are required' : null;
    }
    
    String notes = value.trim();
    
    if (notes.length < 3) {
      return 'Notes must be at least 3 characters';
    }
    
    if (notes.length > 500) {
      return 'Notes cannot exceed 500 characters';
    }
    
    return null;
  }

  // Dropdown validation
  static String? validateDropdown(dynamic value, String fieldName) {
    if (value == null) {
      return 'Please select $fieldName';
    }
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // PIN code validation (Indian)
  static String? validatePinCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PIN code is required';
    }
    
    String pin = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
    
    if (pin.length != 6) {
      return 'PIN code must be exactly 6 digits';
    }
    
    return null;
  }

  // Amount validation (for financial fields)
  static String? validateAmount(String? value, {
    String fieldName = 'Amount',
    double? minAmount,
    double? maxAmount,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
      return 'Please enter a valid amount';
    }
    
    double? amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    if (minAmount != null && amount < minAmount) {
      return '$fieldName must be at least ₹$minAmount';
    }
    
    if (maxAmount != null && amount > maxAmount) {
      return '$fieldName cannot exceed ₹$maxAmount';
    }
    
    return null;
  }
}

// Custom input formatter for phone numbers
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to 10 digits
    if (newText.length > 10) {
      newText = newText.substring(0, 10);
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// Custom input formatter for numbers only
class NumberFormatter extends TextInputFormatter {
  final bool allowDecimal;
  
  NumberFormatter({this.allowDecimal = false});
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    
    if (allowDecimal) {
      // Allow numbers and only one decimal point
      newText = newText.replaceAll(RegExp(r'[^0-9.]'), '');
      
      // Prevent multiple decimal points
      int dotCount = '.'.allMatches(newText).length;
      if (dotCount > 1) {
        int lastDotIndex = newText.lastIndexOf('.');
        newText = newText.substring(0, lastDotIndex) + 
                   newText.substring(lastDotIndex + 1).replaceAll('.', '');
      }
    } else {
      // Allow only numbers
      newText = newText.replaceAll(RegExp(r'[^0-9]'), '');
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
