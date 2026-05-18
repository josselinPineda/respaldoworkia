import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/presentation/viewmodels/problemas_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:workia/features/problems/presentation/views/problems_screen.dart'; // For quick action
// import 'package:workia/features/materials/presentation/views/request_materials_screen.dart'; // Placeholder
import 'package:workia/models/job.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<UserSessionProvider>();

    return ChangeNotifierProvider(
      create: (ctx) => DashboardViewModel(
        trabajosVM: ctx.read<TrabajosViewModel>(),
        asignadosVM: ctx.read<TrabajosAsignadosViewModel>(),
        problemasVM: ctx.read<ProblemasViewModel>(),
        userId: session.userId,
        empresaId: session.empresaId,
        userRole: session.userRole,
      )..loadData(),
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    // We watch the VM to rebuild on changes
    final vm = context.watch<DashboardViewModel>();
    final session = context.read<UserSessionProvider>();
    final t = AppLocalizations.of(context)!;

    if (vm.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, session.userName, session.userRole),
              const SizedBox(height: 16),
              Text(
                t.agendaTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.agendaSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              _buildMetricsGrid(context, vm.metrics),
              const SizedBox(height: 16),
              _buildCalendarSection(context, vm),
              const SizedBox(height: 16),
              _buildTodayJobsSection(context, vm.todayJobs, t),
              const SizedBox(height: 16),
              _buildQuickActionsSection(context, session),
              const SizedBox(height: 16),
              // _buildRegisterActivityForm(context), // Can be extracted or kept if simple
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String userName, String role) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              role, // TODO: map to localized role name if needed
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Navigate to UserSettingsScreen if needed directly or via main nav
          },
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, DashboardMetrics metrics) {
    final t = AppLocalizations.of(context)!;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricCard(
          title: t.jobsTodayMetric,
          value: metrics.jobsToday.toString(),
          color: Colors.blue,
        ),
        _MetricCard(
          title: t.registeredHoursMetric,
          value: metrics.registeredHours.toStringAsFixed(1),
          color: Colors.blueGrey,
        ),
        _MetricCard(
          title: t.completedJobsMetric,
          value: metrics.completedJobs.toString(),
          color: Colors.green,
        ),
        _MetricCard(
          title: t.pendingJobsMetric,
          value: metrics.pendingJobs.toString(),
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildCalendarSection(BuildContext context, DashboardViewModel vm) {
    final now = DateTime.now();
    // Simplified calendar for demo, mirroring original static one but ideally dynamic
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat.yMMMM(
                AppLocalizations.of(context)!.localeName,
              ).format(now),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            // Arrows could control vm.selectedDate month
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text("Calendario Simplificado (Placeholder)"),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayJobsSection(
    BuildContext context,
    List<dynamic> jobs,
    AppLocalizations t,
  ) {
    if (jobs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.todayJobsLabel,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            t.noJobsTodayMessage,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.todayJobsLabel,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...jobs.map((job) {
          // Handle Trabajo vs TrabajoAsignado mapping
          String title = '';
          String subtitle = '';
          String status = '';
          Color statusColor = Colors.grey;

          if (job is Trabajo) {
            title = job.titulo;
            subtitle = job.descripcion.isNotEmpty
                ? job.descripcion
                : 'Sin descripción';
            status = job.estado;
          } else if (job is TrabajoAsignado) {
            title = 'Trabajo Asignado'; // Ideally fetch job title
            subtitle = 'ID: ${job.trabajoId}';
            status = job.estado;
          }

          // Map status color
          if (status == 'En Progreso' || status == 'Iniciado') {
            statusColor = Colors.orange;
          }
          if (status == 'Finalizado' || status == 'Completado') {
            statusColor = Colors.green;
          }
          if (status == 'Pendiente') {
            statusColor = Colors.blue;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _JobCard(
              title: title,
              subtitle: subtitle,
              timeRange: 'N/A', // Time range logic to be added
              status: status,
              statusColor: statusColor,
              buttonLabel: t.viewDetailsButton,
              onPressed: () {
                // Navigate to detail
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    UserSessionProvider session,
  ) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.quickActionsTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          label: t.reportProblemAction,
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProblemsScreen(
                  userName: session.userName,
                  role: session.userRole,
                ),
              ),
            );
          },
        ),
        // Add other actions
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.title,
    required this.subtitle,
    required this.timeRange,
    required this.status,
    required this.statusColor,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String timeRange;
  final String status;
  final Color statusColor;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha((255 * 0.15).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}
