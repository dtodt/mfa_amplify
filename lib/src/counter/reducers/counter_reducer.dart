import 'package:asp/asp.dart';

import '../atoms/atoms.dart';

class CounterReducer extends Reducer {
  CounterReducer() {
    on(() => [counterIncrementAction], _increment);
  }

  void _increment() {
    counterState.setValue(counter + 1);
  }
}
