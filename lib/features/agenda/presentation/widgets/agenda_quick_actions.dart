import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/problemas_viewmodel.dart';
import 'package:workia/widgets/dialogo_reporte_problema.dart';
import 'package:workia/features/problems/presentation/views/problems_screen.dart';
// import 'package:workia/features/agenda/presentation/viewmodels/agenda_viewmodel.dart'; // No se necesita para las acciones si usamos providers directos

class AgendaQuickActions extends StatelessWidget {
  const AgendaQuickActions({
    super.key,
    required this.userName,
    required this.role,
    required this.onRegisterMaterialExpense,
  });

  final String userName;
  final String role;
  final VoidCallback onRegisterMaterialExpense;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.quickActionsTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Reportar Problema (Todos)
        _ActionButton(
          label: t.reportProblemAction,
          color: Colors.red,
          icon: Icons.report_problem,
          onTap: () => _showReportProblemDialog(context),
        ),
        const SizedBox(height: 8),

        // Materiales (Tecnicos: Registrar, Otros: Solicitar - placeholder)
        if (role == 'PERF_TEC') ...[
          _ActionButton(
            label: t.registerMaterialsAction,
            color: Theme.of(context).primaryColor,
            icon: Icons.inventory,
            onTap: onRegisterMaterialExpense,
          ),
        ] else ...[
          _ActionButton(
            label: t.requestMaterialsAction,
            color: Theme.of(context).primaryColor,
            icon: Icons.inventory_2_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad próximamente disponible'),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 8),

        // Ver Problemas (Solo Admin)
        if (role == 'PERF_ADMIN') ...[
          _ActionButton(
            label: t.viewProblemsAction,
            color: Colors.orange,
            icon: Icons.list_alt,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProblemsScreen(userName: userName, role: role),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showReportProblemDialog(BuildContext context) {
    // Usamos read porque es un callback
    final trabajosVM = context.read<TrabajosViewModel>();
    final gastosVM = context.read<GastosViewModel>();
    final problemasVM = context.read<ProblemasViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (_) => DialogoReporteProblema(
        userName: userName,
        role: role,
        jobs: trabajosVM.trabajos,
        gastos: gastosVM.gastos,
        onSave: (problem) => problemasVM.agregar(problem),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: icon != null
            ? Icon(icon, color: Colors.white)
            : const SizedBox.shrink(),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
