import 'package:flutter/material.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/models/job.dart';

class ClientDetailViewModel extends ChangeNotifier {
  // Estado de filtros para la pestaÃ±a de trabajos
  String _searchQuery = '';
  String _statusFilter = 'Todos';
  bool _filtersVisible = false;
  DateTime? _startDate;
  DateTime? _endDate;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  bool get filtersVisible => _filtersVisible;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void toggleFilters() {
    _filtersVisible = !_filtersVisible;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // LÃ³gica de filtrado
  List<TrabajoAsignado> filterAssignments(
    List<TrabajoAsignado> allAssignments,
    List<Trabajo> allJobs,
    String clientId,
  ) {
    var filtered = allAssignments
        .where((a) => a.clienteId == clientId && a.activo)
        .toList();

    // Filtro por texto (tÃtulo trabajo o tÃtulo asignaciÃ³n)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        final job = allJobs.firstWhere(
          (t) => t.id == a.trabajoId,
          orElse: () => Trabajo.empty(),
        );
        return job.titulo.toLowerCase().contains(query) ||
            a.tituloTrabajo.toLowerCase().contains(query);
      }).toList();
    }

    // Filtro por estado
    if (_statusFilter != 'Todos') {
      filtered = filtered.where((a) => a.estado == _statusFilter).toList();
    }

    // Filtro por fecha
    if (_startDate != null && _endDate != null) {
      final start = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      final end = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );
      filtered = filtered.where((a) {
        return a.fechaInicio.isAfter(start) && a.fechaInicio.isBefore(end);
      }).toList();
    }

    // Ordenar por fecha inicio descendente (mÃ¡s reciente primero)
    filtered.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));

    return filtered;
  }

  // Helpers de UI (Colores de estado)
  Color getStatusColor(String status, BuildContext context) {
    final lower = status.replaceAll('_', ' ').toLowerCase().trim();
    if (lower == 'pendiente' ||
        lower == 'pending' ||
        lower == 'on hold' ||
        lower == 'en espera') {
      return Theme.of(context).primaryColor;
    }
    if (lower == 'iniciado' || lower == 'started') return Colors.orange;
    if (lower == 'finalizado' || lower == 'finished') return Colors.green;
    if (lower == 'cerrado' || lower == 'closed') return Colors.grey.shade700;
    return Colors.grey;
  }
}
