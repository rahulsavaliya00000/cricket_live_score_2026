// import 'package:http/http.dart' as http;
// import 'package:cricketbuzz/features/matches/data/datasources/scraper_cricket_datasource.dart';

// void main() async {
//   final client = http.Client();
//   final scraper = ScraperCricketDataSource(client: client);

//   try {
//     print('--- Step 1: Finding Live Match IDs ---');
//     final matches = await scraper.getLiveMatches();
//     print('Found ${matches.length} live matches');

//     if (matches.isEmpty) {
//       print('No live matches found.');
//       return;
//     }

//     // Take the first match
//     final match = matches.first;
//     final matchId = match.id;
//     print(
//       '\nTesting Match: ${match.team1.shortName} vs ${match.team2.shortName} (ID: $matchId)',
//     );

//     // Test getMatchDetail (New JSON API logic)
//     print('\n--- Step 2: Testing getMatchDetail (JSON API) ---');
//     final detail = await scraper.getMatchDetail(matchId);

//     print('Match Title: ${detail.match.title}');
//     print('Series: ${detail.match.seriesName}');
//     print('StatusText: ${detail.match.statusText}');
//     print('Venue: ${detail.match.venue}');
//     print('Innings Count: ${detail.innings.length}');

//     if (detail.innings.isNotEmpty) {
//       for (final inn in detail.innings) {
//         print(
//           '\nInnings: ${inn.teamName} (${inn.runs}/${inn.wickets} in ${inn.overs} overs)',
//         );
//         print('Top 3 Batsmen:');
//         inn.batsmen
//             .take(3)
//             .forEach(
//               (b) =>
//                   print(' - ${b.name}: ${b.runs}(${b.balls}) ${b.dismissal}'),
//             );
//         print('Top 2 Bowlers:');
//         inn.bowlers
//             .take(2)
//             .forEach(
//               (b) =>
//                   print(' - ${b.name}: ${b.wickets}/${b.runs} in ${b.overs}'),
//             );
//       }
//     }

//     print('\n--- Step 3: Testing Commentary ---');
//     print('Found ${detail.commentary.length} commentary items');
//     if (detail.commentary.isNotEmpty) {
//       print('Latest 3 entries:');
//       for (final c in detail.commentary.take(3)) {
//         print(
//           ' [${c.overNumber}.${c.ballNumber}] ${c.batsman} vs ${c.bowler}: ${c.commentary}',
//         );
//       }
//     }

//     if (detail.playingXI1.isNotEmpty || detail.playingXI2.isNotEmpty) {
//       print('\n--- Step 4: Playing XI (Extracted from JSON) ---');
//       print('Team 1: ${detail.playingXI1.join(', ')}');
//       print('Team 2: ${detail.playingXI2.join(', ')}');
//     }
//   } catch (e) {
//     print('❌ Diagnostic Error: $e');
//   } finally {
//     client.close();
//   }
// }
