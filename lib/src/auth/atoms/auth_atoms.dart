// atoms
import 'package:asp/asp.dart';
import 'package:mfa/src/constants.dart';

import '../dtos/dtos.dart';
import '../states/states.dart';

// atoms
final authState = Atom<AuthState>(
  const AuthInitial(),
  key: 'authState',
);

final authLoadingState = Atom<bool>(
  false,
  key: 'authLoadingState',
);

// actions
final authConfirmCodeAction = Atom<String?>(
  null,
  key: 'authConfirmCodeAction',
  pipe: debounceTime(kOneSec),
);

final authFetchSessionAction = Atom.action(key: 'authFetchSessionAction');

final authRememberDeviceAction = Atom.action(key: 'authRememberDeviceAction');

final authSignInAction = Atom<SignInRequestDTO?>(
  null,
  key: 'authSignInAction',
);

final authSignOutAction = Atom<bool>(
  false,
  key: 'authSignOutAction',
);

// computed
bool get authLoading => authLoadingState.value;

bool get authDone => authState.value is AuthLogged;
