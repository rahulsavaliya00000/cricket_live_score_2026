import 'package:flutter_test/flutter_test.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';

// Helper function to simulate detection logic from CrexDataSource
MatchStatus detectStatus(String text, MatchStatus defaultStatus) {
  final lowerText = text.toLowerCase();

  bool hasMatch(String pattern) => RegExp('\\b$pattern\\b').hasMatch(lowerText);

  if (lowerText.contains('won by') ||
      hasMatch('won') ||
      hasMatch('result') ||
      hasMatch('drawn') ||
      hasMatch('abandoned') ||
      lowerText.contains('no result')) {
    return MatchStatus.completed;
  } else if (hasMatch('live') ||
      lowerText.contains('runs needed') ||
      hasMatch('need') ||
      hasMatch('trail') ||
      hasMatch('lead') ||
      hasMatch('opted') ||
      hasMatch('choose') ||
      hasMatch('toss') ||
      hasMatch('stumps') ||
      (hasMatch('day') && !hasMatch('won'))) {
    return MatchStatus.live;
  } else if (hasMatch('starts') ||
      hasMatch('am') ||
      hasMatch('pm') ||
      hasMatch('today') ||
      hasMatch('tomorrow') ||
      RegExp(r'\d{1,2}:\d{2}').hasMatch(lowerText)) {
    return MatchStatus.upcoming;
  }
  return defaultStatus;
}

void main() {
  group('Match Status Detection Logic Verification', () {
    test('should detect LIVE matches correctly', () {
      expect(
        detectStatus(
          'IND 287/4 (72.3) vs AUS - India lead by 24 runs',
          MatchStatus.live,
        ),
        MatchStatus.live,
      );
      expect(
        detectStatus(
          'CSK vs MI - CSK need 37 runs from 20 balls',
          MatchStatus.live,
        ),
        MatchStatus.live,
      );
      expect(
        detectStatus('Toss: IND opted to bat', MatchStatus.live),
        MatchStatus.live,
      );
      expect(
        detectStatus('Stumps - Day 1', MatchStatus.live),
        MatchStatus.live,
      ); // Stumps is live (ongoing)
      expect(detectStatus('Day 2 - Live', MatchStatus.live), MatchStatus.live);
    });

    test('should detect COMPLETED matches correctly', () {
      expect(
        detectStatus('India won by 17 runs', MatchStatus.live),
        MatchStatus.completed,
      );
      expect(
        detectStatus('GT won by 15 runs', MatchStatus.live),
        MatchStatus.completed,
      );
      expect(
        detectStatus('Match Abandoned due to rain', MatchStatus.live),
        MatchStatus.completed,
      );
      expect(
        detectStatus('Match Drawn', MatchStatus.live),
        MatchStatus.completed,
      );
      expect(
        detectStatus('Result: India won', MatchStatus.live),
        MatchStatus.completed,
      );
    });

    test('should detect UPCOMING matches correctly', () {
      expect(
        detectStatus('Starts at 7:30 PM', MatchStatus.upcoming),
        MatchStatus.upcoming,
      );
      expect(
        detectStatus('Today, 7:30 PM', MatchStatus.upcoming),
        MatchStatus.upcoming,
      );
      expect(
        detectStatus('Tomorrow, 3:30 PM', MatchStatus.upcoming),
        MatchStatus.upcoming,
      );
      expect(
        detectStatus('Starts in 2h 30m', MatchStatus.upcoming),
        MatchStatus.upcoming,
      );
    });

    test('should fallback to default status if no keywords found', () {
      expect(
        detectStatus('Random Match Text', MatchStatus.upcoming),
        MatchStatus.upcoming,
      );
      expect(detectStatus('Some Match', MatchStatus.live), MatchStatus.live);
    });
  });
}
