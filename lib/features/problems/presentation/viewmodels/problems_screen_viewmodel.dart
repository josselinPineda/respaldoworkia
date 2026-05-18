import 'package:flutter/material.dart';
import 'package:workia/models/problem.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/problemas_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:workia/l10n/app_localizations.dart';

class ProblemsScreenViewModel extends ChangeNotifier {
  final ProblemasViewModel problemasVM;
  final TrabajosViewModel trabajosVM;
  final TrabajosAsignadosViewModel asignadosVM;
  final UsuariosViewModel usuariosVM;
  final GastosViewModel gastosVM;
  final ClientesViewModel clientesVM;
  final String empresaId;
  final String userId;
  final String userRole;

  ProblemsScreenViewModel({
    required this.problemasVM,
    required this.trabajosVM,
    required this.asignadosVM,
    required this.usuariosVM,
    required this.gastosVM,
    required this.clientesVM,
    required this.empresaId,
    required this.userId,
    required this.userRole,
  });

  // State
  String _pendingSearchQuery = '';
  String _historySearchQuery = '';
  String _pendingRoleFilter = 'Todos';
  String _historyRoleFilter = 'Todos';

  String get pendingSearchQuery => _pendingSearchQuery;
  String get historySearchQuery => _historySearchQuery;
  String get pendingRoleFilter => _pendingRoleFilter;
  String get historyRoleFilter => _historyRoleFilter;

  void setPendingSearchQuery(String query) {
    _pendingSearchQuery = query;
    notifyListeners();
  }

  void setHistorySearchQuery(String query) {
    _historySearchQuery = query;
    notifyListeners();
  }

  void setPendingRoleFilter(String role) {
    _pendingRoleFilter = role;
    notifyListeners();
  }

  void setHistoryRoleFilter(String role) {
    _historyRoleFilter = role;
    notifyListeners();
  }

  // Data Loading
  Future<void> loadData() async {
    await Future.wait([
      problemasVM.cargarProblemas(empresaId),
      trabajosVM.cargarTrabajos(empresaId),
      asignadosVM.cargarTrabajosAsignados(empresaId),
      usuariosVM.cargarUsuarios(empresaId),
      gastosVM.cargarGastos(empresaId),
      clientesVM.cargarClientes(empresaId),
    ]);
  }

  // Helpers
  String getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  ({String name, String role}) resolveReporter(Problema p) {
    String name = p.nombreReportante;
    String role = p.rolReportante;

    if (p.reportadoPorId.isNotEmpty) {
      try {
        final u = usuariosVM.usuarios.firstWhere(
          (user) => user.id == p.reportadoPorId,
        );
        name = u.nombre;
        role = u.perfilId;
      } catch (_) {}
    }
    return (name: name, role: role);
  }

  String formatRole(BuildContext context, String role) {
    final t = AppLocalizations.of(context)!;
    switch (role) {
      case 'PERF_ADMIN':
        return t.adminRole;
      case 'PERF_TEC':
        return t.technicianRole;
      case 'PERF_FIN':
        return t.financeRole;
      default:
        return role;
    }
  }

  // Filter Logic
  List<Problema> get _masterList {
    List<Problema> list = problemasVM.problemas;
    if (userRole == 'PERF_TEC') {
      final myAssignments = asignadosVM.trabajos
          .where((t) => t.tecnicosAsignados.contains(userId))
          .toList();

      list = list.where((p) {
        if (p.reportadoPorId == userId) return true;
        if (p.referenciaTipo == 'Trabajo' && p.referenciaId != null) {
          final isMyAssignment = myAssignments.any(
            (a) => a.id == p.referenciaId || a.trabajoId == p.referenciaId,
          );
          if (isMyAssignment) return true;
        }
        return false;
      }).toList();
    }
    return list;
  }

  List<Problema> get pendingProblems {
    final list = _masterList.where((p) => !p.resuelto && !p.ignorado).toList();
    return _applyFilters(list, _pendingSearchQuery, _pendingRoleFilter);
  }

