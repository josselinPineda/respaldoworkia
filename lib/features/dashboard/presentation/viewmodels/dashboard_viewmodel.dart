import 'package:flutter/material.dart';
import 'package:workia/presentation/viewmodels/problemas_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';

class DashboardMetrics {
  final int jobsToday;
  final double registeredHours;
  final int completedJobs;
  final int pendingJobs;

  const DashboardMetrics({
    this.jobsToday = 0,
    this.registeredHours = 0.0,
    this.completedJobs = 0,
    this.pendingJobs = 0,
  });
}

class DashboardViewModel extends ChangeNotifier {
  final TrabajosViewModel trabajosVM;
  final TrabajosAsignadosViewModel asignadosVM;
  final ProblemasViewModel problemasVM;
  final String userId;
  final String empresaId;
  final String userRole;

  DashboardViewModel({
    required this.trabajosVM,
    required this.asignadosVM,
    required this.problemasVM,
    required this.userId,
    required this.empresaId,
    required this.userRole,
  });

  bool _loading = false;
  bool get loading => _loading;

  DashboardMetrics _metrics = const DashboardMetrics();
  DashboardMetrics get metrics => _metrics;

  List<dynamic> _todayJobs = [];
  List<dynamic> get todayJobs => _todayJobs;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _recalculateMetrics();
    notifyListeners();
  }

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();

    try {
      await Future.wait([
        trabajosVM.cargarTrabajos(empresaId),
        asignadosVM.cargarTrabajosAsignados(empresaId),
        problemasVM.cargarProblemas(empresaId),
      ]);
      _recalculateMetrics();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _recalculateMetrics() {
    final now = DateTime.now();

    // 1. Jobs Today & Today List
    // Filter logic depends on role. For now assuming simplified logic:
    // Techs see assigned jobs, Admin/Finance see all Company jobs.
    // Also filtering by selected date if needed, but "Today" metrics specifically refer to today.

    List<dynamic> jobsForToday = [];
    int pendingCount = 0;
    int completedCount = 0;

    // Helper to check if date matches today
    bool isToday(DateTime? date) {
      if (date == null) return false;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }

    if (userRole == 'tecnico') {
      // Techs rely on asignadosVM logic mostly
      final myAssignments = asignadosVM.trabajos
          .where((t) => t.tecnicosAsignados.contains(userId) && t.activo)
          .toList();

      // Filter for today based on fechaInicio
      jobsForToday = myAssignments
          .where((t) => isToday(t.fechaInicio))
          .toList();

      pendingCount = myAssignments
          .where((t) => t.estado == 'Pendiente' || t.estado == 'En Progreso')
          .length;
      completedCount = myAssignments
          .where((t) => t.estado == 'Finalizado' || t.estado == 'Cerrado')
          .length;
    } else {
      // Admins see all jobs
      final allJobs = trabajosVM.trabajos.where((t) => t.activo).toList();
      jobsForToday = allJobs.where((t) => isToday(t.fechaInicio)).toList();

      pendingCount = allJobs
          .where((t) => t.estado == 'Pendiente' || t.estado == 'En Progreso')
          .length;
      completedCount = allJobs
          .where((t) => t.estado == 'Finalizado' || t.estado == 'Completado')
          .length;
    }

    _todayJobs = jobsForToday;

    // 2. Mocking hours for now as activity structure is complex to aggregate here quickly
    // In a real scenario, iterate _actividadesPorTrabajo and sum hours for today.
    double hours = 0.0;

    // 3. Update Metrics
    _metrics = DashboardMetrics(
      jobsToday: jobsForToday.length,
      registeredHours: hours, // Placeholder
      completedJobs: completedCount,
      pendingJobs: pendingCount,
    );
  }
}
