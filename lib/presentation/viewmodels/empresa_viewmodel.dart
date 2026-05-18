import 'package:flutter/material.dart';
import '../../models/empresa.dart';
import '../../domain/usecases/empresa/actualizar_empresa.dart';
import '../../domain/usecases/empresa/agregar_empresa.dart';
import '../../domain/usecases/empresa/obtener_empresa.dart';
import '../../domain/usecases/empresa/obtener_empresas.dart';
import '../../domain/usecases/empresa/existe_empresa.dart';

class EmpresaViewModel extends ChangeNotifier {
  final ActualizarEmpresa _actualizarEmpresa;
  final AgregarEmpresa _agregarEmpresa;
  final ObtenerEmpresa _obtenerEmpresa;
  final ObtenerEmpresas _obtenerEmpresas;
  final ExisteEmpresa _existeEmpresa;

  Empresa? _empresa;
  Empresa? get empresa => _empresa;
  bool _cargando = false;
  bool get cargando => _cargando;

  EmpresaViewModel({
    required ActualizarEmpresa actualizarEmpresa,
    required AgregarEmpresa agregarEmpresa,
    required ObtenerEmpresa obtenerEmpresa,
    required ObtenerEmpresas obtenerEmpresas,
    required ExisteEmpresa existeEmpresa,
  }) : _actualizarEmpresa = actualizarEmpresa,
       _agregarEmpresa = agregarEmpresa,
       _obtenerEmpresa = obtenerEmpresa,
       _obtenerEmpresas = obtenerEmpresas,
       _existeEmpresa = existeEmpresa;

  Future<void> cargarEmpresa(String id) async {
    _cargando = true;
    notifyListeners();
    _empresa = await _obtenerEmpresa(id);
    _cargando = false;
    notifyListeners();
  }

  Future<void> guardar(Empresa empresa) async {
    await _actualizarEmpresa(empresa);
    _empresa = empresa;
    notifyListeners();
  }

  Future<String> agregar(Empresa empresa) async {
    _cargando = true;
    notifyListeners();
    final id = await _agregarEmpresa(empresa);
    _cargando = false;
    notifyListeners();
    return id;
  }

  Future<List<Empresa>> obtenerTodas() async {
    return await _obtenerEmpresas();
  }

  Future<bool> existeEmpresa(String id) async {
    return await _existeEmpresa(id);
  }
}
