sealed class ButtonAnimatedState {
  const ButtonAnimatedState();
}

final class InitialState extends ButtonAnimatedState {
  const InitialState();
}

final class LoadingState extends ButtonAnimatedState {
  const LoadingState();
}

final class SuccessState extends ButtonAnimatedState {
  const SuccessState();
}

final class FailureState extends ButtonAnimatedState {
  const FailureState();
}
