import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  String toFormat([String? newPattern, String? locale]) {
    return DateFormat(newPattern, locale).format(this);
  }

  String get lineChartDay => toFormat("E, MMM dd");

  String get lineChartDayYear => toFormat("E, MMM dd, yyyy");

  String get dateDash => toFormat("yyyy-MM-dd");

  String get dateDashReversed => toFormat("MM-dd-yyyy");

  String get dateMonth => toFormat("MMMM dd");

  String get dateMonthAbv => toFormat("MMM dd");

  String get dateReversed => toFormat("MMM dd, yyyy");

  String get dateMonthCommaYear => toFormat("dd MMM, yyyy");

  String get dateDashDays => toFormat("dd-MM-yyyy");

  String get dateDashReversedTime => toFormat("MM-dd-yyyy HH:mm");

  String get receiptDateTime => toFormat("MMMM dd, yyyy, hh:mm a");

  String get snclCreatedDate => toFormat("EEEE, dd MMM, yyyy 'at' hh:mm a");

  String get monthDayCommaYearTime => toFormat("MMMM dd, yyyy hh:mm a");

  String get monthDayTime => toFormat("MMMM dd, hh:mm a");

  String get monthDayTimeAbv => toFormat("MMM dd, hh:mm a");

  String get dateDashTime => toFormat("yyyy-MM-dd HH:mm");

  String get dateSlash => toFormat("yyyy/MM/dd");

  String get dateSlashReversed => toFormat("MM/dd/yyyy");

  String get timeHHmm => toFormat("HH:mm");

  String get timeAmPm => toFormat("hh:mm a");

  String get monthName => toFormat("MMMM");

  String get dayMonthTime => toFormat("dd MMM, hh:mm a");

  String get calendarTitle => toFormat("MMMM yyyy");

  String get monthDayAbv => toFormat("MMM dd");

  String get monthDayYear => toFormat("MMMM dd, yyyy");

  String get monthDayYearAbv => toFormat("MMM dd, yyyy");

  String get toIsoUtcFormat => toUtc().toIso8601String();

  String get snclGraphDate => toFormat("MMMM dd, hh:mm a");
  //String get snclGraphDate => "${toFormat('hh:mm')}, ${toFormat('MMM d')}";

  String get walletDate => "${toFormat('MMM d')}, ${toFormat('hh:mm a')}";

  String get envelopeDateFormat => toFormat("EEEE, MMM dd, hh:mm a");

  String get dayAtMonthAtTimeFormat =>
      toFormat("EEEE 'at' MMM dd 'at' hh:mm a");

  bool get isSaturday => weekday == 6;

  bool get isSunday => weekday == 7;

  String get dateOrdinalTime =>
      "$monthName ${_getOrdinalSuffix(day)}, $timeAmPm";

  String get monthThreeCharDayTime => toFormat("MMM d, h:mm a");

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  bool get isToday {
    var today = DateTime.now();
    return year == today.year && month == today.month && day == today.day;
  }

  bool get isYesterday {
    var yesterday = DateTime.now().subtract(Duration(days: 1)).dateDash;
    return dateDash == yesterday;
  }

  bool get isCurrentYearMonth {
    var monthToday = DateTime.now().toFormat("yyyy-MM");
    return toFormat("yyyy-MM") == monthToday;
  }

  bool get isCurrentYear {
    var yearToday = DateTime.now().year;
    return year == yearToday;
  }

  String get chartDate {
    if (isToday) return "Today";
    if (isYesterday) return "Yesterday";
    if (isCurrentYear) return toFormat("MMM d");
    return toFormat("MMM d, yyyy");
  }

  String get chartDateWithTime {
    if (isToday) return "Today, ${toFormat("h:mm a")}";
    if (isYesterday) return "Yesterday, ${toFormat("h:mm a")}";
    if (isCurrentYear) return toFormat("MMM d, h:mm a");
    return toFormat("MMM d, yyyy, h:mm a");
  }

  String get transactionHistoryDateWithTime {
    if (isToday) return "Today, ${toFormat("h:mm a")}";
    if (isYesterday) return "Yesterday, ${toFormat("h:mm a")}";
    if (isCurrentYear) return toFormat("MMM d, h:mm a");
    return toFormat("MMM d, yyyy");
  }
}

