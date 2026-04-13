sealed class SignInEvents {
  const SignInEvents();
}

final class EmailChanged extends SignInEvents {
  final String value;
  const EmailChanged(this.value);
}

final class PasswordChanged extends SignInEvents {
  final String value;
  const PasswordChanged(this.value);
}

final class SubmitPressed extends SignInEvents {}
