// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:bonfire/base/listener_game_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kennie/app.dart';
import 'package:kennie/game/rpg_game.dart';

void main() {
  testWidgets('boots the game shell', (WidgetTester tester) async {
    await tester.pumpWidget(const KennieApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.byType(ListenerGameWidget<RpgGame>), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
  });
}
