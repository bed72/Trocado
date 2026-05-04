sealed class ProfilePasswordIntent {
  const ProfilePasswordIntent();
}

final class NewPasswordChanged extends ProfilePasswordIntent {
  final String value;
  const NewPasswordChanged(this.value);
}

final class ConfirmPasswordChanged extends ProfilePasswordIntent {
  final String value;
  const ConfirmPasswordChanged(this.value);
}

final class NewPasswordVisibilityToggled extends ProfilePasswordIntent {
  const NewPasswordVisibilityToggled();
}

final class ConfirmPasswordVisibilityToggled extends ProfilePasswordIntent {
  const ConfirmPasswordVisibilityToggled();
}

final class SubmitPressed extends ProfilePasswordIntent {
  const SubmitPressed();
}
