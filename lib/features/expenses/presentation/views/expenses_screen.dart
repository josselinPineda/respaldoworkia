import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/widgets/currency_text.dart';
import 'package:workia/models/gasto.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/models/tipo_gasto.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/features/expenses/presentation/viewmodels/expenses_viewmodel.dart';
import 'package:workia/features/problems/presentation/views/problems_screen.dart';
import 'package:workia/features/settings/presentation/views/user_settings_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ExpensesViewModel(
        gastosVM: ctx.read<GastosViewModel>(),
        usuariosVM: ctx.read<UsuariosViewModel>(),
        trabajosAsignadosVM: ctx.read<TrabajosAsignadosViewModel>(),
        clientesVM: ctx.read<ClientesViewModel>(),
        empresaId: empresaId,
        currentUserId: userId,
      )..loadData(),
      child: _ExpensesScreenContent(
        userName: userName,
        role: role,
        userId: userId,
      ),
    );
  }
}

class _ExpensesScreenContent extends StatefulWidget {
  const _ExpensesScreenContent({
    required this.userName,
    required this.role,
    required this.userId,
  });

  final String userName;
  final String role;
  final String userId;

  @override
  State<_ExpensesScreenContent> createState() => _ExpensesScreenContentState();
}

class _ExpensesScreenContentState extends State<_ExpensesScreenContent> {
  String _initials() {
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  void _showAddExpenseDialog(
    BuildContext context, [
    ExpenseUIModel? existingExpense,
  ]) {
    final vm = context.read<ExpensesViewModel>();
    final t = AppLocalizations.of(context)!;

    // Controllers
    final descriptionController = TextEditingController(
      text: existingExpense?.description ?? '',
    );
    final amountController = TextEditingController(
      text: existingExpense != null ? existingExpense.amount.toString() : '',
    );

    // State for dropdowns
    String? selectedTypeId;
    String? selectedClienteId;
    String? selectedAsignadoId;

    // Pre-fill logic (simplified)
    if (existingExpense != null) {
      // Intentar buscar el Gasto original para obtener IDs reales si fuera necesario
      // Por ahora, asumimos edición simple o creación nueva
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          final tipos = vm.gastosVM.tipos;
          final clientes = vm.clientesVM.clientes
              .where((c) => c.activo)
              .toList();
          final trabajos = vm.trabajosAsignadosVM.trabajos
              .where((t) => t.activo)
              .toList();

          // Inicialización por defecto en el primer build del modal
          if (selectedTypeId == null && tipos.isNotEmpty) {
            selectedTypeId = tipos.first.id;
          }
          if (selectedClienteId == null && clientes.isNotEmpty) {
            selectedClienteId = clientes.first.id;
          }

          List<TrabajoAsignado> asignacionesCliente = [];
          if (selectedClienteId != null) {
            asignacionesCliente = trabajos
                .where((t) => t.clienteId == selectedClienteId)
                .toList();
            if (selectedAsignadoId == null && asignacionesCliente.isNotEmpty) {
              selectedAsignadoId = asignacionesCliente.first.id;
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existingExpense != null
                        ? t.expenseDetailsTitle
                        : t.newExpenseTitle,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tipo de Gasto
                  DropdownSearch<TipoGasto>(
                    items: (String? filter, LoadProps? loadProps) => vm.gastosVM.tipos,
                    itemAsString: (TipoGasto t) => t.nombre,
                    selectedItem: vm.gastosVM.tipos.any((e) => e.id == selectedTypeId)
                        ? vm.gastosVM.tipos.firstWhere((e) => e.id == selectedTypeId)
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

                  // Cliente
                  DropdownSearch<Cliente>(
                    items: (f, p) => clientes,
                    itemAsString: (c) => c.nombre,
                    selectedItem: clientes.any((c) => c.id == selectedClienteId)
                        ? clientes.firstWhere((c) => c.id == selectedClienteId)
                        : null,
                    compareFn: (a, b) => a.id == b.id,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: t.clientLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      fit: FlexFit.loose,
                    ),
                    onChanged: (c) {
                      setStateModal(() {
                        selectedClienteId = c?.id;
                        selectedAsignadoId =
                            null; // Reset assignment on client change
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Asignación
                  if (asignacionesCliente.isNotEmpty)
                    DropdownSearch<TrabajoAsignado>(
                      items: (f, p) => asignacionesCliente,
                      itemAsString: (t) => t.tituloTrabajo.isNotEmpty
                          ? t.tituloTrabajo
                          : t.trabajoId,
                      selectedItem:
                          asignacionesCliente.any(
                            (t) => t.id == selectedAsignadoId,
                          )
                          ? asignacionesCliente.firstWhere(
                              (t) => t.id == selectedAsignadoId,
                            )
                          : null,
                      compareFn: (a, b) => a.id == b.id,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: t.assignmentLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        fit: FlexFit.loose,
                      ),
                      onChanged: (t) =>
                          setStateModal(() => selectedAsignadoId = t?.id),
                    ),

                  const SizedBox(height: 12),

                  // Monto
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: t.amountLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: t.descriptionOptionalLabel,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) return;
                      // TODO: Validar campos requeridos

                      final nuevoGasto = Gasto(
                        id:
                            existingExpense?.id ??
                            '', // Si edita, mantiene ID (si la API soporta update directo con mismo objeto)
                        fechaGasto:
                            existingExpense?.date ??
                            DateTime.now(), // update date? prefer no
                        monto: amount,
                        empresaId: vm.empresaId,
                        trabajoAsignadoId: selectedAsignadoId ?? '',
                        trabajoId: '', // Se podría buscar del trabajo asignado
                        clienteId: selectedClienteId ?? '',
                        idTipoGasto: selectedTypeId ?? '',
                        urlComprobante: '',
                        creadoPor: widget.userId,
                        actualizadoPor: widget.userId,
                        descripcion: descriptionController.text,
                        fechaCreacion:
                            DateTime.now(), // Backend lo maneja usualmente para nuevos
                        fechaActualizacion: DateTime.now(),
                      );

                      // Si es editar, llamar a actualizar (si existiera en VM), sino agregar
                      // Asumimos agregar por ahora o lógica de VM manejará upsert si ID existe
                      await vm.addExpense(nuevoGasto);

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.saveButton)),
                      ); // "Guardar" o mensaje éxito
                    },
                    child: Text(t.saveButton),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAssignAmountDialog(BuildContext context, int index) {
    final controller = TextEditingController();
    final vm = context.read<ExpensesViewModel>();
    final t = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.assignAmountTitle,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t.amountLabel,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  await vm.completePendingExpense(index, amount);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                }
              },
              child: Text(t.assignButton),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpensesViewModel>();
    final t = AppLocalizations.of(context)!;
    final showPending =
        widget.role == 'PERF_FIN' || widget.role == 'PERF_ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: Text(t.expensesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProblemsScreen(
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
                  builder: (_) => UserSettingsScreen(
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
        onRefresh: vm.loadData,
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Pendientes
                  if (showPending && vm.pendingExpenses.isNotEmpty) ...[
                    CurrencyText(
                      vm.pendingExpenses.fold(
                        0.0,
                        (sum, item) => sum + (item.amount ?? 0.0),
                      ),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...vm.pendingExpenses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Card(
                        child: ListTile(
                          title: Text(item.type),
                          subtitle: Text(item.description),
                          trailing: ElevatedButton(
                            onPressed: () =>
                                _showAssignAmountDialog(context, index),
                            child: Text(t.assignButton),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Registrados
                  Text(
                    t.registeredExpensesTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (vm.completedExpenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        t.exportNoExpensesMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ...vm.completedExpenses.map(
                    (exp) => Card(
                      child: ListTile(
                        title: Text(
                          exp.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exp.dateFormatted),
                            if (exp.description.isNotEmpty)
                              Text(
                                exp.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: CurrencyText(
                          exp.amount,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () => _showAddExpenseDialog(
                          context,
                          exp,
                        ), // View/Edit details
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTypeSelectionBottomSheetModular(
    BuildContext context,
    ExpensesViewModel viewModel,
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
                  listenable: viewModel.gastosVM,
                  builder: (context, _) {
                    final tipos = viewModel.gastosVM.tipos;
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
