sealed class SignUpIntent {
  const SignUpIntent();
}

final class EmailChanged extends SignUpIntent {
  final String value;
  const EmailChanged(this.value);
}

final class PasswordChanged extends SignUpIntent {
  final String value;
  const PasswordChanged(this.value);
}

final class TermsToggled extends SignUpIntent {
  final bool value;
  const TermsToggled(this.value);
}

final class PasswordVisibilityToggled extends SignUpIntent {
  const PasswordVisibilityToggled();
}

final class SubmitPressed extends SignUpIntent {
  const SubmitPressed();
}
