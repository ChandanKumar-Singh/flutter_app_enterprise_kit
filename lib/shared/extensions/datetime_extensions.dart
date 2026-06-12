extension DateTimeExtensions on DateTime {
  // ── Checks ─────────────────────────────────────────────────────────────────
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return isAfter(start.startOfDay) && isBefore(end.endOfDay);
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  bool get isThisYear => year == DateTime.now().year;

  bool get isPast => isBefore(DateTime.now());
  bool get isFuture => isAfter(DateTime.now());

  bool get isWeekend => weekday == DateTime.saturday || weekday == DateTime.sunday;
  bool get isWeekday => !isWeekend;

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isBetween(DateTime start, DateTime end) =>
      isAfter(start) && isBefore(end);

  // ── Navigation ─────────────────────────────────────────────────────────────
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
  DateTime get startOfWeek => subtract(Duration(days: weekday - 1)).startOfDay;
  DateTime get endOfWeek => startOfWeek.add(const Duration(days: 6)).endOfDay;
  DateTime get startOfMonth => DateTime(year, month, 1);
  DateTime get endOfMonth => DateTime(year, month + 1, 0).endOfDay;
  DateTime get startOfYear => DateTime(year, 1, 1);
  DateTime get endOfYear => DateTime(year, 12, 31).endOfDay;

  DateTime addWorkdays(int days) {
    var result = this;
    int added = 0;
    while (added < days) {
      result = result.add(const Duration(days: 1));
      if (result.isWeekday) added++;
    }
    return result;
  }

  // ── Formatting ─────────────────────────────────────────────────────────────
  String get formatted => '$day/${_pad(month)}/$year';
  String get formattedUS => '${_pad(month)}/${_pad(day)}/$year';
  String get formattedISO => toIso8601String().substring(0, 10);
  String get formattedDateTime => '$formattedISO ${_pad(hour)}:${_pad(minute)}';
  String get formattedTime => '${_pad(hour)}:${_pad(minute)}';
  String get formattedTimeWithSeconds => '${_pad(hour)}:${_pad(minute)}:${_pad(second)}';
  String get formattedFull => '$dayName, $day $monthName $year';

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  String get monthName => const [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ][month];

  String get monthNameShort => monthName.substring(0, 3);

  String get dayName => const [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ][weekday];

  String get dayNameShort => dayName.substring(0, 3);

  // ── Utility ────────────────────────────────────────────────────────────────
  Duration durationUntil(DateTime other) => other.difference(this);
  int get daysInMonth => DateTime(year, month + 1, 0).day;
  int get weekOfYear => ((difference(DateTime(year, 1, 1)).inDays + 1) / 7).ceil();
  int get quarter => ((month - 1) / 3).floor() + 1;
  int get age {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) age--;
    return age;
  }

  DateTime copyWith({
    int? year, int? month, int? day,
    int? hour, int? minute, int? second, int? millisecond,
  }) => DateTime(
    year ?? this.year, month ?? this.month, day ?? this.day,
    hour ?? this.hour, minute ?? this.minute, second ?? this.second,
    millisecond ?? this.millisecond,
  );

  String _pad(int v) => v.toString().padLeft(2, '0');
}

extension NullableDateTimeExtensions on DateTime? {
  String get orEmpty => this == null ? '' : this!.formatted;
  bool get isNullOrPast => this == null || this!.isPast;
}
