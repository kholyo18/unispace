sealed class Result<T> {
  const Result();
  factory Result.success(T data) = Success<T>;
  factory Result.error(Exception error) = Error<T>;
  factory Result.loading() = Loading<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Exception exception;
  const Error(this.exception);
}

class Loading<T> extends Result<T> {
  const Loading();
}

extension ResultExtensions<T> on Result<T> {
  void fold(void Function(T data) onSuccess, void Function(Exception error) onError) {
    if (this is Success<T>) {
      onSuccess((this as Success<T>).data);
    } else if (this is Error<T>) {
      onError((this as Error<T>).exception);
    }
  }

  T? getOrNull() => this is Success<T> ? (this as Success<T>).data : null;
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;
  bool get isLoading => this is Loading<T>;
}