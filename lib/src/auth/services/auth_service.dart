import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mfa/src/auth/config/config.dart';
import 'package:result_dart/result_dart.dart';

import '../dtos/auth_dtos.dart';

//
abstract class AuthService {
  AsyncResult<bool, Exception> confirmSignIn(String confirmation);

  AsyncResult<FetchResponseDTO, Exception> fetchSession();

  AsyncResult<Unit, Exception> forgetDevices();

  AsyncResult<Unit, Exception> rememberDevice();

  AsyncResult<SignInResponseDTO, Exception> signIn(SignInRequestDTO dto);

  AsyncResult<Unit, Exception> signOut([bool allDevices]);

  AsyncResult<Unit, Exception> updateMfa([bool enable]);
}

//
class CognitoAuthService implements AuthService {
  final AmplifyClass _amplify;

  CognitoAuthService(this._amplify) {
    try {
      _amplify.addPlugin(AmplifyAuthCognito()).then((_) => _amplify
          .configure(AuthConfigHelper.getConfigurationString())
          .then((_) => debugPrint('Auth configured!')));
    } catch (error, stack) {
      debugPrint('Auth config failed!');
      debugPrintStack(label: 'CognitoAuthService', stackTrace: stack);
    }
  }

  AmplifyAuthCognito get _cognito =>
      _amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);

  @override
  AsyncResult<bool, Exception> confirmSignIn(String confirmation) async {
    try {
      final result = await _cognito.confirmSignIn(
        confirmationValue: confirmation,
      );
      return result.isSignedIn.toSuccess();
    } on AuthNotAuthorizedException catch (e) {
      return e.toFailure();
    } on CodeMismatchException catch (e) {
      return e.toFailure();
    } catch (e) {
      return _unexpectedError(e).toFailure();
    }
  }

  @override
  AsyncResult<FetchResponseDTO, Exception> fetchSession() async {
    try {
      final session = await _cognito.fetchAuthSession();
      final accessToken =
          session.userPoolTokensResult.value.accessToken.toJson();
      final mfaEnabled = await _isMfaEnabled();
      return Success((accessToken: accessToken, mfaEnabled: mfaEnabled));
    } catch (e) {
      return _unexpectedError(e).toFailure();
    }
  }

  @override
  AsyncResult<Unit, Exception> forgetDevices() async {
    try {
      final devices = await _cognito.fetchDevices();
      for (final device in devices) {
        await _cognito.forgetDevice(device);
      }
      return unit.toSuccess();
    } catch (e) {
      return _unexpectedError(e).toFailure();
    }
  }

  @override
  AsyncResult<Unit, Exception> rememberDevice() async {
    try {
      await _cognito.rememberDevice();
      return unit.toSuccess();
    } catch (e) {
      return _unexpectedError(e).toFailure();
    }
  }

  @override
  AsyncResult<SignInResponseDTO, Exception> signIn(SignInRequestDTO dto) async {
    try {
      final result = await _cognito.signIn(
        options: const SignInOptions(
          pluginOptions: CognitoSignInPluginOptions(
            authFlowType: AuthenticationFlowType.userSrpAuth,
          ),
        ),
        password: dto.password,
        username: dto.username,
      );
      //? when mfa active and device not remembered, isSignedIn is false
      if (!result.isSignedIn) {
        return _handleSignInChallenges(result);
      }
      final mfaEnabled = await _isMfaEnabled();
      return Success((mfaEnabled: mfaEnabled, signedIn: result.isSignedIn));
    } on ResourceNotFoundException catch (e) {
      return e.toFailure();
    } catch (e) {
      return _unexpectedError(e).toFailure();
    }
  }

  @override
  AsyncResult<Unit, Exception> signOut([bool allDevices = false]) async {
    try {
      await _cognito.signOut(
        options: SignOutOptions(globalSignOut: allDevices),
      );
      return unit.toSuccess();
    } catch (e) {
      return _unexpectedError(e).toFailure();
    }
  }

  @override
  AsyncResult<Unit, Exception> updateMfa([bool enable = false]) async {
    try {
      var state = MfaPreference.disabled;
      if (enable) {
        state = MfaPreference.enabled;
      }
      await _cognito.updateMfaPreference(
        sms: state,
      );
      return unit.toSuccess();
    } catch (e) {
      return _unexpectedError(e).toFailure();
    }
  }

  Failure<SignInResponseDTO, AuthException> _handleSignInChallenges(
    CognitoSignInResult result,
  ) {
    final nextStep = result.nextStep.signInStep;
    if (AuthSignInStep.confirmSignInWithSmsMfaCode == nextStep) {
      final destination =
          result.nextStep.codeDeliveryDetails?.destination ?? '';
      var messageDirections = '';
      if (destination.isNotEmpty) {
        messageDirections = ' with number $destination';
      }
      return AuthNotAuthorizedException(
        'Confirm your device$messageDirections.',
      ).toFailure();
    }
    return MfaMethodNotFoundException(
      'The `${nextStep.name} is not supported.`',
    ).toFailure();
  }

  Future<bool> _isMfaEnabled() async {
    final preference = await _cognito.fetchMfaPreference();
    final prefered = preference.preferred ?? MfaType.sms;
    return preference.enabled.contains(prefered);
  }

  Exception _unexpectedError(Object e) =>
      Exception('Unexpected error: ${e.runtimeType}');
}
