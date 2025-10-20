import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common_flutter/widgets/address_list_tile.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/enterprise_activity_type_list_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';

final _logger = Logger('InformationsPage');

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => AboutPageState();
}

class AboutPageState extends State<AboutPage> {
  final _formKey = GlobalKey<FormState>();

  String? name;
  final addressController = AddressController();
  final phoneController = TextEditingController();

  String? contactFirstName;
  String? contactLastName;
  String? contactFunction;
  final contactPhoneController = TextEditingController();
  String get contactPhone => contactPhoneController.text;
  final contactEmailController = TextEditingController();
  String get contactEmail => contactEmailController.text;
  String? neq;

  final _activityTypesController = EnterpriseActivityTypeListController(
    initial: {},
  );
  EnterpriseActivityTypeListController get activityTypesController =>
      _activityTypesController;

  Future<String?> validate() async {
    _logger.finer('Validating InformationsPage with name: $name');

    await addressController.requestValidation();

    if (!_formKey.currentState!.validate()) {
      return 'Remplir tous les champs avec un *.';
    }

    _formKey.currentState!.save();

    return null;
  }

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    contactPhoneController.dispose();
    contactEmailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building AboutPage of with name: $name');

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: FocusScope(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SubTitle(
                'Coordonnées de l\'établissement',
                left: 0,
                top: 0,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '* Nom de l\'entreprise',
                ),
                validator:
                    (text) =>
                        text!.isEmpty
                            ? 'Ajouter le nom de l\'entreprise.'
                            : null,
                onChanged: (name) => this.name = name,
              ),
              AddressListTile(
                title: 'Adresse',
                isMandatory: true,
                enabled: true,
                addressController: addressController,
              ),
              SizedBox(height: 8),
              PhoneListTile(
                title: 'Téléphone de l\'établissement',
                controller: phoneController,
                isMandatory: true,
                enabled: true,
              ),
              SizedBox(height: 16),
              const SubTitle('Entreprise représentée par', left: 0, top: 0),
              TextFormField(
                decoration: const InputDecoration(labelText: '* Prénom'),
                validator:
                    (text) =>
                        text!.isEmpty
                            ? 'Ajouter le nom de la personne représentant l\'entreprise.'
                            : null,
                onChanged: (name) => contactFirstName = name,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '* Nom de famille',
                ),
                validator:
                    (text) =>
                        text!.isEmpty
                            ? 'Ajouter le nom de la personne représentant l\'entreprise.'
                            : null,
                onChanged: (name) => contactLastName = name,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '* Fonction'),
                validator:
                    (text) =>
                        text!.isEmpty
                            ? 'Ajouter la fonction de cette personne.'
                            : null,
                onChanged: (function) => contactFunction = function,
              ),
              PhoneListTile(
                controller: contactPhoneController,
                isMandatory: true,
                canCall: false,
                enabled: true,
              ),
              EmailListTile(
                controller: contactEmailController,
                isMandatory: true,
                enabled: true,
                canMail: false,
              ),
              const SizedBox(height: 16),
              const SubTitle(
                'Type d\'activités de l\'entreprise',
                left: 0,
                top: 0,
              ),
              EnterpriseActivityTypeListTile(
                hideTitle: true,
                subtitle:
                    '* Sélectionner les mots clefs illustrant les activités de l’entreprise',
                controller: _activityTypesController,
                editMode: true,
                activityTabAtTop: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
