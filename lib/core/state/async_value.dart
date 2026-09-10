/// Lightweight async state for presentation controllers.
///
/// Screens use this to distinguish loading / data / error without a
/// state-management framework.
sealed class AsyncValue<T> {
  const AsyncValue();

  bool get isLoading => this is AsyncLoading<T>;

  Object? get error => switch (this) {
    AsyncError<T>(:final error) => error,
    _ => null,
  };

  T? get valueOrNull => switch (this) {
    AsyncData<T>(:final value) => value,
    _ => null,
  };

  R maybeWhen<R>({
    required R Function() orElse,
    R Function(T data)? data,
    R Function()? loading,
    R Function(Object error, StackTrace stackTrace)? error,
  }) {
    return switch (this) {
      AsyncData<T>(:final value) when data != null => data(value),
      AsyncLoading<T>() when loading != null => loading(),
      AsyncError<T>(error: final err, stackTrace: final st)
          when error != null =>
        error(err, st),
      _ => orElse(),
    };
  }

  R when<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(Object error, StackTrace stackTrace) error,
  }) {
    return switch (this) {
      AsyncData<T>(:final value) => data(value),
      AsyncLoading<T>() => loading(),
      AsyncError<T>(error: final err, stackTrace: final st) => error(err, st),
    };
  }
}

final class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.value);

  final T value;
}

final class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

final class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(this.error, this.stackTrace);

  @override
  final Object error;
  final StackTrace stackTrace;
}
