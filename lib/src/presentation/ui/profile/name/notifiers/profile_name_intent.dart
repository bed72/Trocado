sealed class ProfileNameIntent {
  const ProfileNameIntent();
}

final class NameChanged extends ProfileNameIntent {
  final String value;
  const NameChanged(this.value);
}

final class SubmitPressed extends ProfileNameIntent {
  const SubmitPressed();
}
