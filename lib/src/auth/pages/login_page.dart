import 'package:asp/asp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mfa/src/auth/auth.dart';

const _kPassword = String.fromEnvironment(
  'LOGIN_PASSWORD',
);

const _kUsername = String.fromEnvironment(
  'LOGIN_USERNAME',
);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _autoValidate = AutovalidateMode.disabled;
  DateTime? _lastCodeExpiration;

  late RxDisposer _authDisposer;

  bool get _showCodeButton =>
      _lastCodeExpiration != null &&
      DateTime.now().isBefore(_lastCodeExpiration!);

  @override
  Widget build(BuildContext context) {
    context.select(() => [authLoadingState]);

    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final inversePrimary = colorScheme.inversePrimary;

    Widget? codeButton;
    VoidCallback? onTap;
    if (!authLoading) {
      onTap = _signIn;

      if (_showCodeButton) {
        codeButton = FloatingActionButton(
          onPressed: _mfaCheck,
          child: const Icon(Icons.pin_outlined),
        );
      }
    }

    return Scaffold(
      body: Form(
        autovalidateMode: _autoValidate,
        key: _formKey,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.person_outline),
                          labelText: 'Email *',
                        ),
                        validator: _validateField,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.lock_outline),
                          labelText: 'Password *',
                        ),
                        obscureText: true,
                        validator: _validateField,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: Navigator.of(context).pop,
                            child: const Text('Back'),
                          ),
                          const SizedBox(width: 16.0),
                          FilledButton.tonal(
                            onPressed: onTap,
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (authLoading)
              Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(
                  color: primary,
                  backgroundColor: inversePrimary,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: codeButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    _authDisposer();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _passwordController.text = _kPassword;
    _emailController.text = _kUsername;

    _authDisposer = rxObserver(() => authState.value, effect: _authState);
  }

  void _authState(AuthState? state) {
    if (!mounted || state == null) return;

    return switch (state) {
      AuthFailed state => _failed(state.failure),
      AuthLogged() => _logged(),
      AuthMfaCheck() => _mfaCheck(DateTime.now()),
      AuthMfaCheckFailed() => _mfaCheck(),
      (_) => null,
    };
  }

  void _failed(Exception failure) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$failure')),
    );

    setState(() {
      _lastCodeExpiration = null;
    });
  }

  void _logged() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged in successfully')),
    );

    Navigator.of(context).pop();
  }

  void _mfaCheck([DateTime? sentDate]) {
    if (sentDate != null) {
      setState(() {
        _lastCodeExpiration = sentDate.add(const Duration(minutes: 4));
      });
    }
    if (!_showCodeButton) return;

    showModalBottomSheet<void>(
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      isDismissible: false,
      builder: (BuildContext context) {
        final keyboardSize = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardSize),
          child: SizedBox(
            height: 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        autofocus: true,
                        controller: _codeController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.key_outlined),
                          labelText: 'Mfa confirm code *',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: _validateField,
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: Navigator.of(context).pop,
                            child: const Text('Back'),
                          ),
                          const SizedBox(width: 16.0),
                          FilledButton.tonal(
                            onPressed: () {
                              if (_codeController.text.length < 6) return;
                              authConfirmCodeAction
                                  .setValue(_codeController.text);
                              Navigator.of(context).pop();
                              _codeController.clear();
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _signIn() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      setState(() {
        _autoValidate = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    authSignInAction.setValue((
      password: _passwordController.text,
      username: _emailController.text,
    ));
  }

  String? _validateField(value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}
