import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// Metric tile used on the dashboard.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
    this.accentSoft,
    this.onTap,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
  final Color? accentSoft;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (accentSoft ?? accent).withValues(alpha: 
                    accentSoft == null ? 0.12 : 1,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.colors.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal bars showing how the catalogue breaks down by genre.
class GenreBars extends StatelessWidget {
  const GenreBars({super.key, required this.distribution});

  final Map<String, int> distribution;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final int total = distribution.values.fold(0, (int a, int b) => a + b);
    final List<MapEntry<String, int>> entries = distribution.entries.toList();
    if (entries.isEmpty) {
      return Text(
        'Add a book to see the genre breakdown.',
        style: TextStyle(fontSize: 13, color: colors.muted),
      );
    }
    final int max = entries.first.value;

    return Column(
      children: <Widget>[
        for (int index = 0; index < entries.length; index++) ...<Widget>[
          _GenreRow(
            label: entries[index].key,
            value: entries[index].value,
            total: total,
            progress: max == 0 ? 0 : entries[index].value / max,
            color: colors.chart[index % colors.chart.length],
          ),
          if (index != entries.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _GenreRow extends StatelessWidget {
  const _GenreRow({
    required this.label,
    required this.value,
    required this.total,
    required this.progress,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int percent = total == 0 ? 0 : ((value / total) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value ${value == 1 ? 'title' : 'titles'} · $percent%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.colors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 7,
            color: context.colors.border.withValues(alpha: 0.55),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double value, Widget? _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.0, 1.0).toDouble(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Column chart of loans issued per month.
class ActivityBars extends StatelessWidget {
  const ActivityBars({super.key, required this.data});

  final List<MapEntry<DateTime, int>> data;

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final int maxValue = data.fold<int>(
      0,
      (int max, MapEntry<DateTime, int> entry) =>
          entry.value > max ? entry.value : max,
    );
    final int ceiling = maxValue == 0 ? 1 : maxValue;
    final DateTime now = DateTime.now();

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (int index = 0; index < data.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '${data[index].value}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: data[index].value == 0
                            ? colors.muted
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: data[index].value / ceiling,
                        ),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (BuildContext context, double value, Widget? _) {
                          final bool current = index == data.length - 1;
                          return Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 4),
                            height: (value * 96).clamp(4.0, 96.0),
                            decoration: BoxDecoration(
                              color: current
                                  ? colors.warning
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.22 +
                                          (value * 0.55)
                                              .clamp(0.0, 0.55)
                                              .toDouble()),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _months[data[index].key.month - 1],
                      style: TextStyle(
                        fontSize: 11,
                        color: index == data.length - 1 ||
                                data[index].key.month == now.month
                            ? Theme.of(context).colorScheme.onSurface
                            : colors.muted,
                        fontWeight: index == data.length - 1
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
