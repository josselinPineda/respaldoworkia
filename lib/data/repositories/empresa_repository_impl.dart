import '../../domain/repositories/empresa_repository.dart';
import '../../models/empresa.dart';

/// Implementación en memoria del repositorio de empresa.
///
/// Esta clase almacena una única instancia de [Empresa] y permite
/// obtenerla y actualizarla. Se utiliza en ausencia de un backend
/// persistente y se puede sustituir fácilmente por una
/// implementación que utilice Firestore u otra base de datos.
class EmpresaRepositoryImpl implements EmpresaRepository {
  Empresa? _empresa;

  /// Obtiene la empresa actualmente almacenada o `null` si no se
  /// ha establecido ninguna.  El valor se devuelve envuelto en un
  /// [Future] para conservar la compatibilidad con APIs asíncronas.
  @override
  @override
  Future<Empresa?> obtenerEmpresa(String id) async {
    return _empresa?.id == id ? _empresa : null;
  }

  /// Actualiza la empresa almacenada con la nueva [empresa].  Si no
  /// existía anteriormente una empresa, simplemente se asigna.  No
  /// se generan identificadores adicionales; el [id] de [empresa]
  /// debe proporcionarse desde la capa de presentación si se desea
  /// persistir o sincronizar.
  @override
  Future<void> actualizarEmpresa(Empresa empresa) async {
    _empresa = empresa;
  }

  @override
  Future<String> agregarEmpresa(Empresa empresa) async {
    _empresa = empresa;
    return empresa.id.isNotEmpty ? empresa.id : 'temp_id';
  }

  @override
  Future<List<Empresa>> obtenerEmpresas() async {
    return _empresa != null ? [_empresa!] : [];
  }

  @override
  Future<bool> existeEmpresa(String id) async {
    return _empresa?.id == id;
  }
}