extension TimeOfDayExt on TimeOfDay {
  String get timeFormat {
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }
}

extension DateTimeStringExt on String {
  DateTime? parseDateStringLocal() {
    try {
      return DateTime.parse(this).toLocal();
    } catch (e) {
      debugPrint('Invalid date format: $e');
      return null;
    }
  }

  /// Returns either just time if within today, or date and time if not within today
  /// Format: Aug 24, 01:24 pm or 01:24 pm
  String dateTimeAsPerCurrentTime() {
    try {
      final DateTime? date = DateTime.tryParse(this)?.toLocal();
      if (date == null) {
        return "";
      }
      final now = DateTime.now().toLocal();
      if (date.day == now.day) {
        return date.timeAmPm;
      }
      return "${date.dateMonthAbv}, ${date.timeAmPm}";
    } catch (e) {
      return "";
    }
  }

  String formatToReadableDateTimeLocal({String? source}) {
    try {
      final date = DateTime.parse(this).toLocal();
      final formatter = DateFormat('MMM d, h:mm a');
      return formatter.format(date);
    } catch (e) {
      return '';
    }
  }

  @Deprecated('This is not needed, use DateTime.tryParse(this) instead')
  DateTime? parseDateString({String? source}) {
    try {
      return DateTime.parse(this);
    } catch (e) {
      return null;
    }
  }

  DateTime? parseScrappyDateFormat({String? source}) {
    try {
      // Define the date format (RFC 1123)
      DateFormat format = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");

      // Parse the string to a DateTime
      DateTime dateTime = format.parseUTC(this).toLocal();

      return dateTime;
    } catch (e) {
      return null;
    }
  }

  DateTime? parseIsoDateFormat({String? source}) {
    try {
      // Parse ISO 8601 string to UTC DateTime
      DateTime? dateTime = DateTime.tryParse(this)?.toUtc().toLocal();

      return dateTime;
    } catch (e) {
      return null;
    }
  }

  DateTime? parseIsoOrScrappyDateFormat({String? source}) {
    try {
      return parseIsoDateFormat(source: source) ??
          parseScrappyDateFormat(source: source);
    } catch (e) {
      return null;
    }
  }

  DateTime? parseDateStringToLocalTimezone({String? source}) {
    try {
      return DateTime.parse(this).toLocal();
    } catch (e) {
      debugPrint('Invalid date format: $e');
      return null;
    }
    // try {
    //   return DateTime.parse(this).add(DateTime.now().timeZoneOffset).toLocal();
    // } catch (e) {
    //   developerLog(
    //     "parseDateStringToLocalTimezone(); source: $source, date: $this, message:${e.toString()}",
    //   );
    //   //debugPrint('Invalid date format: $e');
    //   return null;
    // }
  }

  String? getCardRemainingTime() {
    DateTime now = DateTime.now().toUtc();
    DateTime? future = DateTime.tryParse(this)?.toUtc();

    if (future == null || future.isBefore(now)) return null; // Expired

    var duration = future.difference(now);

    int days = _calculateExactDays(now, future);
    int hours = duration.inHours;
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds;

    if (days > 0) {
      return days == 1 ? "1 day" : "$days days";
    } else if (hours > 0) {
      return hours == 1 ? "1 hour" : "$hours hours";
    } else if (minutes > 0) {
      return hours == 1 ? "1 min" : "$minutes min";
    } else {
      return "$seconds seconds";
    }
  }

  int _calculateExactDays(DateTime start, DateTime end) {
    DateTime startDate = DateTime(start.year, start.month, start.day);
    DateTime endDate = DateTime(end.year, end.month, end.day);
    return endDate.difference(startDate).inDays;
  }

  String? getSamedayRemainingTime() {
    final date = parseDateStringToLocalTimezone();
    if (date == null) return null;

    final now = DateTime.now();

    final isSameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return isSameDay ? date.monthDayTime : date.dateMonthAbv;
  }
}

extension TimestampExt on int {
  DateTime toDateTimeLocal() {
    final isSeconds = this < 1000000000000;
    final normalized = isSeconds ? this * 1000 : this;
    return DateTime.fromMillisecondsSinceEpoch(normalized).toLocal();
  }
}
