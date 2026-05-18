import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:workia/features/agenda/presentation/viewmodels/agenda_viewmodel.dart';

class AgendaCalendar extends StatelessWidget {
  const AgendaCalendar({super.key, required this.onDateSelected});

  final Function(DateTime date) onDateSelected;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();
    final currentMonth = vm.currentMonth;

    // Calcular días
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      currentMonth.year,
      currentMonth.month,
    );

    // Lunes = 0
    int startIndex = firstDayOfMonth.weekday - 1;
    if (startIndex < 0) startIndex = 0;

    final List<DateTime?> cells = [];
    for (int i = 0; i < startIndex; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(currentMonth.year, currentMonth.month, d));
    }

    // Rellenar filas
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.yMMMM(locale).format(currentMonth);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header del mes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: vm.previousMonth,
                ),
                Text(
                  monthLabel.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: vm.nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Días de la semana
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((d) {
                return Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Grilla de días
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1, // Cuadrados
              ),
              itemCount: cells.length,
              itemBuilder: (context, index) {
                final date = cells[index];
                if (date == null) return const SizedBox.shrink();

                final jobs = vm.jobsForDate(date);
                final hasJobs = jobs.isNotEmpty;
                final isToday = DateUtils.isSameDay(date, DateTime.now());

                return GestureDetector(
                  onTap: () => onDateSelected(date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: Theme.of(context).primaryColor)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isToday
                                ? Theme.of(context).primaryColor
                                : Colors.black87,
                          ),
                        ),
                        if (hasJobs) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: jobs.take(3).map((job) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: vm.colorForJob(job.id),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
