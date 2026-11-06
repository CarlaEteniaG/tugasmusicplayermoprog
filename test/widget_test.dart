
import 'package:flutter_test/flutter_test.dart';

import 'package:tugasmusicplayer/main.dart';

void main() {
  testWidgets('Music Player smoke test', (WidgetTester tester) async {
    // Build aplikasi Music Player
    await tester.pumpWidget(
      MyApp(
        username: '',
        isDarkMode: false,
        onSave: (String name) async {},
        onThemeChanged: (bool value) async {},
      ),
    );

    // Memeriksa apakah widget MyApp berhasil dibuat
    expect(find.byType(MyApp), findsOneWidget);
  });
}