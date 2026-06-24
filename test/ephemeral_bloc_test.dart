import 'package:flutter_test/flutter_test.dart';

import 'package:ephemeral_bloc/ephemeral_bloc.dart';

void main() {
  test('adds one to input values', () {
    final calculator = Calculator();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
  });
}
