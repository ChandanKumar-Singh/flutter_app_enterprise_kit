import 'package:intl/intl.dart';

class AppFormatter {
  AppFormatter._();

  // ── Currency ───────────────────────────────────────────────────────────────
  static String currency(
    num amount, {
    String symbol = '\$',
    String locale = 'en_US',
    int decimalDigits = 2,
    bool compact = false,
  }) {
    if (compact) {
      return '$symbol${_compact(amount)}';
    }
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  static String currencyCompact(num amount, {String symbol = '\$'}) =>
      '$symbol${_compact(amount)}';

  // ── Numbers ────────────────────────────────────────────────────────────────
  static String number(num n, {int? decimalDigits, String locale = 'en_US'}) =>
      NumberFormat.decimalPattern(locale).format(n);

  static String compact(num n) => _compact(n);

  static String percentage(num value, {int decimalDigits = 1}) =>
      '${value.toStringAsFixed(decimalDigits)}%';

  static String ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  // ── Date / Time ────────────────────────────────────────────────────────────
  static String date(DateTime dt, {String format = 'dd MMM yyyy', String? locale}) =>
      DateFormat(format, locale).format(dt);

  static String time(DateTime dt, {bool use24h = false, String? locale}) =>
      DateFormat(use24h ? 'HH:mm' : 'hh:mm a', locale).format(dt);

  static String dateTime(DateTime dt, {String? locale}) =>
      DateFormat('dd MMM yyyy, hh:mm a', locale).format(dt);

  static String relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'just now';
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }

  static String duration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  static String countdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    return duration(diff);
  }

  // ── Phone ──────────────────────────────────────────────────────────────────
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    if (digits.length == 11 && digits[0] == '1') {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    return raw;
  }

  // ── File size ──────────────────────────────────────────────────────────────
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ── Credit Card ───────────────────────────────────────────────────────────
  static String creditCard(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  static String maskedCard(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return raw;
    return '**** **** **** ${digits.substring(digits.length - 4)}';
  }

  // ── Text ──────────────────────────────────────────────────────────────────
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) =>
      text.length <= maxLength ? text
          : '${text.substring(0, maxLength - ellipsis.length)}$ellipsis';

  static String initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0].substring(0, words[0].length > 2 ? 2 : words[0].length).toUpperCase();
    return '${words[0][0]}${words.last[0]}'.toUpperCase();
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  static String _compact(num n) {
    final abs = n.abs();
    String suffix = '';
    double div = 1;
    if (abs >= 1e9) { suffix = 'B'; div = 1e9; }
    else if (abs >= 1e6) { suffix = 'M'; div = 1e6; }
    else if (abs >= 1e3) { suffix = 'K'; div = 1e3; }
    if (div == 1) return n.toString();
    final val = n / div;
    return val == val.floorToDouble()
        ? '${val.toInt()}$suffix'
        : '${val.toStringAsFixed(1)}$suffix';
  }
}
