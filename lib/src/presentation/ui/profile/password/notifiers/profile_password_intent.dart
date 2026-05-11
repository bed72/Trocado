sealed class ProfilePasswordIntent {
  const ProfilePasswordIntent();
}

final class NewPasswordChanged extends ProfilePasswordIntent {
  final String value;
  const NewPasswordChanged(this.value);
}

final class CurrentPasswordChanged extends ProfilePasswordIntent {
  final String value;
  const CurrentPasswordChanged(this.value);
}

final class NewPasswordVisibilityToggled extends ProfilePasswordIntent {
  const NewPasswordVisibilityToggled();
}

final class CurrentPasswordVisibilityToggled extends ProfilePasswordIntent {
  const CurrentPasswordVisibilityToggled();
}

final class SubmitPressed extends ProfilePasswordIntent {
  const SubmitPressed();
}
