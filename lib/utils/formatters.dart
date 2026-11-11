const List<String> _months = <String>[
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

const List<String> _weekdays = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Strips the time component so two dates can be compared by calendar day.
DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

/// Returns `today + [days]` without a time component.
DateTime todayPlus(int days) => dateOnly(DateTime.now()).add(Duration(days: days));

/// `12 Mar 2024`
String formatDate(DateTime value) =>
    '${value.day} ${_months[value.month - 1]} ${value.year}';

/// `12 Mar`
String formatShortDate(DateTime value) =>
    '${value.day} ${_months[value.month - 1]}';

/// `March 2024`
String formatMonthYear(DateTime value) {
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.year}';
}

/// `Wednesday, 12 March 2024`
String formatLongDate(DateTime value) =>
    '${_weekdays[value.weekday - 1]}, ${formatDate(value)}';

/// Human friendly distance such as `Today`, `3 days ago`, `in 5 days`.
String formatRelativeDay(DateTime value) {
  final int delta = dateOnly(value).difference(dateOnly(DateTime.now())).inDays;
  if (delta == 0) return 'Today';
  if (delta == 1) return 'Tomorrow';
  if (delta == -1) return 'Yesterday';
  if (delta > 1) return 'in $delta days';
  return '${delta.abs()} days ago';
}

/// Number of calendar days between [value] and today. Negative means overdue.
int daysUntil(DateTime value) =>
    dateOnly(value).difference(dateOnly(DateTime.now())).inDays;

/// `AM`, `JD` — up to two initials from a display name.
String initialsOf(String name) {
  final List<String> parts =
      name.trim().split(RegExp(r'\s+')).where((String e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

String greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
