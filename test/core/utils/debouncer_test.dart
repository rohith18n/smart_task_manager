import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_manager/core/utils/debouncer.dart';

void main() {
  test('Debouncer only executes the last callback after delay', () async {
    final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
    int executionCount = 0;
    String lastValue = '';

    debouncer.run(() {
      executionCount++;
      lastValue = 'first';
    });

    debouncer.run(() {
      executionCount++;
      lastValue = 'second';
    });

    debouncer.run(() {
      executionCount++;
      lastValue = 'third';
    });

    expect(executionCount, equals(0));

    await Future.delayed(const Duration(milliseconds: 80));

    expect(executionCount, equals(1));
    expect(lastValue, equals('third'));
  });

  test('Debouncer cancel prevents execution', () async {
    final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
    bool executed = false;

    debouncer.run(() {
      executed = true;
    });

    debouncer.cancel();
    await Future.delayed(const Duration(milliseconds: 80));

    expect(executed, isFalse);
  });
}
