/// Model representing a material expense logged by a technician.
/// The [type] indicates the category of expense (e.g. Materiales,
/// Combustible).  The [description] records what was purchased.  The
/// [amount] is filled in by finance once the cost is known.  When
/// [amount] remains null, the expense is considered pending.
class MaterialExpense {
  final String type;
  final String description;
  double? amount;
  MaterialExpense({
    required this.type,
    required this.description,
    this.amount,
  });
}