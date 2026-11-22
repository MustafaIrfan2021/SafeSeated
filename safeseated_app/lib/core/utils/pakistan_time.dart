class PakistanTime {
  const PakistanTime._();

  static const Duration utcOffset = Duration(hours: 5);

  static DateTime fromPakistanWallClock(DateTime value) =>
      DateTime.utc(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second,
        value.millisecond,
        value.microsecond,
      ).subtract(utcOffset);

  static DateTime toPakistan(DateTime value) =>
      value.toUtc().add(utcOffset);

  static DateTime? parseUtc(String? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    if (_hasExplicitOffset(value)) return parsed.toUtc();
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  static DateTime? parseInput(String value, {DateTime? now}) {
    final normalized = value.trim();
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return _hasExplicitOffset(normalized)
          ? parsed.toUtc()
          : fromPakistanWallClock(parsed);
    }

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final suffix = match.group(3)?.toUpperCase();
    if (suffix == 'PM' && hour < 12) hour += 12;
    if (suffix == 'AM' && hour == 12) hour = 0;

    final pakistanNow = toPakistan(now ?? DateTime.now().toUtc());
    return fromPakistanWallClock(
      DateTime.utc(
        pakistanNow.year,
        pakistanNow.month,
        pakistanNow.day,
        hour,
        minute,
      ),
    );
  }

  static bool _hasExplicitOffset(String value) {
    final separator = value.indexOf(RegExp(r'[Tt ]'));
    if (separator < 0) return false;
    return RegExp(
      r'(?:Z|[+-]\d{2}(?::?\d{2})?)$',
      caseSensitive: false,
    ).hasMatch(value.substring(separator + 1).trim());
  }
}
