import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class Player {
  final String name;
  final String team;
  final double grossSalary;

  const Player({required this.name, required this.team, required this.grossSalary});

  static Player fromCsv(List<dynamic> csvRow) {
    return Player(
      name: csvRow[0] as String,
      team: csvRow[1] as String,
      grossSalary: (csvRow[2] as num).toDouble(),
    );
  }
}

const Map<String, String> teamMapping = {
  'ATL': 'Atlanta Hawks',
  'BOS': 'Boston Celtics',
  'BRK': 'Brooklyn Nets',
  'CHO': 'Charlotte Hornets',
  'CHI': 'Chicago Bulls',
  'CLE': 'Cleveland Cavaliers',
  'DAL': 'Dallas Mavericks',
  'DEN': 'Denver Nuggets',
  'DET': 'Detroit Pistons',
  'GSW': 'Golden State Warriors',
  'HOU': 'Houston Rockets',
  'IND': 'Indiana Pacers',
  'LAC': 'Los Angeles Clippers',
  'LAL': 'Los Angeles Lakers',
  'MEM': 'Memphis Grizzlies',
  'MIA': 'Miami Heat',
  'MIL': 'Milwaukee Bucks',
  'MIN': 'Minnesota Timberwolves',
  'NOP': 'New Orleans Pelicans',
  'NYK': 'New York Knicks',
  'OKC': 'Oklahoma City Thunder',
  'ORL': 'Orlando Magic',
  'PHI': 'Philadelphia 76ers',
  'PHO': 'Phoenix Suns',
  'POR': 'Portland Trail Blazers',
  'SAC': 'Sacramento Kings',
  'SAS': 'San Antonio Spurs',
  'TOR': 'Toronto Raptors',
  'UTA': 'Utah Jazz',
  'WAS': 'Washington Wizards',
};

Future<List<Player>> loadCSV() async {
  final rawData = await rootBundle.loadString('assets/salaries.csv');
  return compute(_parseCSV, rawData);
}

List<Player> _parseCSV(String rawData) {
  List<List<dynamic>> listData = CsvToListConverter().convert(rawData);
  return listData.skip(1).map((csvRow) => Player.fromCsv(csvRow)).toList();
}
