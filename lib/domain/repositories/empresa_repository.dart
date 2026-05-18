import '../../models/empresa.dart';

/// Contrato para gestionar la información de la empresa.
abstract class EmpresaRepository {
  Future<Empresa?> obtenerEmpresa(String id);
  Future<List<Empresa>> obtenerEmpresas();
  Future<bool> existeEmpresa(String id);
  Future<String> agregarEmpresa(Empresa empresa);
  Future<void> actualizarEmpresa(Empresa empresa);
}
