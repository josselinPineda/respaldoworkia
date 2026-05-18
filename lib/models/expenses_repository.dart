import 'package:workia/models/material_expense.dart';

/// A simple in-memory repository for tracking material expenses.
/// Technicians can add pending expenses (without an amount), and
/// finance or admin users can assign an amount, which moves the
/// expense from pending to completed.  In a full application
/// these would be persisted to Firestore and the repository would
/// provide streams or futures to listen to changes.
class ExpensesRepository {
  static final List<MaterialExpense> pending = [];
  static final List<MaterialExpense> completed = [];

  /// Add a pending expense without an amount.  This is used by
  /// technicians when registering materials used.
  static void addPending(MaterialExpense exp) {
    pending.add(exp);
  }

  /// Complete a pending expense by setting its amount and moving
  /// it to the completed list.  [index] specifies which pending
  /// expense to complete.
  static void completeExpense(int index, double amount) {
    final exp = pending.removeAt(index);
    exp.amount = amount;
    completed.add(exp);
  }
}
