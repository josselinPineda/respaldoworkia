import 'package:flutter/material.dart';
import 'package:workia/models/expenses_repository.dart';
import 'package:workia/models/gasto.dart';
import 'package:workia/models/material_expense.dart';
import 'package:workia/models/tipo_gasto.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';

/// Modelo de UI para mostrar gastos en la lista.
class ExpenseUIModel {
  final String id;
  final String title; // Tipo de gasto o nombre
  final DateTime date;
  final double amount;
  final String description;
  final String createdBy;
  final String createdById;
  final bool isPending;

  ExpenseUIModel({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    this.description = '',
    this.createdBy = '',
    this.createdById = '',
    this.isPending = false,
  });

  String get dateFormatted => '${date.day}/${date.month}/${date.year}';
}

class ExpensesViewModel extends ChangeNotifier {
  final GastosViewModel gastosVM;
  final UsuariosViewModel usuariosVM;
  final TrabajosAsignadosViewModel trabajosAsignadosVM;
  final ClientesViewModel clientesVM;
  final String empresaId;
  final String currentUserId;

  ExpensesViewModel({
    required this.gastosVM,
    required this.usuariosVM,
    required this.trabajosAsignadosVM,
    required this.clientesVM,
    required this.empresaId,
    required this.currentUserId,
  });

  // ========== ESTADO ==========
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ========== GETTERS COMPUTADOS ==========

  /// Lista unificada de gastos completados (Firestore) convertidos a modelo UI.
  List<ExpenseUIModel> get completedExpenses {
    return gastosVM.gastos.map((g) {
      final tipo = gastosVM.tipos.firstWhere(
        (t) => t.id == g.idTipoGasto,
        orElse: () => TipoGasto(
          id: g.idTipoGasto,
          codigo: g.idTipoGasto,
          nombre: g.idTipoGasto, // Fallback al ID si no encuentra nombre
          descripcion: '',
        ),
      );

      String createdByName = g.creadoPor;
      try {
        final user = usuariosVM.usuarios.firstWhere((u) => u.id == g.creadoPor);
        createdByName = user.nombre;
      } catch (_) {}

      return ExpenseUIModel(
        id: g.id,
        title: tipo.nombre,
        date: g.fechaGasto,
        amount: g.monto,
        description: g.descripcion,
        createdBy: createdByName,
        createdById: g.creadoPor,
        isPending: false,
      );
    }).toList();
  }

  /// Lista de gastos pendientes (Memoria local).
  /// Nota: En una app real esto vendría también de una colección en Firestore.
  List<MaterialExpense> get pendingExpenses => ExpensesRepository.pending;

  // ========== ACCIONES ==========

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      gastosVM.cargarGastos(empresaId),
      gastosVM.cargarTipos(empresaId),
      usuariosVM.cargarUsuarios(empresaId),
      trabajosAsignadosVM.cargarTrabajosAsignados(empresaId),
      clientesVM.cargarClientes(empresaId),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(Gasto gasto) async {
    _isLoading = true;
    notifyListeners();
    try {
      await gastosVM.agregar(gasto);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await gastosVM.eliminar(expenseId, empresaId, currentUserId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Completa un gasto pendiente (lo registra en Firestore y elimina de pendientes).
  Future<void> completePendingExpense(int index, double amount) async {
    // 1. Obtener la asignación por defecto (lógica original simplificada)
    // En la app original usa la primera asignación disponible.
    // Idealmente el usuario seleccionaría la asignación, pero mantenemos la lógica base.
    final asignaciones = trabajosAsignadosVM.trabajos;
    final asig = asignaciones.isNotEmpty ? asignaciones.first : null;

    final pending = ExpensesRepository.pending[index];

    // 2. Crear el gasto en Firestore
    final nuevoGasto = Gasto(
      fechaGasto: DateTime.now(),
      monto: amount,
      empresaId: asig?.empresaId ?? empresaId,
      trabajoAsignadoId:
          asig?.id ??
          '', // Si no hay asignación, va vacío o requiere logica de negocio
      trabajoId: asig?.trabajoId ?? '',
      clienteId: asig?.clienteId ?? '',
      idTipoGasto: 'TG001', // ID hardcoded en original para materiales
      urlComprobante: '',
      creadoPor: currentUserId,
      actualizadoPor: currentUserId,
      descripcion:
          '${pending.type}: ${pending.description}', // Combinar tipo y desc
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );

    await addExpense(nuevoGasto);

    // 3. Eliminar de pendientes local
    ExpensesRepository.pending.removeAt(index);
    notifyListeners();
  }

  void addPendingExpense(MaterialExpense expense) {
    ExpensesRepository.addPending(expense);
    notifyListeners();
  }
}
