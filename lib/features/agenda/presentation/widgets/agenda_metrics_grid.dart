import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/features/agenda/presentation/viewmodels/agenda_viewmodel.dart';
import 'package:workia/l10n/app_localizations.dart';

class AgendaMetricsGrid extends StatelessWidget {
  const AgendaMetricsGrid({super.key, required this.onMetricTap});

  final Function(String metricTitle) onMetricTap;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();
    final t = AppLocalizations.of(context)!;

    // Formatear horas
    final hours = vm.registeredHoursToday;
    String hoursStr;
    if (hours == hours.roundToDouble()) {
      hoursStr = hours.toStringAsFixed(0);
    } else {
      hoursStr = hours.toStringAsFixed(1);
    }

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricCard(
          title: t.jobsTodayMetric,
          value: '${vm.todayJobsCount}',
          color: Theme.of(context).primaryColor,
          onTap: () => onMetricTap(t.jobsTodayMetric),
        ),
        _MetricCard(
          title: t.registeredHoursMetric,
          value: hoursStr,
          color: Colors.green,
          onTap: () => onMetricTap(t.registeredHoursMetric),
        ),
        _MetricCard(
          title: t.completedJobsMetric,
          value: '${vm.completedJobsCount}',
          color: Theme.of(context).primaryColor,
          onTap: () => onMetricTap(t.completedJobsMetric),
        ),
        _MetricCard(
          title: t.pendingJobsMetric,
          value: '${vm.pendingJobsCount}',
          color: Colors.orange,
          onTap: () => onMetricTap(t.pendingJobsMetric),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
