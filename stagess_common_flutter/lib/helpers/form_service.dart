import 'package:flutter/material.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

abstract class FormService {
  static bool validateForm(
    GlobalKey<FormState> formKey, {
    bool save = false,
    bool showSnackbarError = true,
  }) {
    if (formKey.currentContext == null || formKey.currentState == null) {
      return false;
    }

    ScaffoldMessenger.of(formKey.currentContext!).clearSnackBars();

    if (!formKey.currentState!.validate()) {
      if (showSnackbarError) {
        showSnackBar(
          formKey.currentContext!,
          message: 'Remplir tous les champs avec un *.',
        );
      }
      return false;
    }

    if (save) {
      formKey.currentState!.save();
    }

    return true;
  }

  static String? textNotEmptyValidator(String? text) {
    if (text!.isEmpty) {
      return 'Le champ ne peut pas être vide.';
    }
    return null;
  }

  static String? neqValidator(String? neq) {
    if (neq == null || neq == '') return 'Un NEQ doit être spécifié';
    if (neq.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(neq)) {
      return 'Le NEQ est composé de 10 chiffres.';
    }
    return null;
  }

  static String? phoneValidator(String? phone) {
    if (phone!.isEmpty) {
      return 'Un numéro de téléphone est obligatoire.';
    } else if (!PhoneNumber.isValid(phone)) {
      return 'Le numéro entré n\'est pas valide.';
    }
    return null;
  }

  static String? emailValidator(String? email) {
    if (email == null || email.isEmpty) {
      return 'Une adresse courriel est obligatoire.';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'L\'adresse courriel n\'est pas valide.';
    }
    return null;
  }

  static String? usernameValidator(String? username) {
    if (username == null || username.isEmpty) {
      return 'Un nom d\'utilisateur est requis.';
    }
    return null;
  }

  static String? passwordValidator(String? password) {
    if (password == null || password.isEmpty) {
      return 'Le champ ne peut pas être vide.';
    }
    return null;
  }

  static String? passwordConfirmationValidator(
    String? confirmPassword,
    String? password,
  ) {
    if (password == null || password.isEmpty) {
      return 'Le mot de passe ne peut pas être vide.';
    }

    if (confirmPassword != password) {
      return 'Les mots de passe ne sont pas identiques.';
    }
    return null;
  }
}
