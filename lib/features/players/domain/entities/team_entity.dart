import 'package:equatable/equatable.dart';

class CricketTeam extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String flagUrl;

  const CricketTeam({
    required this.id,
    required this.name,
    required this.slug,
    this.flagUrl = '',
  });

  @override
  List<Object?> get props => [id, name, slug];

  /// Hard-coded list of major international cricket teams with Cricbuzz IDs.
  static const List<CricketTeam> internationalTeams = [
    CricketTeam(
      id: '2',
      name: 'India',
      slug: 'india',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776162/india.jpg',
    ),
    CricketTeam(
      id: '4',
      name: 'Australia',
      slug: 'australia',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776202/australia.jpg',
    ),
    CricketTeam(
      id: '9',
      name: 'England',
      slug: 'england',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776237/england.jpg',
    ),
    CricketTeam(
      id: '11',
      name: 'South Africa',
      slug: 'south-africa',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776287/south-africa.jpg',
    ),
    CricketTeam(
      id: '13',
      name: 'New Zealand',
      slug: 'new-zealand',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776333/new-zealand.jpg',
    ),
    CricketTeam(
      id: '3',
      name: 'Pakistan',
      slug: 'pakistan',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776308/pakistan.jpg',
    ),
    CricketTeam(
      id: '5',
      name: 'Sri Lanka',
      slug: 'sri-lanka',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776254/sri-lanka.jpg',
    ),
    CricketTeam(
      id: '10',
      name: 'West Indies',
      slug: 'west-indies',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776191/west-indies.jpg',
    ),
    CricketTeam(
      id: '6',
      name: 'Bangladesh',
      slug: 'bangladesh',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776210/bangladesh.jpg',
    ),
    CricketTeam(
      id: '96',
      name: 'Afghanistan',
      slug: 'afghanistan',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776177/afghanistan.jpg',
    ),
    CricketTeam(
      id: '27',
      name: 'Ireland',
      slug: 'ireland',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c839366/ireland.jpg',
    ),
    CricketTeam(
      id: '12',
      name: 'Zimbabwe',
      slug: 'zimbabwe',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776198/zimbabwe.jpg',
    ),
    CricketTeam(
      id: '15',
      name: 'Netherlands',
      slug: 'netherlands',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776335/netherlands.jpg',
    ),
    CricketTeam(
      id: '23',
      name: 'Scotland',
      slug: 'scotland',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776280/scotland.jpg',
    ),
    CricketTeam(
      id: '72',
      name: 'Nepal',
      slug: 'nepal',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776331/nepal.jpg',
    ),
    CricketTeam(
      id: '7',
      name: 'UAE',
      slug: 'united-arab-emirates',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776242/united-arab-emirates.jpg',
    ),
    CricketTeam(
      id: '161',
      name: 'Namibia',
      slug: 'namibia',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776326/namibia.jpg',
    ),
    CricketTeam(
      id: '15',
      name: 'USA',
      slug: 'united-states-of-america',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776186/united-states-of-america.jpg',
    ),
    CricketTeam(
      id: '304',
      name: 'Oman',
      slug: 'oman',
      flagUrl: 'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776328/oman.jpg',
    ),
    CricketTeam(
      id: '26',
      name: 'Canada',
      slug: 'canada',
      flagUrl:
          'https://static.cricbuzz.com/a/img/v1/72x54/i1/c776227/canada.jpg',
    ),
  ];
}
