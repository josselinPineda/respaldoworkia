import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/features/jobs/presentation/viewmodels/job_detail_viewmodel.dart';
import 'package:workia/features/jobs/presentation/widgets/assign_client_sheet.dart';
import 'package:workia/features/jobs/presentation/widgets/job_client_card.dart';

/// Widget que muestra la lista de clientes asignados a un trabajo.
///
/// Este widget es puramente declarativo:
/// - Consume datos YA FILTRADOS del ViewModel.
/// - Dispara eventos al ViewModel (cambios de filtro, abrir sheet).
/// - No contiene lógica de filtrado ni cálculos.
class JobClientsList extends StatelessWidget {
  const JobClientsList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final vm = context.watch<JobDetailViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra de búsqueda y toggle de filtros
        _SearchBar(vm: vm),

        // Panel de filtros (animado)
        _FiltersPanel(vm: vm),

        const SizedBox(height: 16),

        // Botón de asignar cliente (solo si no es técnico)
        if (vm.userRole != 'PERF_TEC') ...[
          ElevatedButton.icon(
            onPressed: () => _showAssignSheet(context),
            icon: const Icon(Icons.person_add),
            label: Text(t.assignClientLabel),
          ),
          const SizedBox(height: 16),
        ],

        // Lista de clientes o mensaje vacío
        _ClientsListOrEmpty(vm: vm),
      ],
    );
  }

  void _showAssignSheet(BuildContext context) async {
    // Asegurar que los usuarios estén cargados antes de abrir el sheet
    final usuariosVM = context.read<UsuariosViewModel>();
    final job = context.read<JobDetailViewModel>().job;
    
    if (usuariosVM.usuarios.isEmpty) {
      await usuariosVM.cargarUsuarios(job.empresaId);
    }
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<JobDetailViewModel>(),
        child: const AssignClientSheet(),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.vm});

  final JobDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: t.searchClientLabel,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onChanged: vm.setSearchQuery,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(vm.showFilters ? Icons.filter_alt_off : Icons.filter_alt),
          tooltip: vm.showFilters ? t.hideFiltersTooltip : t.showFiltersTooltip,
          onPressed: vm.toggleFilters,
        ),
      ],
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({required this.vm});

  final JobDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: child,
        );
      },
      child: vm.showFilters
          ? Padding(
              key: const ValueKey('filters'),
              padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
              child: Column(
                children: [
                  // Dropdown de estado
                  DropdownButtonFormField<String>(
                    value: vm.clientStatusFilter,
                    decoration: InputDecoration(
                      labelText: t.statusLabel,
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Todos',
                        child: Text(t.allOption),
                      ),
                      DropdownMenuItem(
                        value: 'EN ESPERA',
                        child: Text(t.jobStatusOnHold),
                      ),
                      DropdownMenuItem(
                        value: 'INICIADO',
                        child: Text(t.jobStatusStarted),
                      ),
                      DropdownMenuItem(
                        value: 'FINALIZADO',
                        child: Text(t.jobStatusFinished),
                      ),
                      DropdownMenuItem(
                        value: 'CERRADO',
                        child: Text(t.jobStatusClosed),
                      ),
                      DropdownMenuItem(
                        value: 'CANCELADO',
                        child: Text(t.jobStatusCancelled),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        vm.setStatusFilter(val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Selector de rango de fechas
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: Text(
                      (vm.filterStartDate != null && vm.filterEndDate != null)
                          ? '${t.rangeLabel}: ${vm.formatDateRange(vm.filterStartDate, vm.filterEndDate)}'
                          : t.selectDateRangeButton,
                    ),
                  ),

                  // Botón de limpiar fechas
                  if (vm.filterStartDate != null)
                    TextButton(
                      onPressed: vm.clearDateFilter,
                      child: Text(t.cleanDatesButton),
                    ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('no-filters')),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      value: [vm.filterStartDate, vm.filterEndDate],
    );

    if (results != null && results.length >= 2) {
      vm.setDateRange(results[0], results[1]);
    }
  }
}

class _ClientsListOrEmpty extends StatelessWidget {
  const _ClientsListOrEmpty({required this.vm});

  final JobDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final items = vm.filteredClientAssignments;

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          vm.hasAnyClients
              ? t.noClientsFoundMessage
              : t.noClientsAssignedMessage,
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return JobClientCard(
          client: item.client,
          assignment: item.assignment,
          role: vm.userRole,
          job: vm.job,
        );
      }).toList(),
    );
  }
}
