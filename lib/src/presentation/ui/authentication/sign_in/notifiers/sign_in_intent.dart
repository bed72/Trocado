sealed class SignInIntent {
  const SignInIntent();
}

final class EmailChanged extends SignInIntent {
  final String value;
  const EmailChanged(this.value);
}

final class PasswordChanged extends SignInIntent {
  final String value;
  const PasswordChanged(this.value);
}

final class PasswordVisibilityToggled extends SignInIntent {
  const PasswordVisibilityToggled();
}

final class SubmitPressed extends SignInIntent {
  const SubmitPressed();
}
