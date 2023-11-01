// atoms
import 'package:asp/asp.dart';

// atoms
final counterState = Atom<int>(0, key: 'counterState');

// actions
final counterIncrementAction = Atom.action(
  key: 'counterIncrementAction',
);

// computed
int get counter => counterState.value;
