import 'package:flutter/material.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/models/job.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';

/// ViewModel para la pantalla de Clientes.
///
/// Contiene la lógica de filtros, búsqueda y asignación de trabajos.
class ClientsPageViewModel extends ChangeNotifier {
  final ClientesViewModel clientesVM;
  final TrabajosViewModel trabajosVM;
  final TrabajosAsignadosViewModel asignadosVM;
  final String empresaId;
  final String userId;

  ClientsPageViewModel({
    required this.clientesVM,
    required this.trabajosVM,
    required this.asignadosVM,
    required this.empresaId,
    required this.userId,
  });

  // ========== ESTADO DE FILTROS ==========

  String _searchQuery = '';
  bool _filtrosVisibles = false;
  String _asignadoFiltro = 'Todos';

  String get searchQuery => _searchQuery;
  bool get filtrosVisibles => _filtrosVisibles;
  String get asignadoFiltro => _asignadoFiltro;

  void setSearchQuery(String query) {
    _searchQuery = query;
    clientesVM.buscar(query, empresaId);
    notifyListeners();
  }

  void toggleFiltrosVisibles() {
    _filtrosVisibles = !_filtrosVisibles;
    notifyListeners();
  }

  void setAsignadoFiltro(String value) {
    _asignadoFiltro = value;
    notifyListeners();
  }

  // ========== OPCIONES DE FILTRO ==========

  List<String> get asignadoOptions => ['Todos', 'Asignados', 'No asignados'];

  // ========== DATOS DERIVADOS ==========

  Set<String> get _assignedClientIds {
    return asignadosVM.trabajos
        .where((a) => a.activo)
        .map((a) => a.clienteId)
        .toSet();
  }

  List<Cliente> get filteredClients {
    var clients = clientesVM.clientes
        .where(
          (c) =>
              empresaId.isEmpty ||
              c.empresaId.isEmpty ||
              c.empresaId == empresaId,
        )
        .toList();

    // Filtrar por asignación
    if (_asignadoFiltro == 'Asignados') {
      clients = clients
          .where((c) => _assignedClientIds.contains(c.id))
          .toList();
    } else if (_asignadoFiltro == 'No asignados') {
      clients = clients
          .where((c) => !_assignedClientIds.contains(c.id))
          .toList();
    }

    // Ordenar por nombre
    clients.sort((a, b) => a.nombre.compareTo(b.nombre));

    return clients;
  }

  List<Trabajo> get availableJobs => trabajosVM.trabajos;

  // ========== ACCIONES ==========

  Future<void> loadData() async {
    await Future.wait([
      clientesVM.cargarClientes(empresaId),
      trabajosVM.cargarTrabajos(empresaId),
      asignadosVM.cargarTrabajosAsignados(empresaId),
    ]);
  }

  Future<void> assignJobsToClient(Cliente client, Set<String> jobIds) async {
    for (final id in jobIds) {
      final trabajo = trabajosVM.trabajos.firstWhere(
        (j) => j.id == id,
        orElse: () => Trabajo(
          id: '',
          titulo: '',
          cliente: '',
          estado: '',
          descripcion: '',
          costo: 0,
          empresaId: '',
          fechaInicio: DateTime.now(),
          fechaFin: DateTime.now(),
        ),
      );
      if (trabajo.id.isEmpty) continue;

      final nuevoAsignado = TrabajoAsignado(
        id: '',
        clienteId: client.id,
        trabajoId: trabajo.id,
        tituloTrabajo: trabajo.titulo,
        precioBase: trabajo.costo,
        precioFinal: trabajo.costo,
        estado: 'En espera',
        fechaInicio: DateTime.now(),
        fechaFin: DateTime.now(),
        proximaFecha: trabajo.esCiclico
            ? DateTime.now().add(const Duration(days: 365))
            : null,
        esCiclico: trabajo.esCiclico,
        frecuenciaCiclico: trabajo.frecuenciaCiclico,
        tecnicosAsignados: const [],
        empresaId: trabajo.empresaId,
        activo: true,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        creadoPor: userId,
        actualizadoPor: userId,
      );
      await asignadosVM.agregar(nuevoAsignado);
    }
    await asignadosVM.cargarTrabajosAsignados(empresaId);
    notifyListeners();
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
}
