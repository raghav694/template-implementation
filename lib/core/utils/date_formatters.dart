class DateFormatters {
  DateFormatters._();

  static const _months = [
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

  static String profileDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
