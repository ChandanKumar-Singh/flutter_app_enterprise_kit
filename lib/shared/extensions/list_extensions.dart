extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;

  T? firstWhereOrNull(bool Function(T) test) {
    try { return firstWhere(test); } catch (_) { return null; }
  }

  List<T> distinct([Object Function(T)? keySelector]) {
    if (keySelector == null) return toSet().toList();
    final seen = <Object>{};
    return where((e) => seen.add(keySelector(e))).toList();
  }

  List<List<T>> chunked(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }

  Map<K, List<T>> groupBy<K>(K Function(T) keySelector) {
    final map = <K, List<T>>{};
    for (final item in this) {
      final key = keySelector(item);
      (map[key] ??= []).add(item);
    }
    return map;
  }

  List<T> sortedBy<K extends Comparable>(K Function(T) keySelector,
      {bool descending = false}) {
    final sorted = [...this]..sort((a, b) {
        final cmp = keySelector(a).compareTo(keySelector(b));
        return descending ? -cmp : cmp;
      });
    return sorted;
  }

  List<R> mapIndexed<R>(R Function(int index, T item) f) =>
      asMap().entries.map((e) => f(e.key, e.value)).toList();

  List<T> whereIndexed(bool Function(int index, T item) f) =>
      asMap().entries.where((e) => f(e.key, e.value)).map((e) => e.value).toList();

  List<T> interleave(T separator) {
    if (length <= 1) return toList();
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) result.add(separator);
    }
    return result;
  }

  T? get(int index) => (index >= 0 && index < length) ? this[index] : null;

  List<T> takeLast(int n) => length <= n ? toList() : sublist(length - n);

  List<T> toggle(T item) =>
      contains(item) ? (toList()..remove(item)) : (toList()..add(item));

  (List<T>, List<T>) partition(bool Function(T) test) {
    final yes = <T>[], no = <T>[];
    for (final e in this) { (test(e) ? yes : no).add(e); }
    return (yes, no);
  }

  bool containsAll(Iterable<T> items) => items.every(contains);
}

extension NullableListExtensions<T> on List<T>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  List<T> get orEmpty => this ?? [];
  int get safeLength => this?.length ?? 0;
}
