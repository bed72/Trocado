sealed class ValidationBase<T> {
  const ValidationBase();
}

final class Valid<T> extends ValidationBase<T> {
  final T value;
  const Valid(this.value);
}

final class Invalid<T> extends ValidationBase<T> {
  final String message;
  const Invalid(this.message);
}

abstract interface class Validation<T> {
  ValidationBase<T> call(T value);
}
