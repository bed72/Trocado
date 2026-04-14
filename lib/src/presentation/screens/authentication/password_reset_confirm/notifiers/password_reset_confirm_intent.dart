sealed class PasswordResetConfirmIntent {
  const PasswordResetConfirmIntent();
}

final class NewPasswordChanged extends PasswordResetConfirmIntent {
  final String value;
  const NewPasswordChanged(this.value);
}

final class ConfirmPasswordChanged extends PasswordResetConfirmIntent {
  final String value;
  const ConfirmPasswordChanged(this.value);
}

final class SubmitPressed extends PasswordResetConfirmIntent {
  const SubmitPressed();
}
