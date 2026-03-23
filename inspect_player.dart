import 'dart:io';
import 'package:html/parser.dart';

void main() {
  final file = File('player_profile.html');
  final document = parse(file.readAsStringSync());

  // Basic Info
  final name = document.querySelector('h1')?.text.trim();
  final country = document
      .querySelector('h3')
      ?.text
      .trim(); // Often country is h3

  print('Name: $name');
  print('Country: $country');

  // Tables for stats
  final tables = document.querySelectorAll('table');
  print('Tables found: ${tables.length}');

  for (var table in tables) {
    final rows = table.querySelectorAll('tr');
    if (rows.isNotEmpty) {
      print(
        'Table Header: ${rows.first.text.trim().replaceAll(RegExp(r'\s+'), ' ')}',
      );
    }
  }
}
