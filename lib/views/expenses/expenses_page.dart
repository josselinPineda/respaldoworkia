import 'package:flutter/material.dart';
import 'package:workia/widgets/currency_text.dart';
import 'package:workia/utils/ui_utils.dart';

import 'package:workia/views/settings/user_settings_page.dart';
import 'package:workia/models/expenses_repository.dart';
import 'package:workia/models/material_expense.dart';
import 'package:workia/models/gasto.dart';
import 'package:workia/models/tipo_gasto.dart';
import 'package:provider/provider.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/views/problems/problems_page.dart';
import 'package:workia/views/expenses/expense_types_view.dart';

// Importar viewmodel de trabajos asignados para seleccionar una asignación al registrar gastos.
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
// Importar modelo de trabajo asignado para acceder a sus propiedades.
import 'package:workia/models/trabajo_asignado.dart';
// Importar viewmodel y modelo de clientes para seleccionar el cliente al registrar gastos.
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';

import 'package:workia/models/cliente.dart';
// Importar dropdown_search para búsqueda en los desplegables
import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/l10n/app_localizations.dart';

/// Model representing an expense record for display.
class Expense {
  final String id;
  final String name;
  final DateTime date;
  final double amount;
  final String description;
  final String createdBy;
  // Added audit fields to preserve data during edits
  final DateTime? createdAt;
  final String createdById;
  final String type;

  Expense({
    required this.id,
    required this.name,
    required this.date,
    required this.amount,
    this.description = '',
    this.createdBy = '',
    this.createdAt,
    this.createdById = '',
    this.type = '',
  });

