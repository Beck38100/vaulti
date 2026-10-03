import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaulti/widgets/animations.dart';

import 'helpers.dart';

/// Simule le réglage Android « Supprimer les animations ».
Widget withReducedMotion(Widget child) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child,
      ),
    );

void main() {
  group('AppearIn', () {
    final opacityInside = find.descendant(of: find.byType(AppearIn), matching: find.byType(Opacity));

    testWidgets('fait apparaître son contenu en fondu', (tester) async {
      await tester.pumpWidget(wrap(const AppearIn(child: Text('contenu'))));

      expect(opacityInside, findsOneWidget);
    });

    testWidgets('affiche son contenu sans animation quand elles sont réduites', (tester) async {
      await tester.pumpWidget(wrap(withReducedMotion(const AppearIn(child: Text('contenu')))));

      expect(opacityInside, findsNothing);
      expect(find.text('contenu'), findsOneWidget);
    });
  });

  group('PressScale', () {
    Future<ValueChanged<bool>> pumpPressScale(WidgetTester tester, {required bool reduced}) async {
      late ValueChanged<bool> highlight;
      Widget card = PressScale(builder: (context, onHighlightChanged) {
        highlight = onHighlightChanged;
        return const SizedBox(width: 40, height: 40);
      });
      if (reduced) card = withReducedMotion(card);
      await tester.pumpWidget(wrap(card));
      return highlight;
    }

    testWidgets('rétrécit légèrement pendant l’appui', (tester) async {
      final highlight = await pumpPressScale(tester, reduced: false);

      highlight(true);
      await tester.pump();

      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.97);
    });

    testWidgets('ne bouge plus quand les animations sont réduites', (tester) async {
      final highlight = await pumpPressScale(tester, reduced: true);

      highlight(true);
      await tester.pump();

      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });
  });

  testWidgets('le changement de dossier est instantané quand les animations sont réduites', (tester) async {
    Widget switcher() => const DirectionalSwitcher(depth: 1, previousDepth: 0, child: Text('dossier'));

    await tester.pumpWidget(wrap(switcher()));
    expect(tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration, Motion.normal);

    await tester.pumpWidget(wrap(withReducedMotion(switcher())));
    expect(tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration, Duration.zero);
  });
}
