import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/screens/game_screen.dart';

/// Regression test for the sleep confirm modal: opens the REAL dialog and
/// fails if it paints anything that can read as a stray line — gold
/// accents, borders, dividers, progress bars, or underlined text.
void main() {
  testWidgets('sleep confirm has no lines of any kind', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showSleepConfirmDialog(ctx),
            child: const Text('open sleep'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open sleep'));
    await tester.pumpAndSettle();

    final painted = <String>{};
    void note(String where, Color? c) {
      if (c == null) return;
      painted.add(
        '$where: #${c.toARGB32().toRadixString(16).padLeft(8, '0')}',
      );
    }

    for (final c in tester.widgetList<Container>(find.byType(Container))) {
      final d = c.decoration;
      if (d is BoxDecoration) {
        note('container.bg', d.color);
        final b = d.border;
        if (b is Border) {
          for (final entry in {
            'top': b.top,
            'right': b.right,
            'bottom': b.bottom,
            'left': b.left,
          }.entries) {
            if (entry.value.style == BorderStyle.solid) {
              painted.add(
                'BORDER LINE (${entry.key}): '
                '#${entry.value.color.toARGB32().toRadixString(16).padLeft(8, '0')}',
              );
            }
          }
        }
      }
    }
    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      note('text(${t.data})', t.style?.color);
      final dec = t.style?.decoration;
      if (dec != null && dec != TextDecoration.none) {
        painted.add('UNDERLINED: "${t.data}" -> $dec');
      }
    }
    for (final i in tester.widgetList<Icon>(find.byType(Icon))) {
      note('icon(${i.icon})', i.color);
    }
    for (final b in tester.widgetList<FilledButton>(
      find.byType(FilledButton),
    )) {
      note('filledbutton.bg', b.style?.backgroundColor?.resolve({}));
      note('filledbutton.side', b.style?.side?.resolve({})?.color);
    }

    final lines = painted.toList()..sort();
    for (final line in lines) {
      // ignore: avoid_print
      print('AUDIT $line');
    }

    expect(find.byType(Divider), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    final bad = lines
        .where(
          (s) =>
              s.contains('ffd966') ||
              s.startsWith('BORDER LINE') ||
              s.startsWith('UNDERLINED'),
        )
        .toList();
    expect(bad, isEmpty, reason: 'stray lines present: $bad');
  });
}