  List<Problema> get historyProblems {
    final list = _masterList.where((p) => p.resuelto || p.ignorado).toList();
    return _applyFilters(list, _historySearchQuery, _historyRoleFilter);
  }

  List<Problema> _applyFilters(
    List<Problema> list,
    String query,
    String roleFilter,
  ) {
    var filtered = list;
    final q = query.trim().toLowerCase();

    if (q.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.title.toLowerCase().contains(q) ||
                p.details.toLowerCase().contains(q),
          )
          .toList();
    }

    if (roleFilter != 'Todos') {
      // Note: This relies on formatted role string matching.
      // It's brittle but maintains existing logic.
      // Ideally we'd filter by role ID, but UI uses "Role - Name".
      // We'll skip exact match here and assume UI passes the raw value if updated,
      // OR we implement the same key generation logic.
      // Since formatRole needs context, we can't easily do it here without context.
      // Refactoring: Let's assume the UI passes the raw "Role - Name" string relative to the app's current locale...
      // This is bad architecture (ViewModel depending on locale-specific strings for filtering).
      // BUT for strict refactoring of existing logic, we must replicate or improve.
      // Improvement: Filter by reporter ID? No, the dropdown is distinct (Role + Name).

      // Let's implement the key generation here to match.
      // But we need context for translations.
      // Alternative: Pass the formatted roles from UI? No.

      // Temporary fix: In UI we'll build options. Here we filter by checking if the generated key matches.
      // We'll add a helper `generateRoleKey(context, problem)` in UI, but here?
      // Since we can't easily access context here for EVERY item filter loop efficiently...
      // We will perform the check in the View? No.

      // Let's modify the filter to accept a cleaner criterion.
      // But let's stick to the current string match to avoid regression.
      // We will create the key inside the loop, but we need the localized strings.
      // We can't import AppLocalizations without context if it relies on it.
      // We'll skip this specific filter implementation here and let the View handle the list generation for the dropdown?
      // Or better: The ViewModel provides the logic but needs 'Role - Name'.
      // If we pass the filter logic to the view? No.

      // Decision: We will handle text search here. Role filtering is complex due to localization.
      // We will expose a method `applyRoleFilter(List<Problema>, String roleFilter, BuildContext context)`.
      // Or we accept that `roleFilter` IS the string "Role - Name" and we generate it to compare.
      // We will add `currentContext` or similar? No.

      // Let's just return the list filtered by query, and let the UI do the final role filter?
      // Or, better, we generate the roles in English/Key and map them?
      // Too complex for now.

      // Let's assume the View passes the `roleFilter` string and we just compare it.
      // We have `_resolveReporter`. We need `_formatRole`.
      // We can't implement `_formatRole` without context.
      // So we will execute the filter in `filteredProblems(BuildContext context)`?
      // Yes.
    }
    return filtered;
  }

  List<Problema> getPendingProblems(BuildContext context) {
    var list = _masterList.where((p) => !p.resuelto && !p.ignorado).toList();
    return _applyFiltersWithContext(
      list,
      _pendingSearchQuery,
      _pendingRoleFilter,
      context,
    );
  }

  List<Problema> getHistoryProblems(BuildContext context) {
    var list = _masterList.where((p) => p.resuelto || p.ignorado).toList();
    return _applyFiltersWithContext(
      list,
      _historySearchQuery,
      _historyRoleFilter,
      context,
    );
  }

  List<Problema> _applyFiltersWithContext(
    List<Problema> list,
    String query,
    String roleFilter,
    BuildContext context,
  ) {
    var filtered = list;
    final q = query.trim().toLowerCase();

    if (q.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.title.toLowerCase().contains(q) ||
                p.details.toLowerCase().contains(q),
          )
          .toList();
    }

    if (roleFilter != 'Todos') {
      filtered = filtered.where((p) {
        final resolved = resolveReporter(p);
        final formattedRole = formatRole(context, resolved.role);
        final key = '$formattedRole - ${resolved.name}';
        return key == roleFilter;
      }).toList();
    }
    return filtered;
  }

  // Available Role Options
  List<String> getRoleOptions(BuildContext context) {
    final allRoles = _masterList
        .map((p) {
          final resolved = resolveReporter(p);
          final formattedRole = formatRole(context, resolved.role);
          return '$formattedRole - ${resolved.name}';
        })
        .toSet()
        .toList();
    allRoles.sort();
    return ['Todos', ...allRoles];
  }

  ({
    String titulo,
    String cliente,
    String direccion,
    String descripcion,
    String fechas,
    String estado,
  })
  resolveJobInfo(String? refId, String? fallbackJobId) {
    if ((refId == null || refId.isEmpty) &&
        (fallbackJobId == null || fallbackJobId.isEmpty)) {
      return (
        titulo: '',
        cliente: '',
        direccion: '',
        descripcion: '',
        fechas: '',
        estado: '',
      );
    }

    // Logic copied from ProblemsPage
    String titulo = '';
    String clienteName = '';
    String direccion = '';
    String descripcion = '';
    String fechas = '';
    String estado = '';
    String? clienteId;
    String? trabajoId;
    DateTime? fInicio;
    DateTime? fFin;

    // 1. Asignaciones
    try {
      if (refId != null) {
        final asig = asignadosVM.trabajos.firstWhere((a) => a.id == refId);
        titulo = asig.tituloTrabajo;
        clienteId = asig.clienteId;
        trabajoId = asig.trabajoId;
        estado = asig.estado;
        fInicio = asig.fechaInicio;
        fFin = asig.fechaFin;
      }
    } catch (_) {}

    // 2. Trabajos
    if (titulo.isEmpty) {
      String? idToSearch = (trabajoId != null && trabajoId.isNotEmpty)
          ? trabajoId
          : (fallbackJobId != null && fallbackJobId.isNotEmpty)
          ? fallbackJobId
          : refId;

      if ((idToSearch == null || idToSearch == refId) &&
          refId != null &&
          refId.startsWith('ASIG_')) {
        final parts = refId.split('__');
        if (parts.isNotEmpty) {
          final firstPart = parts[0];
          if (firstPart.length > 5) {
            final extractedId = firstPart.substring(5);
            if (idToSearch == refId) {
              idToSearch = extractedId;
            }
          }
        }
      }

      if (idToSearch != null && idToSearch.isNotEmpty) {
        try {
          final t = trabajosVM.trabajos.firstWhere((j) => j.id == idToSearch);
          titulo = t.titulo;
          if (descripcion.isEmpty) descripcion = t.descripcion;
          if (estado.isEmpty) estado = t.estado;
          if (fInicio == null || fFin == null) {
            fInicio = t.fechaInicio;
            fFin = t.fechaFin;
          }
          if (clienteId == null || clienteId.isEmpty) {
            clienteId = t.clienteId;
            if (clienteId.isEmpty) clienteName = t.cliente;
          }
        } catch (_) {
          titulo = '';
        }
      }
    }

    // Fechas
    if (fInicio != null && fFin != null) {
      final df = DateFormat('dd/MM/yyyy');
      final isSameDay =
          fInicio.year == fFin.year &&
          fInicio.month == fFin.month &&
          fInicio.day == fFin.day;

      if (isSameDay) {
        fechas = df.format(fInicio);
      } else {
        fechas = '${df.format(fInicio)} - ${df.format(fFin)}';
      }
    }

    // Cliente
    if (clienteId != null && clienteId.isNotEmpty) {
      try {
        final c = clientesVM.clientes.firstWhere((cl) => cl.id == clienteId);
        clienteName = c.nombre;
        direccion = c.direccion;
      } catch (_) {}
    }

    return (
      titulo: titulo,
      cliente: clienteName,
      direccion: direccion,
      descripcion: descripcion,
      fechas: fechas,
      estado: estado,
    );
  }
}
