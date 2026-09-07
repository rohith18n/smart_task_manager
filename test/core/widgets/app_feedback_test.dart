import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_manager/core/widgets/app_feedback.dart';

void main() {
  Widget createTestWidget(void Function(BuildContext) trigger) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () => trigger(context),
                child: const Text('Show Feedback'),
              ),
            );
          },
        ),
      ),
    );
  }

  group('AppFeedback Tests', () {
    testWidgets('AppFeedback.showSuccess renders title and message',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget((context) {
          AppFeedback.showSuccess(
            context,
            title: 'Task Created',
            message: 'Your task has been scheduled.',
          );
        }),
      );

      await tester.tap(find.text('Show Feedback'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Task Created'), findsOneWidget);
      expect(find.text('Your task has been scheduled.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('AppFeedback.showError renders title, message and action',
        (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        createTestWidget((context) {
          AppFeedback.showError(
            context,
            title: 'Sign In Failed',
            message: 'Invalid email or password.',
            actionLabel: 'Retry',
            onAction: () {
              actionTriggered = true;
            },
          );
        }),
      );

      await tester.tap(find.text('Show Feedback'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sign In Failed'), findsOneWidget);
      expect(find.text('Invalid email or password.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'), warnIfMissed: false);
      await tester.pump();

      expect(actionTriggered, isTrue);
    });

    testWidgets('AppFeedback.showWarning renders correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget((context) {
          AppFeedback.showWarning(
            context,
            title: 'Offline Warning',
            message: 'You are currently disconnected.',
          );
        }),
      );

      await tester.tap(find.text('Show Feedback'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Offline Warning'), findsOneWidget);
      expect(find.text('You are currently disconnected.'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('AppFeedback.showInfo renders and can be hidden',
        (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        createTestWidget((context) {
          testContext = context;
          AppFeedback.showInfo(
            context,
            title: 'Copied',
            message: 'ID copied to clipboard.',
          );
        }),
      );

      await tester.tap(find.text('Show Feedback'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Copied'), findsOneWidget);
      expect(find.text('ID copied to clipboard.'), findsOneWidget);

      AppFeedback.hide(testContext);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Copied'), findsNothing);
    });

    testWidgets('AppFeedback.showSync renders cloud sync message',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget((context) {
          AppFeedback.showSync(
            context,
            title: 'Sync in Progress',
            message: 'Syncing tasks with cloud...',
          );
        }),
      );

      await tester.tap(find.text('Show Feedback'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sync in Progress'), findsOneWidget);
      expect(find.text('Syncing tasks with cloud...'), findsOneWidget);
      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    });
  });
}
