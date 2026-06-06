import 'package:ai_diary_social_platform/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the app home tabs directly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: AiDiarySocialApp()));

    expect(find.text('피드'), findsOneWidget);
    expect(find.text('캐릭터'), findsOneWidget);
    expect(find.text('일기'), findsOneWidget);
  });
}
