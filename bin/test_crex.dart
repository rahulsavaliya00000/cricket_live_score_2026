import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

void main() async {
  final url = 'https://crex.com/';
  final headers = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
  };

  print('Fetching $url...');
  try {
    final response = await http.get(Uri.parse(url), headers: headers);
    print('Status Code: ${response.statusCode}');

    final document = parse(response.body);
    final matchCards = document.querySelectorAll('a[href*="/scoreboard/"]');
    print('Found ${matchCards.length} match cards with href*="/scoreboard/".');

    if (matchCards.isEmpty) {
      print('HTML snippet: ${response.body.substring(0, 1000)}');
    } else {
      for (var i = 0; i < matchCards.length && i < 3; i++) {
        print(
          'Card $i text: ${matchCards[i].text.trim().replaceAll('\n', ' ')}',
        );
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
