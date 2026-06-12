extension MapExtensions<K, V> on Map<K, V> {
  Map<K, V> merge(Map<K, V> other, {V Function(V a, V b)? conflictResolver}) {
    final result = Map<K, V>.from(this);
    for (final entry in other.entries) {
      if (result.containsKey(entry.key) && conflictResolver != null) {
        result[entry.key] = conflictResolver(result[entry.key] as V, entry.value);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  Map<K, V> filter(bool Function(K key, V value) test) =>
      Map.fromEntries(entries.where((e) => test(e.key, e.value)));

  Map<K, R> mapValues<R>(R Function(K key, V value) f) =>
      Map.fromEntries(entries.map((e) => MapEntry(e.key, f(e.key, e.value))));

  Map<R, V> mapKeys<R>(R Function(K key) f) =>
      Map.fromEntries(entries.map((e) => MapEntry(f(e.key), e.value)));

  V? getOrNull(K key) => containsKey(key) ? this[key] : null;

  V getOrDefault(K key, V defaultValue) => this[key] ?? defaultValue;

  Map<V, K> get inverted => Map.fromEntries(entries.map((e) => MapEntry(e.value, e.key)));

  Map<K, V> whereValues(bool Function(V) test) =>
      filter((_, v) => test(v));

  Map<K, V> whereKeys(bool Function(K) test) =>
      filter((k, _) => test(k));

  List<R> toList<R>(R Function(K key, V value) transform) =>
      entries.map((e) => transform(e.key, e.value)).toList();
}

extension NumExtensions on num {
  bool get isPositive => this > 0;
  bool get isNegative => this < 0;
  bool get isZero => this == 0;

  double get asDouble => toDouble();
  int get asInt => toInt();

  num clamp(num min, num max) => this < min ? min : (this > max ? max : this);

  num get abs => this < 0 ? -this : this;

  bool isBetween(num min, num max) => this >= min && this <= max;

  String toStringFixed(int fractionDigits) =>
      toStringAsFixed(fractionDigits);

  String get compactFormat {
    if (abs >= 1e9) return '${(this / 1e9).toStringAsFixed(1)}B';
    if (abs >= 1e6) return '${(this / 1e6).toStringAsFixed(1)}M';
    if (abs >= 1e3) return '${(this / 1e3).toStringAsFixed(1)}K';
    return toString();
  }
}
