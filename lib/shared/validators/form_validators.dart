// Composable, type-safe validators for use with TextFormField.validator

typedef Validator = String? Function(String?);

class FormValidators {
  FormValidators._();

  // ── Compose: chain validators ──────────────────────────────────────────────
  static Validator compose(List<Validator> validators) {
    return (value) {
      for (final v in validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }

  // ── Required ───────────────────────────────────────────────────────────────
  static Validator required({String message = 'This field is required'}) =>
      (v) => (v == null || v.trim().isEmpty) ? message : null;

  // ── Email ──────────────────────────────────────────────────────────────────
  static Validator email({String message = 'Enter a valid email address'}) =>
      (v) => (v != null && v.isNotEmpty &&
          !RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(v))
          ? message : null;

  // ── Password ───────────────────────────────────────────────────────────────
  static Validator minLength(int min, {String? message}) =>
      (v) => (v != null && v.length < min) ? (message ?? 'Minimum $min characters') : null;

  static Validator maxLength(int max, {String? message}) =>
      (v) => (v != null && v.length > max) ? (message ?? 'Maximum $max characters') : null;

  static Validator exactLength(int len, {String? message}) =>
      (v) => (v != null && v.length != len) ? (message ?? 'Must be exactly $len characters') : null;

  static Validator strongPassword({
    String message = 'Password must be at least 8 characters with uppercase, lowercase, number, and special character',
  }) => (v) {
    if (v == null || v.isEmpty) return null;
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Must contain an uppercase letter';
    if (!v.contains(RegExp(r'[a-z]'))) return 'Must contain a lowercase letter';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Must contain a number';
    if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Must contain a special character';
    return null;
  };

  static Validator matchValue(String Function() getValue,
      {String message = 'Values do not match'}) =>
      (v) => (v != getValue()) ? message : null;

  // ── Phone ──────────────────────────────────────────────────────────────────
  static Validator phone({String message = 'Enter a valid phone number'}) =>
      (v) => (v != null && v.isNotEmpty &&
          !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v.replaceAll(RegExp(r'\s'), '')))
          ? message : null;

  // ── Numeric ───────────────────────────────────────────────────────────────
  static Validator numeric({String message = 'Must be a valid number'}) =>
      (v) => (v != null && v.isNotEmpty && double.tryParse(v) == null) ? message : null;

  static Validator integer({String message = 'Must be a whole number'}) =>
      (v) => (v != null && v.isNotEmpty && int.tryParse(v) == null) ? message : null;

  static Validator minValue(num min, {String? message}) =>
      (v) {
        if (v == null || v.isEmpty) return null;
        final n = double.tryParse(v);
        if (n == null) return 'Invalid number';
        return n < min ? (message ?? 'Minimum value is $min') : null;
      };

  static Validator maxValue(num max, {String? message}) =>
      (v) {
        if (v == null || v.isEmpty) return null;
        final n = double.tryParse(v);
        if (n == null) return 'Invalid number';
        return n > max ? (message ?? 'Maximum value is $max') : null;
      };

  static Validator range(num min, num max, {String? message}) =>
      compose([numeric(), minValue(min), maxValue(max, message: message)]);

  // ── URL ────────────────────────────────────────────────────────────────────
  static Validator url({String message = 'Enter a valid URL'}) =>
      (v) {
        if (v == null || v.isEmpty) return null;
        final uri = Uri.tryParse(v);
        return (uri == null || !uri.isAbsolute) ? message : null;
      };

  // ── Pattern ───────────────────────────────────────────────────────────────
  static Validator pattern(RegExp regex, {required String message}) =>
      (v) => (v != null && v.isNotEmpty && !regex.hasMatch(v)) ? message : null;

  // ── Name ──────────────────────────────────────────────────────────────────
  static Validator name({String message = 'Enter a valid name'}) =>
      (v) => (v != null && v.isNotEmpty &&
          !RegExp(r"^[a-zA-Z\s\-'.]+$").hasMatch(v)) ? message : null;

  // ── Date ──────────────────────────────────────────────────────────────────
  static Validator date({String format = 'dd/MM/yyyy', String? message}) =>
      (v) {
        if (v == null || v.isEmpty) return null;
        final date = DateTime.tryParse(v);
        return date == null ? (message ?? 'Enter a valid date') : null;
      };

  static Validator dateNotPast({String message = 'Date cannot be in the past'}) =>
      (v) {
        if (v == null || v.isEmpty) return null;
        final date = DateTime.tryParse(v);
        if (date == null) return 'Invalid date';
        return date.isBefore(DateTime.now()) ? message : null;
      };

  static Validator dateNotFuture({String message = 'Date cannot be in the future'}) =>
      (v) {
        if (v == null || v.isEmpty) return null;
        final date = DateTime.tryParse(v);
        if (date == null) return 'Invalid date';
        return date.isAfter(DateTime.now()) ? message : null;
      };

  // ── Credit Card ───────────────────────────────────────────────────────────
  static Validator creditCard({String message = 'Enter a valid card number'}) =>
      (v) {
        if (v == null || v.isEmpty) return null;
        final cleaned = v.replaceAll(RegExp(r'\D'), '');
        if (cleaned.length < 13 || cleaned.length > 19) return message;
        int sum = 0;
        bool alt = false;
        for (int i = cleaned.length - 1; i >= 0; i--) {
          int n = int.parse(cleaned[i]);
          if (alt) { n *= 2; if (n > 9) n -= 9; }
          sum += n;
          alt = !alt;
        }
        return sum % 10 != 0 ? message : null;
      };

  // ── Username ──────────────────────────────────────────────────────────────
  static Validator username({
    int minLength = 3,
    int maxLength = 30,
    String? message,
  }) => compose([
    FormValidators.minLength(minLength),
    FormValidators.maxLength(maxLength),
    pattern(RegExp(r'^[a-zA-Z0-9_\-.]+$'),
        message: message ?? 'Only letters, numbers, _, - and . are allowed'),
  ]);

  // ── File Size ─────────────────────────────────────────────────────────────
  static Validator fileSize(int maxBytes, {String? message}) =>
      (v) {
        if (v == null || v.isEmpty) return null;
        final size = int.tryParse(v);
        if (size == null) return null;
        return size > maxBytes
            ? (message ?? 'File size exceeds ${(maxBytes / 1024 / 1024).toStringAsFixed(1)} MB')
            : null;
      };

  // ── Convenience combos ────────────────────────────────────────────────────
  static Validator requiredEmail() => compose([required(), email()]);
  static Validator requiredPhone() => compose([required(), phone()]);
  static Validator requiredPassword() => compose([required(), strongPassword()]);
}
