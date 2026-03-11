import 'package:crcrme_material_theme/crcrme_material_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stagess/common/widgets/selectable_text_boxes.dart';

// coverage:ignore-start
void main() async {
  runApp(StagessApp());
}
// coverage:ignore-end

class StagessApp extends StatelessWidget {
  const StagessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => 'Stagess',
      theme: crcrmeMaterialTheme,
      home: MainPage(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'CA')],
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SelectableTextBoxesController(options: {});
    return Scaffold(
      appBar: AppBar(title: const Text('Stagess - Main Page')),
      body: SingleChildScrollView(
          child: Column(
        children: [
          SelectableTextBoxes(controller: controller),
          ElevatedButton(
              onPressed: () {
                for (final option in controller.options) {
                  debugPrint('Option ${option.key}: ${option.value}');
                }
              },
              child: const Text('Submit'))
        ],
      )),
    );
  }
}

// import 'dart:math';

// import 'package:aad_oauth/aad_oauth.dart';
// import 'package:aad_oauth/model/config.dart';
// import 'package:flutter/material.dart';

// void main() async {
//   final navigatorKey = GlobalKey<NavigatorState>();

//   runApp(MaterialApp(
//     navigatorKey: navigatorKey,
//     home: Scaffold(
//       body: MicrosoftLoginWeb(navigatorKey: navigatorKey),
//     ),
//   ));
// }

// class MicrosoftLoginWeb extends StatefulWidget {
//   const MicrosoftLoginWeb({super.key, required this.navigatorKey});

//   final GlobalKey<NavigatorState> navigatorKey;
//   static const String tenant = 'd9e685e2-1e5c-4bb8-bbae-e8ab8ba845a9';
//   static const String clientId = 'dd26538f-ec32-49d9-8625-ebe2bf1ef53a';
//   static const String redirectUri = 'http://localhost:3457/auth';
//   static const String scope = 'openid profile'; //'email offline_access';
//   static const String responseType = 'code';
//   static const String responseMode = 'post_form';

//   @override
//   State<MicrosoftLoginWeb> createState() => _MicrosoftLoginWebState();
// }

// class _MicrosoftLoginWebState extends State<MicrosoftLoginWeb> {
//   final state = Random().nextInt(1000000).toString();
//   late final oauth = AadOAuth(Config(
//     tenant: MicrosoftLoginWeb.tenant,
//     clientId: MicrosoftLoginWeb.clientId,
//     scope: MicrosoftLoginWeb.scope,
//     redirectUri: MicrosoftLoginWeb.redirectUri,
//     webUseRedirect: true,
//     navigatorKey: widget.navigatorKey,
//     state: state,
//     responseMode: 'form_post',
//     loginHint: 'benjamin.michaud@partenaire.cssda.ca',
//   ));

//   Future<String?> _login() async {
//     final result = await oauth.login();
//     return result.fold(
//       (l) {
//         debugPrint('Login Failed: $l');
//         return null;
//       },
//       (r) {
//         debugPrint('Login Successful: $r');
//         return r.accessToken;
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: _login,
//       child: const Text('Login with Microsoft'),
//     );
//   }
// }
