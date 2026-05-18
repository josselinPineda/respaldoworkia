import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/problem.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/features/problems/presentation/viewmodels/problems_screen_viewmodel.dart';

import 'package:workia/widgets/currency_text.dart';

class ProblemCard extends StatelessWidget {
  const ProblemCard({
    super.key,
    required this.problem,
    required this.role,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Problema problem;
  final String role;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  // Helper para formatear roles
  String formatRole(BuildContext context, String role) {
    switch (role) {
      case 'PERF_ADMIN':
        return AppLocalizations.of(context)!.adminRole;
      case 'PERF_TEC':
        return AppLocalizations.of(context)!.technicianRole;
      case 'PERF_FIN':
        return AppLocalizations.of(context)!.financeRole;
      default:
        return role;
    }
  }

  String _getResolverName(Problema problem, UsuariosViewModel usuariosVM) {
    if (!problem.resuelto) return '';
    final idToUse = problem.resueltoPorId.isNotEmpty
        ? problem.resueltoPorId
        : problem.actualizadoPorId;

    if (idToUse.isEmpty) return '';

    try {
      final user = usuariosVM.usuarios.firstWhere((u) => u.id == idToUse);
      return user.nombre;
    } catch (_) {
      return idToUse;
    }
  }

  String _getResolverRole(Problema problem, UsuariosViewModel usuariosVM) {
    if (!problem.resuelto) return '';
    final idToUse = problem.resueltoPorId.isNotEmpty
        ? problem.resueltoPorId
        : problem.actualizadoPorId;

    if (idToUse.isEmpty) return '';

    try {
      final user = usuariosVM.usuarios.firstWhere((u) => u.id == idToUse);
      return user.perfilId;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuariosVM = context.read<UsuariosViewModel>();
    final problemsScreenVM = context.read<ProblemsScreenViewModel>();

    // Buscar usuario reportante
    Usuario? reportante;
    try {
      if (problem.reportadoPorId.isNotEmpty) {
        reportante = usuariosVM.usuarios.firstWhere(
          (u) => u.id == problem.reportadoPorId,
        );
      }
    } catch (_) {
      reportante = null;
    }

    final nombreReportante = reportante?.nombre ?? problem.nombreReportante;
    final rolReportante = reportante?.perfilId ?? problem.rolReportante;

    Widget refWidget;
    String refText =
        '${AppLocalizations.of(context)!.typeLabel}: ${problem.referenciaTipo}';
    refWidget = Text(refText, style: const TextStyle(fontSize: 12));

    if (problem.referenciaTipo == 'Trabajo' && problem.referenciaId != null) {
      final info = problemsScreenVM.resolveJobInfo(
        problem.referenciaId,
        problem.trabajoId,
      );

      String titulo = info.titulo;

      if (titulo.isNotEmpty) {
        if (info.fechas.isNotEmpty) {
          refText =
              '${AppLocalizations.of(context)!.assignedJobLabel}: $titulo - ${info.fechas}';
        } else {
          refText = '${AppLocalizations.of(context)!.jobLabel}: $titulo';
        }
      } else {
        refText =
            '${AppLocalizations.of(context)!.jobIdLabel} ${problem.referenciaId}';
      }

      if (titulo.isEmpty) {
        refText =
            '${AppLocalizations.of(context)!.jobIdLabel} ${problem.referenciaId}';
      }
      refWidget = Text(refText, style: const TextStyle(fontSize: 12));
    } else if (problem.referenciaTipo == 'Gasto' &&
        problem.referenciaId != null) {
      final matching = problemsScreenVM.gastosVM.gastos
          .where((g) => g.id == problem.referenciaId)
          .toList();
      if (matching.isNotEmpty) {
        final gasto = matching.first;
        refWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppLocalizations.of(context)!.expenseLabel}: ',
              style: const TextStyle(fontSize: 12),
            ),
            CurrencyText(gasto.monto, style: const TextStyle(fontSize: 12)),
          ],
        );
      } else {
        refText =
            '${AppLocalizations.of(context)!.expenseIdLabel} ${problem.referenciaId}';
        refWidget = Text(refText, style: const TextStyle(fontSize: 12));
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      problem.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)!.reportedByPrefix}$nombreReportante (${formatRole(context, rolReportante)})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (problem.referenciaTipo == 'Trabajo' &&
                        problem.referenciaId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: refWidget,
                      ),
                    if (problem.resuelto)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Builder(
                          builder: (context) {
                            final rName = _getResolverName(problem, usuariosVM);
                            final rRole = _getResolverRole(problem, usuariosVM);
                            final rRoleStr = rRole.isNotEmpty
                                ? ' (${formatRole(context, rRole)})'
                                : '';
                            return Text(
                              '${AppLocalizations.of(context)!.resolvedByLabel}: $rName$rRoleStr',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (role != 'PERF_TEC')
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  tooltip: AppLocalizations.of(context)!.editButton,
                ),
              if (role != 'PERF_TEC')
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: onDelete,
                  tooltip: AppLocalizations.of(context)!.deleteButton,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
