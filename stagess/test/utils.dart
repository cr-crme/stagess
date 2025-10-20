import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

///
/// Overlay are required for widgets such as Tootip
Widget addOverlay(Widget child) {
  return MaterialApp(
    builder:
        (context, ch) => Overlay(
          initialEntries: [OverlayEntry(builder: (context) => child)],
        ),
  );
}

extension StageSsWidgetTester on WidgetTester {
  Future<void> loadDummyData() async {
    // Find the reinitalize data button in the drawer
    await openDrawer();
    await tap(find.text(reinitializedDataButtonText));
    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  BuildContext context(Finder finder) => element(finder);

  T ancestorByType<T extends Widget>({required Finder of}) {
    final parent = find.ancestor(of: of, matching: find.byType(T));
    return parent.evaluate().first.widget as T;
  }

  T ancestorBySubtype<T extends Widget>({required Finder of}) {
    final parent = find.ancestor(of: of, matching: find.bySubtype<T>());
    return parent.evaluate().first.widget as T;
  }

  Future<void> openDrawer() async {
    final drawerIcon = find.byIcon(Icons.menu);
    await tap(drawerIcon);
    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  Future<void> closeDrawer() async {
    Navigator.pop(context(find.byType(Drawer)));
    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  Future<void> navigateToScreen(ScreenTest target) async {
    // This function assumes drawer menu is shown
    await openDrawer();
    final targetButton = find.ancestor(
      of: find.text(target.name),
      matching: find.byType(Card),
    );
    await tap(targetButton);

    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  Future<BuildContext> contextWithNotifiers({
    bool withAuthentication = false,
    bool withSchools = false,
    bool withTeachers = false,
    bool withStudents = false,
    bool withEnterprises = false,
    bool withInternships = false,
    bool withItineraries = false,
  }) async {
    final container = Container();
    await pumpWidgetWithNotifiers(
      container,
      withAuthentication: withAuthentication,
      withSchools: withSchools,
      withTeachers: withTeachers,
      withStudents: withStudents,
      withEnterprises: withEnterprises,
      withInternships: withInternships,
      withItineraries: withItineraries,
    );
    return context(find.byWidget(container));
  }

  Future<void> pumpWidgetWithNotifiers(
    Widget child, {
    bool withAuthentication = false,
    bool withSchools = false,
    bool withTeachers = false,
    bool withStudents = false,
    bool withEnterprises = false,
    bool withInternships = false,
    bool withItineraries = false,
    Enterprise? dummyEnterprise,
    Internship? dummyInternship,
  }) async {
    if (!withAuthentication &&
        !withSchools &&
        !withTeachers &&
        !withStudents &&
        !withEnterprises &&
        !withInternships &&
        !withItineraries) {
      throw Exception('At least one provider must be required');
    }

    await pumpWidget(
      MaterialApp(
        builder:
            (ctx, ch) => MultiProvider(
              providers: [
                if (withAuthentication)
                  ChangeNotifierProvider(
                    create: (context) => AuthProvider(mockMe: true),
                  ),
                if (withSchools)
                  ChangeNotifierProvider(
                    create:
                        (context) => SchoolBoardsProvider(
                          uri: Uri.parse('ws://localhost'),
                          mockMe: true,
                        ),
                  ),
                if (withEnterprises)
                  ChangeNotifierProvider(
                    create: (context) {
                      final enterprises = EnterprisesProvider(
                        uri: Uri.parse('ws://localhost'),
                        mockMe: true,
                      );
                      if (dummyEnterprise != null) {
                        enterprises.add(dummyEnterprise);
                      }
                      return enterprises;
                    },
                  ),
                if (withInternships)
                  ChangeNotifierProvider(
                    create: (context) {
                      final internships = InternshipsProvider(
                        uri: Uri.parse('ws://localhost'),
                        mockMe: true,
                      );
                      if (dummyInternship != null) {
                        internships.add(dummyInternship);
                      }
                      return internships;
                    },
                  ),
                if (withTeachers && withAuthentication)
                  ChangeNotifierProxyProvider<AuthProvider, TeachersProvider>(
                    create:
                        (context) => TeachersProvider(
                          uri: Uri.parse('ws://localhost'),
                          mockMe: true,
                        ),
                    update:
                        (context, auth, previous) =>
                            previous!..initializeAuth(auth),
                  ),
                if (withTeachers && !withAuthentication)
                  ChangeNotifierProvider<TeachersProvider>(
                    create:
                        (context) => TeachersProvider(
                          uri: Uri.parse('ws://localhost'),
                          mockMe: true,
                        ),
                  ),
                if (withStudents && withAuthentication)
                  ChangeNotifierProxyProvider<AuthProvider, StudentsProvider>(
                    create:
                        (context) => StudentsProvider(
                          uri: Uri.parse('ws://localhost'),
                          mockMe: true,
                        ),
                    update:
                        (context, auth, previous) =>
                            previous!..initializeAuth(auth),
                  ),
                if (withStudents && !withAuthentication)
                  ChangeNotifierProvider<StudentsProvider>(
                    create:
                        (context) => StudentsProvider(
                          uri: Uri.parse('ws://localhost'),
                          mockMe: true,
                        ),
                  ),
              ],
              child: child,
            ),
      ),
    );

    final buildContext = context(find.byWidget(child));
    if (withAuthentication) {
      final authProvided = AuthProvider.of(buildContext, listen: false);
      authProvided.schoolBoardId = 'MockedSchoolBoardId';
      authProvided.schoolId = 'MockedSchoolId';
      authProvided.teacherId = 'MockedTeacherId';

      if (withSchools) {
        SchoolBoardsProvider.of(
          buildContext,
          listen: false,
        ).initializeAuth(AuthProvider.of(buildContext, listen: false));
      }
      if (withTeachers) {
        TeachersProvider.of(
          buildContext,
          listen: false,
        ).initializeAuth(AuthProvider.of(buildContext, listen: false));
      }
      if (withStudents) {
        StudentsProvider.of(
          buildContext,
          listen: false,
        ).initializeAuth(AuthProvider.of(buildContext, listen: false));
      }
      if (withEnterprises) {
        EnterprisesProvider.of(
          buildContext,
          listen: false,
        ).initializeAuth(AuthProvider.of(buildContext, listen: false));
      }
      if (withInternships) {
        InternshipsProvider.of(
          buildContext,
          listen: false,
        ).initializeAuth(AuthProvider.of(buildContext, listen: false));
      }
    }
  }
}

// Add the providers to the widget tree

void expectStyle({
  required Text of,
  required TextStyle comparedTo,
  bool skipColor = false,
  bool skipFontWeight = false,
  bool skipFontSize = false,
}) {
  if (!skipColor) expect(of.style!.color, comparedTo.color);
  if (!skipFontWeight) expect(of.style!.fontWeight, comparedTo.fontWeight);
  if (!skipFontSize) expect(of.style!.fontSize, comparedTo.fontSize);
}

const drawerTitle = 'Stagess';
const reinitializedDataButtonText = 'Réinitialiser la base de données';

enum ScreenTest {
  myStudents,
  supervisionTable,
  tasks,
  enterprises,
  healthAndSafetyAtPFAE;

  String get name {
    switch (this) {
      case ScreenTest.myStudents:
        return 'Mes élèves';
      case ScreenTest.supervisionTable:
        return 'Tableau des supervisions';
      case ScreenTest.tasks:
        return 'Tâches à réaliser';
      case ScreenTest.enterprises:
        return 'Entreprises';
      case ScreenTest.healthAndSafetyAtPFAE:
        return 'Santé et Sécurité au PFAE';
    }
  }
}

enum StudentTest {
  cedricMasson,
  thomasCaron,
  mikaelBoucher,
  kevinLeblanc,
  diegoVargas,
  jeanneTremblay,
  vincentPicard,
  vanessaMonette,
  melissaPoulain;

  String get name {
    switch (this) {
      case StudentTest.cedricMasson:
        return 'Cedric Masson';
      case StudentTest.thomasCaron:
        return 'Thomas Caron';
      case StudentTest.mikaelBoucher:
        return 'Mikael Boucher';
      case StudentTest.kevinLeblanc:
        return 'Kevin Leblanc';
      case StudentTest.diegoVargas:
        return 'Diego Vargas';
      case StudentTest.jeanneTremblay:
        return 'Jeanne Tremblay';
      case StudentTest.vincentPicard:
        return 'Vincent Picard';
      case StudentTest.vanessaMonette:
        return 'Vanessa Monette';
      case StudentTest.melissaPoulain:
        return 'Melissa Poulain';
    }
  }

  static int get length => StudentTest.values.length;
}

enum EnterpriseTest {
  metroGagnon,
  jeanCoutu,
  autoCare,
  autoRepair,
  boucherieMarien,
  iga,
  pharmaprix,
  subway,
  walmart,
  leJardinDeJoanie,
  fleuristeJoli;

  String get name {
    switch (this) {
      case EnterpriseTest.metroGagnon:
        return 'Metro Gagnon';
      case EnterpriseTest.jeanCoutu:
        return 'Jean Coutu';
      case EnterpriseTest.autoCare:
        return 'Auto Care';
      case EnterpriseTest.autoRepair:
        return 'Auto Repair';
      case EnterpriseTest.boucherieMarien:
        return 'Boucherie Marien';
      case EnterpriseTest.iga:
        return 'IGA';
      case EnterpriseTest.pharmaprix:
        return 'Pharmaprix';
      case EnterpriseTest.subway:
        return 'Subway';
      case EnterpriseTest.walmart:
        return 'Walmart';
      case EnterpriseTest.leJardinDeJoanie:
        return 'Le jardin de Joanie';
      case EnterpriseTest.fleuristeJoli:
        return 'Fleuriste Joli';
    }
  }

  static int get length => EnterpriseTest.values.length;
}

enum InternshipsTest {
  thomasCaronBoucherieMarien,
  cedaricMassonAutoCare,
  vincentPicardIga,
  diegoVargasMetroGagnon;

  String get studentName {
    switch (this) {
      case InternshipsTest.thomasCaronBoucherieMarien:
        return StudentTest.thomasCaron.name;
      case InternshipsTest.cedaricMassonAutoCare:
        return StudentTest.cedricMasson.name;
      case InternshipsTest.vincentPicardIga:
        return StudentTest.vincentPicard.name;
      case InternshipsTest.diegoVargasMetroGagnon:
        return StudentTest.diegoVargas.name;
    }
  }

  String get enterpriseName {
    switch (this) {
      case InternshipsTest.thomasCaronBoucherieMarien:
        return EnterpriseTest.boucherieMarien.name;
      case InternshipsTest.cedaricMassonAutoCare:
        return EnterpriseTest.autoCare.name;
      case InternshipsTest.vincentPicardIga:
        return EnterpriseTest.iga.name;
      case InternshipsTest.diegoVargasMetroGagnon:
        return EnterpriseTest.metroGagnon.name;
    }
  }

  static int get length => InternshipsTest.values.length;
}

enum TasksSstTest {
  boucherieMarien,
  iga,
  metroGagnon;

  String get name {
    switch (this) {
      case TasksSstTest.boucherieMarien:
        return EnterpriseTest.boucherieMarien.name;
      case TasksSstTest.iga:
        return EnterpriseTest.iga.name;
      case TasksSstTest.metroGagnon:
        return EnterpriseTest.metroGagnon.name;
    }
  }

  static int get length => TasksSstTest.values.length;
}

enum TaskEndInternshipTest {
  thomasCaronBoucherieMarien;

  String get name {
    switch (this) {
      case TaskEndInternshipTest.thomasCaronBoucherieMarien:
        return StudentTest.thomasCaron.name;
    }
  }

  String get enterpriseName {
    switch (this) {
      case TaskEndInternshipTest.thomasCaronBoucherieMarien:
        return EnterpriseTest.boucherieMarien.name;
    }
  }

  static int get length => TaskEndInternshipTest.values.length;
}

enum TaskPostEvaluationTest {
  vanessaMonettePharmaprix,
  vanessaMonetteJeanCoutu;

  String get studentName {
    switch (this) {
      case TaskPostEvaluationTest.vanessaMonettePharmaprix:
        return StudentTest.vanessaMonette.name;
      case TaskPostEvaluationTest.vanessaMonetteJeanCoutu:
        return StudentTest.vanessaMonette.name;
    }
  }

  String get enterpriseName {
    switch (this) {
      case TaskPostEvaluationTest.vanessaMonettePharmaprix:
        return EnterpriseTest.pharmaprix.name;
      case TaskPostEvaluationTest.vanessaMonetteJeanCoutu:
        return EnterpriseTest.jeanCoutu.name;
    }
  }

  static int get length => TaskPostEvaluationTest.values.length;
}

enum TasksTest {
  sst,
  endInternship,
  postEvaluation;

  String get name {
    switch (this) {
      case TasksTest.sst:
        return 'Repérer les risques SST';
      case TasksTest.endInternship:
        return 'Terminer les stages';
      case TasksTest.postEvaluation:
        return 'Faire les évaluations post-stage';
    }
  }

  static int get length =>
      TasksSstTest.length +
      TaskEndInternshipTest.length +
      TaskPostEvaluationTest.length;
}
