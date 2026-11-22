import 'package:flutter_test/flutter_test.dart';
import 'package:safeseated_app/core/utils/pakistan_time.dart';

void main() {
  test('Pakistan wall-clock conversion is independent of DateTime timezone', () {
    final localDateTime = DateTime(2026, 11, 22, 3);
    final utcDateTime = DateTime.utc(2026, 11, 22, 3);

    expect(
      PakistanTime.fromPakistanWallClock(localDateTime),
      DateTime.utc(2026, 11, 21, 22),
    );
    expect(
      PakistanTime.fromPakistanWallClock(utcDateTime),
      DateTime.utc(2026, 11, 21, 22),
    );
  });

  test('timezone-free user input is interpreted as Pakistan time', () {
    final parsed = PakistanTime.parseInput('2026-11-22 03:15');

    expect(parsed, DateTime.utc(2026, 11, 21, 22, 15));
  });

  test('explicit UTC input remains the same instant', () {
    final parsed = PakistanTime.parseInput('2026-11-21T22:15:00Z');

    expect(parsed, DateTime.utc(2026, 11, 21, 22, 15));
  });

  test('timezone-free API timestamps are read as UTC', () {
    final parsed = PakistanTime.parseUtc('2026-11-22T03:00:00');

    expect(parsed, DateTime.utc(2026, 11, 22, 3));
    expect(
      PakistanTime.toPakistan(parsed!),
      DateTime.utc(2026, 11, 22, 8),
    );
  });
}
