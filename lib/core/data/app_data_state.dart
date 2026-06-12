// ─── AppDataState ─────────────────────────────────────────────────────────────
// Sealed class representing the state of async data operations.
// Replaces ad-hoc isLoading/error/data booleans across the codebase.
//
// Usage:
//   AsyncValue<User>  ← Riverpod's version
//   AppDataState<User> ← use when NOT in Riverpod context (repository, UI without ref)
//
//   final state = AppDataState<User>.loading();
//   final state = AppDataState.data(user);
//   final state = AppDataState.error('Something went wrong', stackTrace);
//
//   // Pattern match:
//   state.when(
//     loading:  ()          => CircularProgressIndicator(),
//     data:     (user)      => UserCard(user),
//     error:    (e, stack)  => ErrorWidget(e.toString()),
//   );
// ─────────────────────────────────────────────────────────────────────────────

sealed class AppDataState<T> {
  const AppDataState();

  // ── Constructors ─────────────────────────────────────────────────────────

  const factory AppDataState.initial() = AppDataInitial<T>;
  const factory AppDataState.loading() = AppDataLoading<T>;
  const factory AppDataState.data(T value) = AppDataSuccess<T>;
  const factory AppDataState.error(Object error, [StackTrace? stackTrace]) =
      AppDataError<T>;

  // ── Convenience ──────────────────────────────────────────────────────────

  bool get isInitial   => this is AppDataInitial<T>;
  bool get isLoading   => this is AppDataLoading<T>;
  bool get hasData     => this is AppDataSuccess<T>;
  bool get hasError    => this is AppDataError<T>;

  T? get valueOrNull => hasData ? (this as AppDataSuccess<T>).value : null;

  // ── Pattern matching ─────────────────────────────────────────────────────

  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) =>
      switch (this) {
        AppDataInitial<T>()                  => initial(),
        AppDataLoading<T>()                  => loading(),
        AppDataSuccess<T> s                  => data(s.value),
        AppDataError<T> e                    => error(e.error, e.stackTrace),
      };

  R maybeWhen<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(T value)? data,
    R Function(Object error, StackTrace? stackTrace)? error,
    required R Function() orElse,
  }) =>
      switch (this) {
        AppDataInitial<T>() => initial?.call() ?? orElse(),
        AppDataLoading<T>() => loading?.call() ?? orElse(),
        AppDataSuccess<T> s => data?.call(s.value) ?? orElse(),
        AppDataError<T> e   => error?.call(e.error, e.stackTrace) ?? orElse(),
      };

  // ── Transform ────────────────────────────────────────────────────────────

  AppDataState<R> map<R>(R Function(T value) mapper) => switch (this) {
        AppDataSuccess<T> s => AppDataState.data(mapper(s.value)),
        AppDataLoading<T>() => const AppDataState.loading(),
        AppDataError<T> e   => AppDataState.error(e.error, e.stackTrace),
        _                   => const AppDataState.initial(),
      };

  @override
  String toString() => switch (this) {
        AppDataInitial()  => 'AppDataState.initial()',
        AppDataLoading()  => 'AppDataState.loading()',
        AppDataSuccess s  => 'AppDataState.data(${s.value})',
        AppDataError e    => 'AppDataState.error(${e.error})',
      };
}

// ── Subtypes ──────────────────────────────────────────────────────────────────

final class AppDataInitial<T> extends AppDataState<T> {
  const AppDataInitial();
}

final class AppDataLoading<T> extends AppDataState<T> {
  const AppDataLoading();
}

final class AppDataSuccess<T> extends AppDataState<T> {
  final T value;
  const AppDataSuccess(this.value);
}

final class AppDataError<T> extends AppDataState<T> {
  final Object error;
  final StackTrace? stackTrace;
  const AppDataError(this.error, [this.stackTrace]);
}
