sealed class ProfileDeleteIntent {
  const ProfileDeleteIntent();
}

final class PasswordChanged extends ProfileDeleteIntent {
  final String value;

  const PasswordChanged(this.value);
}

final class PasswordVisibilityToggled extends ProfileDeleteIntent {
  const PasswordVisibilityToggled();
}

final class ValidatePressed extends ProfileDeleteIntent {
  const ValidatePressed();
}

final class SubmitPressed extends ProfileDeleteIntent {
  const SubmitPressed();
}
