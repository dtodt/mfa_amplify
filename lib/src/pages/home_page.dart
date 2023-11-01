import 'package:asp/asp.dart';
import 'package:flutter/material.dart';

import '../auth/auth.dart';
import '../counter/counter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    context.select(() => [counterState, authState, authLoadingState]);

    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final inversePrimary = colorScheme.inversePrimary;

    final textTheme = Theme.of(context).textTheme;
    final bodyLarge = textTheme.bodyLarge;
    final headlineSmall = textTheme.headlineSmall;

    var actionIcon = Icons.login;
    if (authDone) {
      actionIcon = Icons.logout;
    }
    VoidCallback? actionTap;
    if (!authLoading) {
      actionTap = _goToLogin;
      if (authDone) {
        actionTap = authSignOutAction.call;
      }
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: actionTap,
            icon: Icon(actionIcon),
          ),
        ],
        backgroundColor: inversePrimary,
        title: const Text('Counter'),
      ),
      body: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: RichText(
              text: TextSpan(children: [
                TextSpan(text: 'You have pushed the button ', style: bodyLarge),
                TextSpan(text: '$counter', style: headlineSmall),
                TextSpan(text: ' times', style: bodyLarge),
              ]),
            ),
          ),
          if (authLoading)
            Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                color: primary,
                backgroundColor: inversePrimary,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: counterIncrementAction,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _goToLogin() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const LoginPage(),
      ),
    );
  }
}
