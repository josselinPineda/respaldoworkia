import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/features/jobs/presentation/viewmodels/job_detail_viewmodel.dart';

/// BottomSheet para asignar clientes a un trabajo.
///
/// Este widget:
/// - Maneja su propio estado local de formulario (selecciones, fechas).
/// - Dispara [vm.saveAssignments] cuando el usuario confirma.
/// - No contiene lógica de cálculo de fechas cíclicas (eso está en el VM).
class AssignClientSheet extends StatefulWidget {
  const AssignClientSheet({super.key, this.existingAssignment});

  /// Si se proporciona, estamos en modo edición.
  final TrabajoAsignado? existingAssignment;

  @override
  State<AssignClientSheet> createState() => _AssignClientSheetState();
}

class _AssignClientSheetState extends State<AssignClientSheet> {
  List<Cliente> _selectedClients = [];
  List<String> _selectedTechIds = [];
  DateTime? _startDate;
  bool _isCyclic = false;
  String _frequency = 'mensual';
  final _priceController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeFromExisting();
  }

  void _initializeFromExisting() {
    final assignment = widget.existingAssignment;
    if (assignment != null) {
      _startDate = assignment.fechaInicio;
      _isCyclic = assignment.esCiclico;
      _frequency = assignment.frecuenciaCiclico ?? 'mensual';
      _priceController.text = assignment.precioFinal.toString();
      _selectedTechIds = List.from(assignment.tecnicosAsignados);

      // Intentar resolver el cliente existente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<JobDetailViewModel>();
        try {
          final client = vm.clientesVM.clientes.firstWhere(
            (c) => c.id == assignment.clienteId,
          );
          setState(() {
            _selectedClients = [client];
          });
        } catch (_) {}
      });
    } else {
      _startDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final vm = context.watch<JobDetailViewModel>();
    final isEditing = widget.existingAssignment != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _Header(title: t.manageAssignmentsTitle),
            const Divider(),

            // Formulario scrolleable
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selector de clientes
                    _buildClientSelector(context, vm, isEditing),
                    const SizedBox(height: 12),

                    // Selector de técnicos
                    _buildTechnicianSelector(context, vm),
                    const SizedBox(height: 12),

                    // Campo de precio
                    TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t.finalPriceLabel,
                        hintText: t.emptyForBasePriceHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Switch cíclico
                    
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.cyclicalJobLabel),
                      value: _isCyclic,
                      onChanged: (val) => setState(() => _isCyclic = val),
                    ),

                    // Frecuencia (si es cíclico)
                    if (_isCyclic) _buildFrequencyDropdown(context),
                    const SizedBox(height: 12),

                    // Selector de fecha
                    ElevatedButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        _startDate != null
                            ? '${t.startDateLabel} ${vm.formatDate(_startDate!)}'
                            : t.selectStartDateLabel,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            const Divider(),

            // Botones de acción
            _ActionButtons(
              isSaving: _isSaving,
              onCancel: () => Navigator.of(context).pop(),
              onSave: () => _save(context, vm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSelector(
    BuildContext context,
    JobDetailViewModel vm,
    bool isEditing,
  ) {
    final t = AppLocalizations.of(context)!;
    final availableClients = isEditing
        ? vm.clientesVM.clientes
        : vm.availableClientsForAssignment;

    if (isEditing) {
      // Modo edición: Selección simple
      return DropdownSearch<Cliente>(
        items: (String? filter, LoadProps? props) => availableClients,
        itemAsString: (Cliente c) => c.nombre,
        selectedItem: _selectedClients.isNotEmpty
            ? _selectedClients.first
            : null,
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(labelText: t.searchClientsLabel),
          ),
        ),
        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(labelText: t.clientsTab),
        ),
        compareFn: (item, selectedItem) => item.id == selectedItem.id,
        onChanged: (Cliente? data) {
          setState(() {
            _selectedClients = data != null ? [data] : [];
          });
        },
      );
    } else {
      // Modo creación: Multi selección
      return DropdownSearch<Cliente>.multiSelection(
        items: (String? filter, LoadProps? props) => availableClients,
        itemAsString: (Cliente c) => c.nombre,
        selectedItems: _selectedClients,
        popupProps: PopupPropsMultiSelection.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(labelText: t.searchClientsLabel),
          ),
        ),
        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(labelText: t.clientsTab),
        ),
        compareFn: (item, selectedItem) => item.id == selectedItem.id,
        onChanged: (List<Cliente> data) {
          setState(() {
            _selectedClients = data;
          });
        },
      );
    }
  }

  Widget _buildTechnicianSelector(BuildContext context, JobDetailViewModel vm) {
    final t = AppLocalizations.of(context)!;
    final technicians = vm.availableTechnicians;

    return DropdownSearch<Usuario>.multiSelection(
      items: (String? filter, LoadProps? props) => technicians,
      itemAsString: (Usuario u) => u.nombre,
      selectedItems: technicians
          .where((u) => _selectedTechIds.contains(u.id))
          .toList(),
      popupProps: PopupPropsMultiSelection.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(labelText: t.searchTechnicianLabel),
        ),
        emptyBuilder: (context, searchEntry) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text('No hay técnicos disponibles'),
          );
        },
      ),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: t.selectTechniciansLabel,
          hintText: technicians.isEmpty 
              ? 'No hay técnicos disponibles' 
              : null,
        ),
      ),
      compareFn: (item, selectedItem) => item.id == selectedItem.id,
      onChanged: (List<Usuario> data) {
        setState(() {
          _selectedTechIds = data.map((u) => u.id).toList();
        });
      },
    );
  }

  Widget _buildFrequencyDropdown(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return DropdownButtonFormField<String>(
      value: _frequency,
      decoration: InputDecoration(labelText: t.frequencyLabel),
      items: [
        DropdownMenuItem(value: 'mensual', child: Text(t.monthlyFrequency)),
        DropdownMenuItem(
          value: 'trimestral',
          child: Text(t.quarterlyFrequency),
        ),
        DropdownMenuItem(
          value: 'semestral',
          child: Text(t.semiannualFrequency),
        ),
        DropdownMenuItem(value: 'anual', child: Text(t.annualFrequency)),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() => _frequency = val);
        }
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
      ),
      dialogSize: const Size(325, 400),
      value: _startDate != null ? [_startDate] : [],
    );

    if (results != null && results.isNotEmpty) {
      setState(() {
        _startDate = results[0];
      });
    }
  }

  Future<void> _save(BuildContext context, JobDetailViewModel vm) async {
    final t = AppLocalizations.of(context)!;

    // Validaciones
    if (_selectedClients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.selectAtLeastOneClientError)));
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCyclic
                ? 'Seleccione una fecha de inicio'
                : 'Seleccione la fecha de trabajo',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Parsear precio manual
      double? manualPrice;
      final txt = _priceController.text.trim();
      if (txt.isNotEmpty) {
        manualPrice = double.tryParse(txt);
      }

      // Delegar la lógica de guardado al ViewModel
      final processedCount = await vm.saveAssignments(
        selectedClients: _selectedClients,
        selectedTechIds: _selectedTechIds,
        startDate: _startDate!,
        isCyclic: _isCyclic,
        frequency: _isCyclic ? _frequency : null,
        manualPrice: manualPrice,
        existingAssignment: widget.existingAssignment,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.assignmentsProcessedMessage(processedCount)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSaving ? null : onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(t.cancelButton),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(t.saveButton),
          ),
        ),
      ],
    );
  }
}
