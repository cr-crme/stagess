import 'package:crcrme_material_theme/crcrme_material_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/common/widgets/disponibility_circle.dart';
import 'package:stagess/common/widgets/numbered_tablet.dart';
import 'package:stagess/screens/enterprises_list/widgets/enterprise_card.dart';
import 'package:stagess_common/models/generic/address.dart';

import '../../../common_tests/utils.dart';
import '../../../utils.dart';

void main() {
  group('EnterpriseCard', () {
    testWidgets('Company name is written as title', (tester) async {
      final enterprise =
          dummyEnterprise()
            ..copyWith(address: Address(civicNumber: 100, street: 'No where'));
      await tester.pumpWidgetWithNotifiers(
        withAuthentication: true,
        dummyEnterprise: enterprise,
        addOverlay(EnterpriseCard(enterprise: enterprise, onTap: (_) {})),
      );

      final title = find.text(enterprise.name);
      expect(title, findsOneWidget);

      final titleWidget = tester.firstWidget(title) as Text;
      expectStyle(
        of: titleWidget,
        comparedTo: crcrmeMaterialTheme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.bold,
        ),
        skipFontSize: true,
      );
    });
  });

  group('Disponibility circle', () {
    testWidgets('Disponibility circle has tooltip', (tester) async {
      await tester.pumpWidget(
        addOverlay(
          const DisponibilityCircle(positionsOccupied: 1, positionsOffered: 3),
        ),
      );

      final tooltip = find.byTooltip(
        'Nombre de places disponibles pour ce métier',
      );
      expect(tooltip, findsOneWidget);
    });

    testWidgets('Disponibility circle is green when there are places', (
      tester,
    ) async {
      await tester.pumpWidget(
        addOverlay(
          const DisponibilityCircle(positionsOccupied: 1, positionsOffered: 3),
        ),
      );

      final tablet = find.byType(NumberedTablet);
      expect(tablet, findsOneWidget);
      expect(
        (tester.firstWidget(tablet) as NumberedTablet).color,
        Colors.green[800],
      );
    });

    testWidgets('Disponibility circle is red when there are no places', (
      tester,
    ) async {
      await tester.pumpWidget(
        addOverlay(
          const DisponibilityCircle(positionsOccupied: 3, positionsOffered: 3),
        ),
      );

      final tablet = find.byType(NumberedTablet);
      expect(tablet, findsOneWidget);
      expect(
        (tester.firstWidget(tablet) as NumberedTablet).color,
        Colors.red[800],
      );
    });

    testWidgets('Disponibility circle shows the right number', (tester) async {
      await tester.pumpWidget(
        addOverlay(
          const DisponibilityCircle(positionsOccupied: 1, positionsOffered: 3),
        ),
      );

      final tablet = find.byType(NumberedTablet);
      expect(tablet, findsOneWidget);
      expect((tester.firstWidget(tablet) as NumberedTablet).number, 2);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('Disponibility is shown if empty when should show', (
      tester,
    ) async {
      await tester.pumpWidget(
        addOverlay(const NumberedTablet(number: 0, hideIfEmpty: false)),
      );

      final tablet = find.byType(NumberedTablet);
      expect(tablet, findsOneWidget);
      expect((tester.firstWidget(tablet) as NumberedTablet).number, 0);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Disponibility is not shown if empty when should not show', (
      tester,
    ) async {
      await tester.pumpWidget(
        addOverlay(const NumberedTablet(number: 0, hideIfEmpty: true)),
      );

      final tablet = find.byType(NumberedTablet);
      expect(tablet, findsOneWidget);
      expect((tester.firstWidget(tablet) as NumberedTablet).number, 0);
      expect(find.text('0'), findsNothing);
    });
  });
}
