import 'package:flutter/material.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common_flutter/widgets/show_address_dialog.dart';

class AddressController {
  Function()? onAddressChangedCallback;
  AddressController({
    this.onAddressChangedCallback,
    Address? initialValue,
    this.fromStringOverrideForDebug,
    this.confirmAddressForDebug,
  }) {
    this.initialValue = initialValue;
  }

  Future<Address?> Function(String)? fromStringOverrideForDebug;
  bool Function(Address?)? confirmAddressForDebug;

  Future<String?> Function()? _validationFunction;
  bool Function()? _isValidating;
  Address? Function()? _getAddress;
  Address? Function(Address)? _setAddress;
  bool Function()? _isMandatory;
  Address? _initialValue;
  set initialValue(Address? value) {
    _initialValue = value;
    _textController.text = value?.toString() ?? '';
  }

  final TextEditingController _textController = TextEditingController();

  // Interface to expose to the user
  Address? get address => _getAddress == null ? null : _getAddress!();
  set address(Address? value) {
    if (value != null && _setAddress != null) _setAddress!(value);

    _textController.text = address?.toString() ?? '';
    requestValidation();
  }

  Future<String?> requestValidation() async {
    final message =
        _validationFunction == null ? null : await _validationFunction!();
    return message;
  }

  Future<void> waitForValidation() async {
    if (_isValidating == null) return;
    while (_isValidating!()) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  bool get isValid {
    if (_isValidating == null) return false;

    final address = _getAddress!();
    if (address?.isNotEmpty ?? false) {
      // If the address is filled, then it is valid if it is valid
      return address!.isValid;
    } else {
      // If the address is empty, then it is valid if it is not mandatory
      return !_isMandatory!();
    }
  }

  void dispose() {
    _textController.dispose();
  }
}

class AddressListTile extends StatefulWidget {
  const AddressListTile({
    super.key,
    this.title,
    this.titleStyle,
    this.contentStyle,
    required this.addressController,
    required this.isMandatory,
    required this.enabled,
  });

  final String? title;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final bool enabled;
  final bool isMandatory;
  final AddressController addressController;

  @override
  State<AddressListTile> createState() => _AddressListTileState();
}

class _AddressListTileState extends State<AddressListTile> {
  bool _isValidating = false;
  String? _previousValidatedAddress;
  String? _previousValidatedMessage;
  late bool addressHasChanged;

  @override
  void initState() {
    super.initState();

    widget.addressController._validationFunction = validate;
    widget.addressController._isValidating = () => _isValidating;
    widget.addressController._getAddress = getAddress;
    widget.addressController._setAddress = setAddress;
    widget.addressController._isMandatory = () => widget.isMandatory;
    _address = widget.addressController._initialValue;

    if (_address == null) {
      // Add the search icon if address is empty
      addressHasChanged = true;
    } else {
      addressHasChanged = false;
    }
  }

  Address? _address;
  Address? getAddress() => _address;
  Address? setAddress(newAddress) => _address = newAddress;

