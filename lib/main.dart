import 'dart:async';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:asp/asp.dart';
import 'package:auto_injector/auto_injector.dart';
import 'package:flutter/material.dart';
import 'package:mfa/src/src.dart';

final injector = AutoInjector();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  injector.addInstance<AmplifyClass>(Amplify);
  injector.addSingleton<AuthService>(CognitoAuthService.new);
  injector.addSingleton<AuthReducer>(AuthReducer.new);
  injector.addSingleton<CounterReducer>(CounterReducer.new);
  injector.commit();

  runApp(const RxRoot(child: MfaApp()));
}

class MfaApp extends StatefulWidget {
  const MfaApp({super.key});

  @override
  State<MfaApp> createState() => _MfaAppState();
}

class _MfaAppState extends State<MfaApp> {
  @override
  Widget build(BuildContext context) {
    context.select(() => [authState]);

    var seed = Colors.amber;
    if (authDone) {
      seed = Colors.lightGreen;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MFA Amplitude',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }

  @override
  void initState() {
    super.initState();

    scheduleMicrotask(
      () => Future.delayed(const Duration(seconds: 5)).then(
        (_) => authFetchSessionAction(),
      ),
    );
  }
}
