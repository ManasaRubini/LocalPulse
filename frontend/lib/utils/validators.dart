class Validators {
  static String? requiredField(String? value, {String fieldName = "Field"}) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName cannot be empty";
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length < 8) {
      return "Please enter a valid phone number";
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 4) {
      return "Password must be at least 4 characters";
    }
    return null;
  }
}
