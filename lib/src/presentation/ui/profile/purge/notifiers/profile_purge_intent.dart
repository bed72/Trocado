sealed class ProfilePurgeIntent {
  const ProfilePurgeIntent();
}

final class PasswordChanged extends ProfilePurgeIntent {
  final String value;

  const PasswordChanged(this.value);
}

final class PasswordVisibilityToggled extends ProfilePurgeIntent {
  const PasswordVisibilityToggled();
}

final class ValidatePressed extends ProfilePurgeIntent {
  const ValidatePressed();
}

final class SubmitPressed extends ProfilePurgeIntent {
  const SubmitPressed();
}
