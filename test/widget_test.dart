import 'package:flutter_test/flutter_test.dart';
import 'package:quizbuilder_pro/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuizBuilderProApp());

    // Let the splash screen timer complete and the login screen build.
    await tester.pump(const Duration(seconds: 3));

    // Verify the app title is rendered on the login screen.
    expect(find.text('QuizBuilder Pro'), findsOneWidget);
  });
}
