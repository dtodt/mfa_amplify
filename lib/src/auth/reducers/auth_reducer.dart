import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:asp/asp.dart';
import 'package:flutter/material.dart';

import '../atoms/atoms.dart';
import '../services/services.dart';
import '../states/states.dart';

class AuthReducer extends Reducer {
  final AuthService _service;

  AuthReducer(this._service) {
    // action reactions
    on(() => [authConfirmCodeAction], _confirmCode);
    on(() => [authFetchSessionAction], _fetchSession);
    on(() => [authRememberDeviceAction], _rememberDevice);
    on(() => [authSignInAction], _signIn);
    on(() => [authSignOutAction], _signOut);
  }

  void _confirmCode() {
    final action = authConfirmCodeAction.value;
    if (action == null) return;
    debugPrint('confirmCode');

    authLoadingState.setValue(true);
    _service.confirmSignIn(action).then((boolOrException) {
      authState.setValue(boolOrException.fold(
        (success) {
          authRememberDeviceAction();
          return const AuthMfaProcessing();
        },
        (failure) {
          authLoadingState.setValue(false);
          if (failure is CodeMismatchException) {
            return const AuthMfaCheckFailed();
          }
          return AuthFailed(failure);
        },
      ));
    });
  }

  void _fetchSession() {
    debugPrint('fetchSession');
    authLoadingState.setValue(true);
    _service.fetchSession().then((dtoOrException) {
      authLoadingState.setValue(false);
      authState.setValue(dtoOrException.fold(
        (success) => AuthLogged(success.mfaEnabled),
        (_) => const AuthUnlogged(),
      ));
    });
  }

  Future<void> _rememberDevice() async {
    debugPrint('rememberDevice');

    debugPrint('forgeting devices');
    // this method only produces a failure on the second device.
    final forgetResult = await _service.forgetDevices();
    debugPrint('forget succeed: ${forgetResult.isSuccess()}');

    debugPrint('remembering device');
    // this method only fails after forgeting the first device.
    final rememberResult = await _service.rememberDevice();
    debugPrint('remember succeed: ${rememberResult.isSuccess()}');

    authLoadingState.setValue(false);
    authState.setValue(const AuthLogged(true));
  }

  void _signIn() {
    final action = authSignInAction.value;
    if (action == null) return;
    debugPrint('signIn');

    authLoadingState.setValue(true);
    _service.signIn(action).then((dtoOrException) {
      authLoadingState.setValue(false);
      authState.setValue(dtoOrException.fold(
        (success) => AuthLogged(success.mfaEnabled),
        (failure) {
          if (failure is AuthNotAuthorizedException) {
            return const AuthMfaCheck();
          }
          return AuthFailed(failure);
        },
      ));
    });
  }

  void _signOut() {
    final action = authSignOutAction.value;
    debugPrint('signOut');

    authLoadingState.setValue(true);
    _service.signOut(action).then((_) {
      authLoadingState.setValue(false);
      authState.setValue(const AuthUnlogged());
    });
  }
}