  String get dateFormatted => '${date.day}/${date.month}/${date.year}';
}

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({
    super.key,
    required this.userName,
    required this.role,
    required this.userId,
    required this.empresaId,
  });
  final String userName;
  final String role;
  final String userId;
  final String empresaId;

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GastosViewModel>().cargarGastos(widget.empresaId);
      context.read<GastosViewModel>().cargarTipos(widget.empresaId);
      context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
        widget.empresaId,
      );
      context.read<ClientesViewModel>().cargarClientes(widget.empresaId);
      context.read<UsuariosViewModel>().cargarUsuarios(widget.empresaId);
    });
  }

  void _showExpenseDetails(Expense expense) {
    final gastosVM = context.read<GastosViewModel>();
    showWorkiaBottomSheet(
      context: context,
      builder: (context) {
        final t = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.expenseDetailsTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _detailRow(
                t.amountLabel,
                '',
                valueWidget: CurrencyText(
                  expense.amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 18,
                  ),
                ),
                isBold: true,
                color: Colors.red,
              ),
              const SizedBox(height: 8),
              _detailRow(t.dateLabel, expense.dateFormatted),
              const SizedBox(height: 8),
              _detailRow(t.expenseTypeLabel, expense.name),
              if (expense.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow(t.descriptionOptionalLabel, expense.description),
              ],
              const SizedBox(height: 8),
              _detailRow(t.reportedByLabel, expense.createdBy),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(t.closeButton),
                    ),
                  ),
                  if (widget.role != 'PERF_TEC' ||
                      expense.createdBy == widget.userName) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Show confirm delete dialog
                          showWorkiaBottomSheet(
                            context: context,
                            builder: (ctx2) => Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    t.confirmDeleteTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    t.confirmDeleteActivityMessage
                                        .replaceAll('actividad', 'gasto')
                                        .replaceAll('activity', 'expense'),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.pop(ctx2),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(t.cancelButton),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await gastosVM.eliminar(
                                                expense.id,
                                                widget.empresaId,
                                                widget
                                                    .userId, // Using userId for consistency with other modules
                                              );
                                              if (ctx2.mounted) {
                                                Navigator.pop(
                                                  ctx2,
                                                ); // Close confirm
                                                if (context.mounted) {
                                                  Navigator.pop(
                                                    context,
                                                  ); // Close details
                                                }
                                                ScaffoldMessenger.of(
                                                  ctx2,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      t.expenseDeleted,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (ctx2.mounted) {
                                                ScaffoldMessenger.of(
                                                  ctx2,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(t.deleteButton),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(t.deleteButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddExpenseDialog(expense);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(t.editButton),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    Widget? valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child:
              valueWidget ??
              Text(
                value,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                  fontSize: isBold ? 18 : 14,
                ),
              ),
        ),
      ],
    );
  }

  void _showAssignAmountDialog(int index) {
    final amountController = TextEditingController();
    showWorkiaBottomSheet(
      context: context,
      builder: (context) {
        final t = AppLocalizations.of(context)!;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.assignAmountTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: t.amountLabel),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: () {
                        final value = double.tryParse(
                          amountController.text.trim(),
                        );
                        if (value != null) {
                          ExpensesRepository.completeExpense(index, value);
                          final trabajosAsignadosVM = context
                              .read<TrabajosAsignadosViewModel>();
                          final List<TrabajoAsignado> asignaciones =
                              trabajosAsignadosVM.trabajos;
                          TrabajoAsignado? asig;
                          if (asignaciones.isNotEmpty) {
                            asig = asignaciones.first;
                          }
                          context.read<GastosViewModel>().agregar(
                            Gasto(
                              fechaGasto: DateTime.now(),
                              monto: value,
                              empresaId: asig?.empresaId ?? '',
                              trabajoAsignadoId: asig?.id ?? '',
                              trabajoId: asig?.trabajoId ?? '',
                              clienteId: asig?.clienteId ?? '',
                              idTipoGasto: 'TG001',
                              urlComprobante: '',
                              creadoPor: widget.userId,
                              actualizadoPor: widget.userId,
                            ),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t.assignExpenseSuccessMessage),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(t.assignButton),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _initials() {
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final gastosViewModel = context.watch<GastosViewModel>();
    final usuariosViewModel = context.watch<UsuariosViewModel>();
    final List<Expense> completed = [
      ...gastosViewModel.gastos.map((g) {
        final tipo = gastosViewModel.tipos.firstWhere(
          (t) => t.id == g.idTipoGasto,
          orElse: () => gastosViewModel.tipos.isNotEmpty
              ? gastosViewModel.tipos.first
              : TipoGasto(
                  id: g.idTipoGasto,
                  codigo: g.idTipoGasto,
                  nombre: g.idTipoGasto,
                  descripcion: '',
                ),
        );
        String createdByName = g.creadoPor;
        try {
          final user = usuariosViewModel.usuarios.firstWhere(
            (u) => u.id == g.creadoPor,
          );
          createdByName = user.nombre;
        } catch (_) {}
        return Expense(
          id: g.id,
          name: tipo.nombre,
          date: g.fechaGasto,
          amount: g.monto,
          description: g.descripcion,
          createdBy: createdByName,
          // Map audit fields
          createdAt: g.fechaCreacion,
          createdById: g.creadoPor,
          type: tipo.nombre,
        );
      }),
    ];
    final List<MaterialExpense> pending = ExpensesRepository.pending;
    final bool showPending =
        widget.role == 'PERF_FIN' || widget.role == 'PERF_ADMIN';
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.expensesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProblemsPage(
                    userName: widget.userName,
                    role: widget.role,
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserSettingsPage(
                    userName: widget.userName,
                    role: widget.role,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _initials(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final gastosVM = context.read<GastosViewModel>();
          final trabajosAsignadosVM = context
              .read<TrabajosAsignadosViewModel>();
          final clientesVM = context.read<ClientesViewModel>();
          final usuariosVM = context.read<UsuariosViewModel>();

          await Future.wait([
            gastosVM.cargarGastos(widget.empresaId),
            gastosVM.cargarTipos(widget.empresaId),
            trabajosAsignadosVM.cargarTrabajosAsignados(widget.empresaId),
            clientesVM.cargarClientes(widget.empresaId),
            usuariosVM.cargarUsuarios(widget.empresaId),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (showPending && pending.isNotEmpty) ...[
              Text(
                t.pendingExpensesTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < pending.length; i++) ...[
                _PendingExpenseItem(
                  expense: pending[i],
                  onAssign: () => _showAssignAmountDialog(i),
                ),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 16),
            ],
            Text(
              t.registeredExpensesTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final exp in completed) ...[
              _ExpenseItem(expense: exp, onTap: () => _showExpenseDetails(exp)),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddExpenseDialog([Expense? existingExpense]) {
    final descriptionController = TextEditingController(
      text: existingExpense?.description ?? '',
    );
    final amountController = TextEditingController(
      text: existingExpense != null ? existingExpense.amount.toString() : '',
    );
    DateTime? date = existingExpense?.date;
    final gastosViewModel = context.read<GastosViewModel>();

    // Determine type ID
    String selectedTypeId = '';
    if (existingExpense != null) {
      try {
        final tipo = gastosViewModel.tipos.firstWhere(
          (t) => t.nombre == existingExpense.type,
        );
        selectedTypeId = tipo.id;
      } catch (_) {}
    }
    if (selectedTypeId.isEmpty && gastosViewModel.tipos.isNotEmpty) {
      selectedTypeId = gastosViewModel.tipos.first.id;
    }

    final trabajosAsignadosVM = context.read<TrabajosAsignadosViewModel>();
    final List<TrabajoAsignado> asignaciones = trabajosAsignadosVM.trabajos
        .where((a) => a.activo)
        .toList();
    final clientesVM = context.read<ClientesViewModel>();
    final List<Cliente> clientes = clientesVM.clientes
        .where((c) => c.activo)
        .toList();

    // Determine client and assignment based on existing expense if possible
    // Note: The Expense model used here is a display model and doesn't explicitly store IDs for client/assignment.
    // In a real scenario you would map the view model Gasto object directly or store IDs in Expense.
    // For now, we will default to 'unselected' or try to match if we had IDs.
    // Since Expense class here is a simple view model, we might not have the IDs to pre-fill client/assignment correctly without fetching the original Gasto.
    // *Simplification*: We'll assume for edit we might just let user re-select or we'd need to fetch the full Gasto.
    // Given the context of `_showExpenseDetails` only having `Expense`, we'll proceed with what we have.
    // If we want to fully support Editing with pre-filled Client/Assignment, we should probably pass the full `Gasto` object or update `Expense` to hold those IDs.

    String? selectedClienteId = clientes.isNotEmpty ? clientes.first.id : null;
    // Attempt to match if we can (e.g. if we had the ID), otherwise default.

    List<TrabajoAsignado> asignacionesCliente = [];
    String? selectedAsignadoId;
    if (selectedClienteId != null) {
      asignacionesCliente = asignaciones
          .where((a) => a.clienteId == selectedClienteId)
          .toList();
      if (asignacionesCliente.isNotEmpty) {
        selectedAsignadoId = asignacionesCliente.first.id;
      }
    }

    // If editing, we might need to look up the real Gasto to get IDs if Expense doesn't have them.
    // The current Expense class (lines 25-45) only keeps strings.
    // To properly edit, we really should rely on the Gasto object or pass IDs.
    // Let's modify the Expense class to optionally hold the Gasto ID and other IDs if we can, OR
    // we can lookup the Gasto from the ViewModel using the ID we clearly have in Expense.id.

    Gasto? originalGasto;
    if (existingExpense != null && existingExpense.id.isNotEmpty) {
      try {
        originalGasto = gastosViewModel.gastos.firstWhere(
          (g) => g.id == existingExpense.id,
        );
      } catch (_) {
        // Fallback: If not found in current list (e.g. filter), use data from existingExpense
        // This prevents overwriting audit fields
      }

      // Setup initial values
      if (originalGasto != null) {
        selectedTypeId = originalGasto.idTipoGasto;
        selectedClienteId = originalGasto.clienteId.isNotEmpty
            ? originalGasto.clienteId
            : selectedClienteId;
        // Refresh assignments for this client
        if (selectedClienteId != null) {
          asignacionesCliente = asignaciones
              .where((a) => a.clienteId == selectedClienteId)
              .toList();
        }
        selectedAsignadoId = originalGasto.trabajoAsignadoId.isNotEmpty
            ? originalGasto.trabajoAsignadoId
            : (asignacionesCliente.isNotEmpty
                  ? asignacionesCliente.first.id
                  : null);

        date = originalGasto.fechaGasto;
      }
    }

    showWorkiaBottomSheet(
      context: context,
      builder: (context) {
        final t = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingExpense != null
                              ? t.expenseDetailsTitle
                              : t.newExpenseTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (clientes.isNotEmpty)
                              DropdownSearch<Cliente>(
                                items: (String? filter, LoadProps? props) =>
                                    clientes,
                                itemAsString: (Cliente c) => c.nombre,
                                selectedItem: clientes.firstWhere(
                                  (c) => c.id == selectedClienteId,
                                  orElse: () => clientes.isNotEmpty
                                      ? clientes.first
                                      : Cliente(
                                          nombre: '',
                                          razonSocial: '',
                                          personaContacto: '',
                                          telefono: '',
                                          correo: '',
                                          direccion: '',
                                        ),
                                ),
                                compareFn: (Cliente? a, Cliente? b) =>
                                    (a == null || b == null)
                                    ? false
                                    : a.id == b.id,
                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: t.clientLabel,
                                  ),
                                ),
                                onChanged: (Cliente? selected) {
                                  if (selected == null) return;
                                  setStateModal(() {
                                    selectedClienteId = selected.id;
                                    asignacionesCliente = asignaciones
                                        .where(
                                          (a) =>
                                              a.clienteId == selectedClienteId,
                                        )
                                        .toList();
                                    selectedAsignadoId =
                                        asignacionesCliente.isNotEmpty
                                        ? asignacionesCliente.first.id
                                        : null;
                                  });
                                },
                              ),
                            if (clientes.isNotEmpty) const SizedBox(height: 12),
                            if (asignacionesCliente.isNotEmpty)
                              DropdownSearch<TrabajoAsignado>(
                                items: (String? filter, LoadProps? props) =>
                                    asignacionesCliente,
                                itemAsString: (TrabajoAsignado t) =>
                                    t.tituloTrabajo.isNotEmpty
                                    ? t.tituloTrabajo
                                    : t.trabajoId,
                                selectedItem: asignacionesCliente.firstWhere(
                                  (a) => a.id == selectedAsignadoId,
                                  orElse: () => asignacionesCliente.first,
                                ),
                                compareFn:
                                    (TrabajoAsignado? a, TrabajoAsignado? b) =>
                                        (a == null || b == null)
                                        ? false
                                        : a.id == b.id,
                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: t.assignmentLabel,
                                  ),
                                ),
                                onChanged: (TrabajoAsignado? selected) {
                                  setStateModal(() {
                                    selectedAsignadoId = selected?.id;
                                  });
                                },
                              ),
                            if (asignacionesCliente.isNotEmpty)
                              const SizedBox(height: 12),
                            DropdownSearch<TipoGasto>(
                              items: (String? filter, LoadProps? loadProps) => gastosViewModel.tipos,
                              itemAsString: (TipoGasto t) => t.nombre,
                              selectedItem: gastosViewModel.tipos.any((e) => e.id == selectedTypeId)
                                  ? gastosViewModel.tipos.firstWhere((e) => e.id == selectedTypeId)
                                  : null,
                              popupProps: const PopupProps.menu(
                                showSearchBox: true,
                              ),
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: t.expenseTypeLabel,
                                ),
                              ),
                              compareFn: (item, selectedItem) => item.id == selectedItem.id,
                              onChanged: (TipoGasto? selected) {
                                if (selected != null) {
                                  setStateModal(() => selectedTypeId = selected.id);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: descriptionController,
                              decoration: InputDecoration(
                                labelText: t.descriptionOptionalLabel,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: date ?? DateTime.now(),
                                  firstDate: DateTime(DateTime.now().year - 1),
                                  lastDate: DateTime(DateTime.now().year + 2),
                                );
                                if (picked != null) {
                                  setStateModal(() => date = picked);
                                }
                              },
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: t.dateLabel,
                                    suffixIcon: const Icon(
                                      Icons.calendar_today,
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: date == null
                                        ? ''
                                        : '${date!.day}/${date!.month}/${date!.year}',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: t.amountLabel,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
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
                            onPressed: () {
                              final amountText = amountController.text.trim();
                              final amount = double.tryParse(amountText);
                              if (date != null &&
                                  amount != null &&
                                  selectedTypeId.isNotEmpty) {
                                TrabajoAsignado? asig;
                                if (selectedAsignadoId != null) {
                                  try {
                                    asig = asignaciones.firstWhere(
                                      (a) => a.id == selectedAsignadoId,
                                    );
                                  } catch (_) {
                                    asig = null;
                                  }
                                }
                                Cliente? cli;
                                if (selectedClienteId != null) {
                                  try {
                                    cli = clientes.firstWhere(
                                      (c) => c.id == selectedClienteId,
                                    );
                                  } catch (_) {
                                    cli = null;
                                  }
                                }

                                final gastoToSave = Gasto(
                                  id:
                                      existingExpense?.id ??
                                      '', // Use existing ID if edit
                                  fechaGasto: date!,
                                  monto: amount,
                                  empresaId:
                                      asig?.empresaId ??
                                      cli?.empresaId ??
                                      widget.empresaId,
                                  trabajoAsignadoId: asig?.id ?? '',
                                  trabajoId: asig?.trabajoId ?? '',
                                  clienteId: cli?.id ?? '',
                                  idTipoGasto: selectedTypeId,
                                  urlComprobante: '',
                                  descripcion: descriptionController.text,
                                  // AUDIT FIX: Use original creator if editing, otherwise current user
                                  creadoPor: existingExpense != null
                                      ? (originalGasto?.creadoPor ??
                                            (existingExpense
                                                    .createdById
                                                    .isNotEmpty
                                                ? existingExpense.createdById
                                                : widget.userId))
                                      : widget.userId,
                                  actualizadoPor: widget.userId,
                                  // AUDIT FIX: Use original creation date if editing, otherwise now
                                  fechaCreacion: existingExpense != null
                                      ? (originalGasto?.fechaCreacion ??
                                            existingExpense.createdAt ??
                                            DateTime.now())
                                      : DateTime.now(),
                                  fechaActualizacion: DateTime.now(),
                                  activo: true,
                                );

                                if (existingExpense != null) {
                                  context.read<GastosViewModel>().actualizar(
                                    gastoToSave,
                                  );
                                } else {
                                  context.read<GastosViewModel>().agregar(
                                    gastoToSave,
                                  );
                                }

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      existingExpense != null
                                          ? t.dataSavedMessage
                                          : t.expenseAddedSuccessMessage,
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(t.saveButton),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTypeSelectionBottomSheet(
    BuildContext context,
    GastosViewModel viewModel,
    Function(String) onSelected,
  ) {
    final t = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  t.expenseTypeLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, _) {
                    final tipos = viewModel.tipos;
                    if (tipos.isEmpty) {
                      return Center(child: Text(t.noJobsFilterMessage));
                    }
                    return ListView.separated(
                      itemCount: tipos.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tipo = tipos[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tipo.nombre),
                          onTap: () {
                            onSelected(tipo.id);
                            Navigator.pop(ctx);
                          },
                          trailing: const Icon(Icons.chevron_right, size: 18),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  const _ExpenseItem({required this.expense, required this.onTap});

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(
          expense.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(expense.dateFormatted),
        trailing: CurrencyText(
          expense.amount,
          prefix: '- ',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// List item representing a pending material expense.  Displays the
/// type and description, with a button to assign the amount.  Used
/// by finance/admin roles to complete expenses.
class _PendingExpenseItem extends StatelessWidget {
  const _PendingExpenseItem({required this.expense, required this.onAssign});
  final MaterialExpense expense;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12), // Added margin for spacing
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${expense.type}: ${expense.description}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onAssign,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                AppLocalizations.of(context)!.assignAmountButtonLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
