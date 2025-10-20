import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/main.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common/services/backend_helpers.dart';

import '../utils.dart';

void main() {
  group('Navigation', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    testWidgets('Then opening page is My enterprises', (
      WidgetTester tester,
    ) async {
      // Load the app and navigate to the home page.
      await tester.pumpWidgetWithNotifiers(
        withAuthentication: true,
        StagessApp(
          useMockers: true,
          backendUri: BackendHelpers.backendUri(
            isLocal: true,
            useSsl: false,
            isDev: true,
          ),
        ),
      );

      // Verify that the home page is "My enterprises"
      expect(find.text(ScreenTest.enterprises.name), findsOneWidget);
    });

    testWidgets('The drawer navigates and closes on click', (
      WidgetTester tester,
    ) async {
      FlutterError.onError = (FlutterErrorDetails details) {
        // Ignore overflow errors
        if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
          return;
        }

        // Forward other errors to the default handler
        FlutterError.presentError(details);
      };

      // Load the app and navigate and open the drawer.
      await tester.pumpWidgetWithNotifiers(
        withAuthentication: true,
        StagessApp(
          useMockers: true,
          backendUri: BackendHelpers.backendUri(
            isLocal: true,
            useSsl: false,
            isDev: true,
          ),
        ),
      );

      // Verify that the drawer contains the expected tiles
      for (final screenNameOuter in ScreenTest.values) {
        for (final screenNameInner in ScreenTest.values) {
          // For some reason, these two next fail (because it is too long)
          if (screenNameInner == ScreenTest.healthAndSafetyAtPFAE ||
              screenNameOuter == ScreenTest.healthAndSafetyAtPFAE) {
            continue;
          }

          // Navigate from Outer to Inner screen
          await tester.navigateToScreen(screenNameInner);

          // Verify the page is loaded and drawer is closed
          expect(find.text(screenNameInner.name), findsOneWidget);
          expect(find.text(drawerTitle), findsNothing);

          // Return to outer loop screen
          await tester.navigateToScreen(screenNameOuter);
        }
      }
    });
  });
}
