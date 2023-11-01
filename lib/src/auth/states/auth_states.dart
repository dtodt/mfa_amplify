//
sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthFailed extends AuthState {
  final Exception failure;
  const AuthFailed(this.failure);
}

final class AuthLogged extends AuthState {
  final bool mfaEnabled;
  const AuthLogged(this.mfaEnabled);
}

final class AuthMfaCheck extends AuthState {
  const AuthMfaCheck();
}

final class AuthMfaCheckFailed extends AuthState {
  const AuthMfaCheckFailed();
}

final class AuthMfaProcessing extends AuthState {
  const AuthMfaProcessing();
}

final class AuthUnlogged extends AuthState {
  const AuthUnlogged();
}
