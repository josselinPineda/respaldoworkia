import 'package:flutter/material.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/models/job.dart';
import 'package:workia/models/trabajo_asignado.dart';

import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/sesiones_viewmodel.dart';

/// ViewModel para la pantalla de Agenda.
///
/// Contiene la lógica de calendario, métricas, mapeo de asignaciones
/// a trabajos, y filtros de estado.
class AgendaViewModel extends ChangeNotifier {
  final ClientesViewModel clientesVM;
  final UsuariosViewModel usuariosVM;
  final TrabajosViewModel trabajosVM;
  final TrabajosAsignadosViewModel asignadosVM;
  final SesionesViewModel sesionesVM;
  final String empresaId;
  final String userId;
  final String userRole;
  final String userName;

  AgendaViewModel({
    required this.clientesVM,
    required this.usuariosVM,
    required this.trabajosVM,
    required this.asignadosVM,
    required this.sesionesVM,
    required this.empresaId,
    required this.userId,
    required this.userRole,
    required this.userName,
  });

  // ========== ESTADO DEL CALENDARIO ==========

  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  final Map<String, Color> _jobColors = {};

  DateTime get currentMonth => _currentMonth;
  DateTime? get selectedDate => _selectedDate;

  void setCurrentMonth(DateTime month) {
    _currentMonth = month;
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    notifyListeners();
  }

  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    notifyListeners();
  }

  // ========== COLORES PARA TRABAJOS ==========

  static const List<Color> _palette = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.teal,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.indigo,
  ];

  Color colorForJob(String jobId) {
    if (_jobColors.containsKey(jobId)) {
      return _jobColors[jobId]!;
    }
    final color = _palette[_jobColors.length % _palette.length];
    _jobColors[jobId] = color;
    return color;
  }

  // ========== MAPEO DE ASIGNACIONES A TRABAJOS ==========

  List<Trabajo> mapAsignacionesToTrabajos(
    List<TrabajoAsignado> asignaciones,
    List<Trabajo> catalogo,
  ) {
    return asignaciones.map((a) {
      // Buscar el trabajo en el catálogo
      final job = catalogo.firstWhere(
        (j) => j.id == a.trabajoId,
        orElse: () => Trabajo(
          id: a.trabajoId,
          titulo: a.tituloTrabajo.isNotEmpty ? a.tituloTrabajo : a.trabajoId,
          cliente: '',
          estado: a.estado,
          descripcion: '',
          costo: a.precioFinal,
          empresaId: a.empresaId,
          fechaInicio: a.fechaInicio,
          fechaFin: a.fechaFin,
        ),
      );

      // Obtener nombre del cliente
      String clientName = '';
      if (a.clienteId.isNotEmpty) {
        final client = clientesVM.clientes.firstWhere(
          (c) => c.id == a.clienteId,
          orElse: () => Cliente(
            id: a.clienteId,
            nombre: a.clienteId,
            razonSocial: '',
            personaContacto: '',
            telefono: '',
            correo: '',
            direccion: '',
          ),
        );
        clientName = client.nombre;
      }

      // Obtener nombres de técnicos
      final techNames = a.tecnicosAsignados.map((techId) {
        final user = usuariosVM.usuarios.firstWhere(
          (u) => u.id == techId,
          orElse: () => Usuario(
            id: techId,
            authUid: '',
            nombre: techId,
            email: '',
            idEmpresa: '',
            perfilId: '',
          ),
        );
        return user.nombre;
      }).toList();

      return job.copyWith(
        estado: a.estado,
        cliente: clientName,
        fechaInicio: a.fechaInicio,
        fechaFin: a.fechaFin,
        empleadosAsignados: techNames,
        clienteId: a.clienteId,
      );
    }).toList();
  }

  // ========== TRABAJOS FILTRADOS ==========

  List<TrabajoAsignado> get activeAssignments {
    var assignments = asignadosVM.trabajos.where((a) => a.activo);
    if (userRole == 'PERF_TEC') {
      assignments = assignments.where(
        (a) => a.tecnicosAsignados.contains(userId),
      );
    }
    return assignments.toList();
  }

  List<Trabajo> get allJobs {
    return mapAsignacionesToTrabajos(activeAssignments, trabajosVM.trabajos);
  }

  List<Trabajo> jobsForDate(DateTime date) {
    return allJobs.where((j) {
      final start = j.fechaInicio;
      final end = j.fechaFin;
      final dateOnly = DateTime(date.year, date.month, date.day);
      final startOnly = DateTime(start.year, start.month, start.day);
      final endOnly = DateTime(end.year, end.month, end.day);
      return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
    }).toList();
  }

  // ========== MÉTRICAS ==========

  int get todayJobsCount {
    final today = DateTime.now();
    return jobsForDate(today).length;
  }

  double get registeredHoursToday {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    var sessions = sesionesVM.sesiones.where(
      (s) => s.inicio.isAfter(todayStart) && s.inicio.isBefore(todayEnd),
    );

    if (userRole == 'PERF_TEC') {
      sessions = sessions.where((s) => s.tecnicoId == userId);
    }

    double total = 0;
    for (final s in sessions) {
      final end = s.fin ?? DateTime.now();
      total += end.difference(s.inicio).inMinutes / 60;
    }
    return total;
  }

  int get completedJobsCount {
    return allJobs.where((j) => _isCompletedStatus(j.estado)).length;
  }

  int get pendingJobsCount {
    return allJobs.where((j) => _isPendingStatus(j.estado)).length;
  }

  // ========== HELPERS DE ESTADO ==========

  String normalizeStatus(String status) {
    final s = status.replaceAll('_', ' ').toLowerCase().trim();
    switch (s) {
      case 'en espera':
      case 'pendiente':
        return 'en_espera';
      case 'iniciado':
      case 'en progreso':
        return 'iniciado';
      case 'finalizado':
      case 'completo':
      case 'completado':
        return 'finalizado';
      case 'cerrado':
        return 'cerrado';
      default:
        return s;
    }
  }

  bool _isCompletedStatus(String status) {
    final n = normalizeStatus(status);
    return n == 'finalizado' || n == 'cerrado';
  }

  bool _isPendingStatus(String status) {
    final n = normalizeStatus(status);
    return n == 'en_espera';
  }

  bool isInProgressStatus(String status) {
    final n = normalizeStatus(status);
    return n == 'iniciado';
  }

  Color statusColor(String status) {
    final n = normalizeStatus(status);
    switch (n) {
      case 'finalizado':
      case 'cerrado':
        return Colors.green;
      case 'iniciado':
        return Colors.blue;
      case 'en_espera':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ========== HELPERS ==========

  String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  // ========== ACCIONES ==========

  Future<void> loadData() async {
    await Future.wait([
      clientesVM.cargarClientes(empresaId),
      usuariosVM.cargarUsuarios(empresaId),
      trabajosVM.cargarTrabajos(empresaId),
      asignadosVM.cargarTrabajosAsignados(empresaId),
      sesionesVM.loadAllRegisteredHours(empresaId),
    ]);
    notifyListeners();
  }
}
