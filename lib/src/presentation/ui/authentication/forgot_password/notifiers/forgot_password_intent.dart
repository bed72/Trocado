sealed class ForgotPasswordIntent {
  const ForgotPasswordIntent();
}

final class EmailChanged extends ForgotPasswordIntent {
  final String value;
  const EmailChanged(this.value);
}

final class SubmitPressed extends ForgotPasswordIntent {
  const SubmitPressed();
}
