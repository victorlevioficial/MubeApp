part of 'create_gig_screen.dart';

extension _CreateGigScreenActions on _CreateGigScreenState {
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _gigDate ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    _updateState(() {
      _gigDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _scrollToDateField() async {
    final dateFieldContext = _dateFieldKey.currentContext;
    if (dateFieldContext == null) return;

    await Scrollable.ensureVisible(
      dateFieldContext,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: 0.15,
    );
  }

  Future<void> _submit(AppConfig config) async {
    FocusScope.of(context).unfocus();
    if (!_showValidationErrors) {
      _updateState(() => _showValidationErrors = true);
    }

    if (!_formKey.currentState!.validate()) {
      AppSnackBar.error(
        context,
        'Revise os campos obrigatorios para continuar.',
      );
      return;
    }
    if (_dateMode == GigDateMode.fixedDate && _gigDate == null) {
      await _scrollToDateField();
      if (!mounted) return;
      AppSnackBar.error(context, 'Selecione a data da gig.');
      return;
    }

    try {
      final currentUser = ref.read(currentUserProfileProvider).asData?.value;
      final locationPayload = _buildLocationPayload(currentUser);
      final geohash = _buildLocationGeohash(locationPayload);

      if (_isEditing) {
        final update = _canEditAllFields
            ? GigUpdate(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                gigType: _gigType,
                dateMode: _dateMode,
                gigDate: _gigDate,
                clearGigDate: _dateMode != GigDateMode.fixedDate,
                locationType: _locationType,
                location: locationPayload,
                geohash: geohash,
                clearLocation: locationPayload == null,
                genres: _selectedGenres,
                requiredInstruments: _selectedInstruments,
                requiredCrewRoles: _selectedRoles,
                requiredStudioServices: _selectedServices,
                slotsTotal: int.parse(_slotsController.text),
                compensationType: _compensationType,
                compensationValue: _compensationType == CompensationType.fixed
                    ? int.tryParse(_compensationValueController.text)
                    : null,
                clearCompensationValue:
                    _compensationType != CompensationType.fixed,
              )
            : GigUpdate(description: _descriptionController.text.trim());

        await ref
            .read(createGigControllerProvider.notifier)
            .updateDraft(widget.initialGig!.id, update);
        if (!mounted) return;
        AppSnackBar.success(context, 'Gig atualizada com sucesso.');
      } else {
        final draft = GigDraft(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          gigType: _gigType,
          dateMode: _dateMode,
          gigDate: _gigDate,
          locationType: _locationType,
          location: locationPayload,
          geohash: geohash,
          genres: _selectedGenres,
          requiredInstruments: _selectedInstruments,
          requiredCrewRoles: _selectedRoles,
          requiredStudioServices: _selectedServices,
          slotsTotal: int.parse(_slotsController.text),
          compensationType: _compensationType,
          compensationValue: _compensationType == CompensationType.fixed
              ? int.tryParse(_compensationValueController.text)
              : null,
        );
        final submission = await ref
            .read(createGigControllerProvider.notifier)
            .submitDraft(draft);
        if (!mounted) return;
        AppSnackBar.success(context, 'Gig publicada com sucesso.');
        context.go(RoutePaths.gigDetailById(submission.gigId));
        return;
      }

      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, resolveGigErrorMessage(error));
    }
  }

  Map<String, dynamic>? _buildLocationPayload(AppUser? currentUser) {
    final label = _locationController.text.trim();
    if (_locationType == GigLocationType.remote) {
      if (label.isEmpty) return null;
      return {'label': label};
    }

    final primaryAddress = currentUser == null
        ? null
        : SavedAddressBook.effectiveAddresses(currentUser).firstOrNull;

    final payload = <String, dynamic>{};
    if (label.isNotEmpty) {
      payload['label'] = label;
    } else if (primaryAddress != null &&
        primaryAddress.shortDisplay.isNotEmpty) {
      payload['label'] = primaryAddress.shortDisplay;
    }

    if (primaryAddress?.lat != null) payload['lat'] = primaryAddress!.lat;
    if (primaryAddress?.lng != null) payload['lng'] = primaryAddress!.lng;
    if (primaryAddress != null && primaryAddress.cidade.isNotEmpty) {
      payload['cidade'] = primaryAddress.cidade;
    }
    if (primaryAddress != null && primaryAddress.estado.isNotEmpty) {
      payload['estado'] = primaryAddress.estado;
    }

    return payload.isEmpty ? null : payload;
  }

  String? _buildLocationGeohash(Map<String, dynamic>? locationPayload) {
    if (_locationType != GigLocationType.onsite || locationPayload == null) {
      return null;
    }

    final lat = (locationPayload['lat'] as num?)?.toDouble();
    final lng = (locationPayload['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return GeohashHelper.encode(lat, lng, precision: 5);
  }
}
