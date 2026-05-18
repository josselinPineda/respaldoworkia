import 'package:workia/models/problem.dart';

/// A simple in-memory repository for storing and managing reported
/// problems.  This repository maintains a single list of all
/// problems; each problem's status is determined by its `ignored`
/// and `resolved` flags.  The repository provides convenience
/// getters to retrieve subsets of the data as well as methods for
/// adding and updating problems.
/// Repositorio en memoria para gestionar problemas reportados.
///
/// Mantiene una lista estática de [Problema] durante la sesión de la
/// aplicación.  Este repositorio no se utiliza actualmente en la
/// aplicación principal pero se conserva como ejemplo de cómo se
/// podría gestionar el almacenamiento en memoria de problemas.
class ProblemsRepository {
  // Internal list of problems.  All problems, regardless of
  // status, are stored here.  This list persists only for the
  // lifetime of the app session and is cleared when the app is
  // restarted.  In a production application this data should be
  // persisted to a database such as Firestore.
  static final List<Problema> _problems = [];

  /// Returns a list of problems that have not been ignored or
  /// resolved.  These are the problems that require attention from
  /// an administrator.  A new list is returned to avoid external
  /// modification of the internal storage.
  static List<Problema> get unresolved =>
      _problems.where((p) => !p.ignorado && !p.resuelto).toList();

  /// Returns a list of problems that have been ignored.  Ignored
  /// problems are not shown in the admin problem list but remain in
  /// the repository.  They can be used for auditing or future
  /// reference.
  static List<Problema> get ignored =>
      _problems.where((p) => p.ignorado).toList();

  /// Returns a list of problems that have been resolved.  Resolved
  /// problems are not shown in the admin problem list but remain in
  /// the repository.
  static List<Problema> get resolved =>
      _problems.where((p) => p.resuelto).toList();

  /// Adds a new problem to the repository.  The problem is added
  /// unchanged; callers should ensure that the required fields are
  /// populated.  Newly added problems default to not ignored and
  /// not resolved.
  static void addProblem(Problema problem) {
    _problems.add(problem);
  }

  /// Marks the problem at [index] in the unresolved list as
  /// ignored.  Ignored problems remain in the repository but are
  /// hidden from the unresolved view.  If the index is out of
  /// range, the method does nothing.
  static void ignoreProblem(int index) {
    final unresolvedProblems = unresolved;
    if (index < 0 || index >= unresolvedProblems.length) return;
    final Problema problem = unresolvedProblems[index];

    // Encontrar el índice en la lista principal
    final mainIndex = _problems.indexOf(problem);
    if (mainIndex != -1) {
      _problems[mainIndex] = problem.copyWith(estado: 'ignorado');
    }
  }

  /// Marks the problem at [index] in the unresolved list as
  /// resolved.  Resolved problems remain in the repository but
  /// are not shown in the unresolved view.  If the index is
  /// out of range, the method does nothing.
  static void resolveProblem(int index) {
    final unresolvedProblems = unresolved;
    if (index < 0 || index >= unresolvedProblems.length) return;
    final Problema problem = unresolvedProblems[index];

    // Encontrar el índice en la lista principal
    final mainIndex = _problems.indexOf(problem);
    if (mainIndex != -1) {
      _problems[mainIndex] = problem.copyWith(estado: 'resuelto');
    }
  }
}
