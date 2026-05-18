
import 'package:flutter/material.dart';
import '../models/job.dart';
import '../widgets/agenda_jobs_panel.dart';

/// Página de ejemplo para integrar el panel. Sustituye tu vista/calendario
/// real por esta si quieres probar rápidamente.
class AgendaDemoPage extends StatefulWidget {
  const AgendaDemoPage({super.key});

  @override
  State<AgendaDemoPage> createState() => _AgendaDemoPageState();
}

class _AgendaDemoPageState extends State<AgendaDemoPage> {
  DateTime selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda (demo)')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          CalendarDatePicker(
            initialDate: selected,
            firstDate: DateTime(2022),
            lastDate: DateTime(2030),
            onDateChanged: (d) async {
              setState(() => selected = d);
              await showJobsForDatePanel(
                context: context,
                date: d,
                loader: _fakeLoader, // Sustituye por tu repo/caso de uso real.
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Toca un día en el calendario para abrir el panel.'),
          ),
        ],
      ),
    );
  }

  /// Simula la carga de trabajos desde tu backend.
  Future<List<Trabajo>> _fakeLoader(DateTime day) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Generamos algunos trabajos de ejemplo que caen en el día tocado.
    final inicio1 = DateTime(day.year, day.month, day.day, 16, 53);
    final fin1 = inicio1.add(const Duration(minutes: 60));
    final inicio2 = DateTime(day.year, day.month, day.day, 14, 0);
    final fin2 = inicio2.add(const Duration(minutes: 90));

    return [
      Trabajo(
        titulo: 'Chamba1',
        cliente: 'Fábrica La Esperanza, Hotel Playa Azul',
        fechaInicio: inicio1,
        fechaFin: fin1,
        estado: 'Completo',
        descripcion: 'Técnicos: Tecnico',
        costo: 0,
      ),
      Trabajo(
        titulo: 'Chamba2',
        cliente: 'anublestech',
        fechaInicio: inicio2,
        fechaFin: fin2,
        estado: 'Cancelado',
        descripcion: 'Técnicos: Allanmvito',
        costo: 0,
      ),
      Trabajo(
        titulo: 'chamba3',
        cliente: 'allambrito',
        fechaInicio: DateTime(day.year, day.month, day.day, 10, 0),
        fechaFin: DateTime(day.year, day.month, day.day, 12, 30),
        estado: 'En Progreso',
        descripcion: 'Técnicos: Allanmvito',
        costo: 0,
      ),
      Trabajo(
        titulo: 'Mantenimiento anual de aires',
        cliente: 'CL_PLAYA_AZUL',
        fechaInicio: DateTime(day.year, day.month, day.day, 16, 53),
        fechaFin: DateTime(day.year, day.month, day.day, 16, 53),
        estado: 'Pendiente',
        descripcion: 'Técnicos: USR_TEC_MIGUEL',
        costo: 0,
      ),
    ];
  }
}
