import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/router.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('LoginScreen');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _email;
  String? _password;

  void _signIn() async {
    _logger.info('Attempting to sign in with email: $_email');
    if (!FormService.validateForm(_formKey, save: true)) return;

    try {
      await AuthProvider.of(
        context,
      ).signInWithEmailAndPassword(email: _email!, password: _password!);
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, message: 'Identifiant ou mot de passe incorrect');
    }

    _logger.fine('Sign in successful');
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Réinitialiser le mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Un lien de réinitialisation du mot de passe sera envoyé\n'
                  'à l\'adresse courriel.'),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.mail),
                  labelText: 'Courriel',
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                AuthProvider.of(context).resetPassword(emailController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Réinitialiser'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building LoginScreen');

    // Calling the provider jumps start the authentication process and ensures data arrival
    final schoolBoardsProvider = SchoolBoardsProvider.of(context, listen: true);
    EnterprisesProvider.of(context, listen: false);
    InternshipsProvider.of(context, listen: false);
    StudentsProvider.of(context, listen: false);
    TeachersProvider.of(context, listen: false);

    final authProvider = AuthProvider.of(context, listen: true);
    if (authProvider.isFullySignedIn) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => GoRouter.of(context).goNamed(Screens.home),
      );
    }

    return PopScope(
      child: ResponsiveService.scaffoldOf(
        context,
        appBar: AppBar(title: const Text('Stagess')),
        smallDrawer:
            authProvider.isAuthenticatorSignedIn ? const MainDrawer() : null,
        mediumDrawer: authProvider.isAuthenticatorSignedIn
            ? const MainDrawer(iconOnly: true, showTitle: false)
            : null,
        largeDrawer: authProvider.isAuthenticatorSignedIn
            ? const MainDrawer(showTitle: false)
            : null,
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: ResponsiveService.maxBodyWidth,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: authProvider.isAuthenticatorSignedIn
                      ? Center(
                          child: Text(
                            schoolBoardsProvider.hasProblemConnecting
                                ? 'Impossible de se connecter à la base de données, \n'
                                    'vérifiez votre connexion internet.'
                                : schoolBoardsProvider.connexionRefused
                                    ? 'Connexion refusée, \n'
                                        'veuillez contacter votre administrateur'
                                    : 'Connexion en cours...',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        )
                      : Column(
                          children: [
                            Text(
                              'Connectez-vous à votre compte avant de poursuivre.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              decoration: const InputDecoration(
                                icon: Icon(Icons.mail),
                                labelText: 'Courriel',
                              ),
                              validator: FormService.emailValidator,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (email) => _email = email,
                              onFieldSubmitted: (_) => _signIn(),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              decoration: const InputDecoration(
                                icon: Icon(Icons.lock),
                                labelText: 'Mot de passe',
                              ),
                              validator: FormService.passwordValidator,
                              keyboardType: TextInputType.visiblePassword,
                              obscureText: true,
                              enableSuggestions: false,
                              autocorrect: false,
                              onSaved: (password) => _password = password,
                              onFieldSubmitted: (_) => _signIn(),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _signIn,
                              child: const Text('Se connecter'),
                            ),
                            const SizedBox(height: 8),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  _showForgotPasswordDialog();
                                },
                                child: Text('Mot de passe oublié ?'),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