  Future<String?> validate({bool forceShowIfNotFound = false}) async {
    while (_isValidating) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (_previousValidatedAddress ==
        widget.addressController._textController.text) {
      return _previousValidatedMessage;
    }
    if (!addressHasChanged) return _previousValidatedMessage;

    _address = null;
    _previousValidatedAddress = widget.addressController._textController.text;
    if (widget.addressController._textController.text == '') {
      _previousValidatedMessage =
          widget.isMandatory ? 'Entrer une adresse valide' : null;
      return _previousValidatedMessage;
    }

    setState(() => _isValidating = true);
    late Address? newAddress;
    try {
      final toCall =
          widget.addressController.fromStringOverrideForDebug ??
          Address.fromString;
      newAddress =
          (await toCall(widget.addressController._textController.text))!;
    } catch (e) {
      newAddress = null;
    }
    if (newAddress == null || newAddress.isNotValid) {
      setState(() => _isValidating = false);
      _previousValidatedMessage = 'L\'adresse n\'a pu être trouvée';
      if (!forceShowIfNotFound) return _previousValidatedMessage;
    }

    if (newAddress.toString() == _address.toString()) {
      // Don't do anything if the address did not change
      _address = newAddress;
      widget.addressController._textController.text = _address.toString();
      addressHasChanged = false;
      setState(() => _isValidating = false);
      _previousValidatedMessage = null;
      return _previousValidatedMessage;
    }

    if (!mounted) {
      // coverage:ignore-start
      setState(() => _isValidating = false);
      _previousValidatedMessage = 'Erreur inconnue';
      return _previousValidatedMessage;
      // coverage:ignore-end
    }

    // coverage:ignore-start
    final confirmAddress =
        widget.addressController.confirmAddressForDebug == null
            ? await showDialog<bool>(
              barrierDismissible: false,
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Confirmer l\'adresse'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'L\'adresse trouvée est\u00a0:\n${newAddress!.isValid ? newAddress.toString() : 'Aucune'}',
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 1 / 2,
                            width: MediaQuery.of(context).size.width * 2 / 3,
                            child: ShowAddressDialog(newAddress),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Confirmer'),
                      ),
                    ],
                  ),
            )
            : widget.addressController.confirmAddressForDebug!(newAddress);
    // coverage:ignore-end

    if (confirmAddress == null || !confirmAddress) {
      _address = null;
      setState(() => _isValidating = false);
      _previousValidatedMessage = 'Essayer une nouvelle adresse';
      return _previousValidatedMessage;
    }

    _address = newAddress;

    widget.addressController._textController.text = _address.toString();
    if (widget.addressController.onAddressChangedCallback != null) {
      widget.addressController.onAddressChangedCallback!();
    }

    setState(() => _isValidating = false);
    addressHasChanged = false;
    _previousValidatedMessage = null;
    if (mounted) setState(() {});

    return _previousValidatedMessage;
  }

  // coverage:ignore-start
  void _showAddress(context) async {
    if (_address == null) return;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(widget.title ?? 'Adresse'),
            content: SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 1 / 2,
                width: MediaQuery.of(context).size.width * 2 / 3,
                child: ShowAddressDialog(_address!),
              ),
            ),
          ),
    );
  }
  // coverage:ignore-end

  bool _isValid() {
    if (widget.addressController._textController.text == '') {
      return !widget.isMandatory;
    }

    return _address != null;
  }

  @override
  Widget build(BuildContext context) {
    final searchIsClickable =
        addressHasChanged &&
        widget.addressController._textController.text.isNotEmpty &&
        !_isValidating;

    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) validate(forceShowIfNotFound: true);
      },
      child: InkWell(
        onTap: widget.enabled ? null : () => _showAddress(context),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: IconButton(
                onPressed: () => _showAddress(context),
                icon: Icon(Icons.map, color: Theme.of(context).primaryColor),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: widget.addressController._textController,
                decoration: InputDecoration(
                  labelText:
                      '${widget.isMandatory && widget.enabled ? '* ' : ''}${widget.title ?? 'Adresse'}',
                  labelStyle:
                      widget.titleStyle ??
                      (widget.enabled ? null : TextStyle(color: Colors.black)),
                  disabledBorder: InputBorder.none,
                ),
                style:
                    widget.contentStyle ??
                    (widget.enabled ? null : TextStyle(color: Colors.black)),
                enabled: widget.enabled && !_isValidating,
                maxLines: null,
                onSaved: (newAddress) => validate(),
                validator:
                    (_) => _isValid() ? null : 'Entrer une adresse valide.',
                keyboardType: TextInputType.streetAddress,
                onChanged:
                    (value) => setState(() {
                      addressHasChanged = true;
                    }),
              ),
            ),
            if (widget.enabled)
              InkWell(
                onTap:
                    searchIsClickable
                        ? () => validate(forceShowIfNotFound: true)
                        : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: Icon(
                    Icons.search,
                    color:
                        searchIsClickable
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
