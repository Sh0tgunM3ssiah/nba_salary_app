import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fl_chart/fl_chart.dart';
import 'load_csv.dart';
import 'main.dart';
import 'utils/utils.dart'; // Import your utils.dart file

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({Key? key}) : super(key: key);

  @override
  _PlayerSelectionScreenState createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  List<Player> players = [];
  String? selectedTeam;
  Player? selectedPlayer;
  final ValueNotifier<double> fineAmountNotifier = ValueNotifier<double>(0.0);
  final TextEditingController fineController = TextEditingController();
  bool fineValid = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadPlayers();
    fineController.addListener(_onFineAmountChanged);
  }

  @override
  void dispose() {
    fineController.removeListener(_onFineAmountChanged);
    fineController.dispose();
    super.dispose();
  }

  void _onFineAmountChanged() {
    String text = fineController.text.replaceAll(',', '');
    double fineAmount = double.tryParse(text) ?? 0.0;
    if (fineAmount > 0) {
      fineValid = true;
      fineAmountNotifier.value = fineAmount;
      text = _formatNumber(fineAmount);
      if (fineController.text != text) {
        fineController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    } else {
      fineValid = false;
      fineAmountNotifier.value = 0.0;
    }
    setState(() {});
  }

  String _formatNumber(double value) {
    final NumberFormat formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  void loadPlayers() async {
    players = await loadCSV();
    setState(() {});
  }

  List<String> getTeams() {
    List<String> teams = players
        .map((player) => teamMapping[player.team] ?? player.team)
        .toSet()
        .toList();
    teams.sort(); // Sort teams alphabetically
    return teams;
  }

  List<Player> getPlayersByTeam(String team) {
    return players
        .where((player) => (teamMapping[player.team] ?? player.team) == team)
        .toList();
  }

  String formatCurrency(double amount) {
    final NumberFormat formatter = NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: '\$',
    );
    return formatter.format(amount);
  }

  Map<String, double> getTaxRates(String team) {
    Map<String, double> taxRates = {
      'Federal': 0.37,
      'NBA Escrow': 0.10,
      'Agent Fee': 0.03,
      'Jock Tax': 0.02,
      'FICA/Medicare': 0.0145,
    };

    Map<String, double> stateTaxRates = {
      'Atlanta Hawks': 0.0575, // Georgia
      'Boston Celtics': 0.05, // Massachusetts
      'Brooklyn Nets': 0.0685, // New York
      'Charlotte Hornets': 0.05499, // North Carolina
      'Chicago Bulls': 0.0495, // Illinois
      'Cleveland Cavaliers': 0.04997, // Ohio
      'Dallas Mavericks': 0.0, // Texas
      'Denver Nuggets': 0.0463, // Colorado
      'Detroit Pistons': 0.0425, // Michigan
      'Golden State Warriors': 0.13, // California
      'Houston Rockets': 0.0, // Texas
      'Indiana Pacers': 0.0323, // Indiana
      'Los Angeles Clippers': 0.13, // California
      'Los Angeles Lakers': 0.13, // California
      'Memphis Grizzlies': 0.0, // Tennessee
      'Miami Heat': 0.0, // Florida
      'Milwaukee Bucks': 0.0765, // Wisconsin
      'Minnesota Timberwolves': 0.0985, // Minnesota
      'New Orleans Pelicans': 0.06, // Louisiana
      'New York Knicks': 0.0685, // New York
      'Oklahoma City Thunder': 0.05, // Oklahoma
      'Orlando Magic': 0.0, // Florida
      'Philadelphia 76ers': 0.0307, // Pennsylvania
      'Phoenix Suns': 0.0454, // Arizona
      'Portland Trail Blazers': 0.099, // Oregon
      'Sacramento Kings': 0.13, // California
      'San Antonio Spurs': 0.0, // Texas
      'Toronto Raptors':
          0.0, // Ontario (Canada, no state tax but federal/provincial taxes apply)
      'Utah Jazz': 0.0495, // Utah
      'Washington Wizards': 0.085, // District of Columbia
    };

    taxRates['State'] =
        stateTaxRates[team] ?? 0.05; // Default to 5% if team not found

    return taxRates;
  }

  Map<String, double> calculateDeductions(double grossSalary, String team) {
    Map<String, double> taxRates = getTaxRates(team);
    Map<String, double> deductions = {};
    double totalDeductions = 0.0;

    taxRates.forEach((key, value) {
      double deduction = grossSalary * value;
      deductions[key] = deduction;
      totalDeductions += deduction;
    });

    deductions['Net Income'] = grossSalary - totalDeductions;

    return deductions;
  }

  double calculateFinePercentage(double fine, double netIncome) {
    if (netIncome == 0) return 0;
    return (fine / netIncome) * 100;
  }

  String getCurrentSeason() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // Determine the starting year of the NBA season
    final seasonStartYear = month >= 7 ? year : year - 1;
    final seasonEndYear = seasonStartYear + 1;

    return '$seasonStartYear-$seasonEndYear';
  }

  void _navigateToUserInput() {
    if (selectedPlayer != null && fineValid) {
      setState(() {
        errorMessage = null;
      });
      final deductions = calculateDeductions(
          selectedPlayer!.grossSalary, selectedPlayer!.team);
      final finePercentage = calculateFinePercentage(
          fineAmountNotifier.value, deductions['Net Income']!);
      Navigator.pushNamed(
        context,
        '/userInput',
        arguments: {
          'selectedPlayer': selectedPlayer,
          'finePercentage': finePercentage,
        },
      );
    } else {
      setState(() {
        errorMessage = 'Please enter a valid fine amount.';
      });
    }
  }

  Widget _buildConsolidatedPieChart(
      double fine, Map<String, double> deductions) {
    List<PieChartSectionData> sections = [];

    double total = deductions.values.reduce((a, b) => a + b);
    double adjustedGross = total + fine;
    double netIncome = deductions['Net Income']! - fine;

    if (fine > adjustedGross) {
      fine = adjustedGross; // Cap the fine at 100% of the gross income
    }

    deductions.forEach((key, value) {
      if (key == 'Net Income') {
        sections.add(PieChartSectionData(
          value: (netIncome / adjustedGross) * 100,
          color: Colors.grey,
          radius: 50,
          showTitle: false,
        ));
      } else {
        sections.add(PieChartSectionData(
          value: (value / adjustedGross) * 100,
          color: _getColorForKey(key),
          radius: 50,
          showTitle: false,
        ));
      }
    });

    sections.add(PieChartSectionData(
      value: (fine / adjustedGross) * 100,
      color: Colors.red,
      radius: 50,
      showTitle: false,
    ));

    return SizedBox(
      height: 200,
      width: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          borderData: FlBorderData(show: false),
          sectionsSpace: 0,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Color _getColorForKey(String key) {
    switch (key) {
      case 'Federal':
        return Colors.blue;
      case 'NBA Escrow':
        return Colors.orange;
      case 'Agent Fee':
        return Colors.green;
      case 'Jock Tax':
        return Colors.purple;
      case 'FICA/Medicare':
        return Colors.yellow;
      case 'State':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double>? deductions;
    double finePercentage = 0.0;
    if (selectedPlayer != null) {
      deductions = calculateDeductions(
          selectedPlayer!.grossSalary, selectedPlayer!.team);
      finePercentage = calculateFinePercentage(
          fineAmountNotifier.value, deductions['Net Income']!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select NBA Player'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton<String>(
                        hint: const Text('Select Team',
                            style: TextStyle(color: Colors.white)),
                        value: selectedTeam,
                        onChanged: (String? value) {
                          setState(() {
                            selectedTeam = value;
                            selectedPlayer =
                                null; // Reset player selection when team changes
                          });
                        },
                        items: getTeams().map((String team) {
                          return DropdownMenuItem<String>(
                            value: team,
                            child: Text(team,
                                style: TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        dropdownColor: Colors.black,
                      ),
                      if (selectedTeam != null)
                        DropdownButton<Player>(
                          hint: const Text('Select Player',
                              style: TextStyle(color: Colors.white)),
                          value: selectedPlayer,
                          onChanged: (Player? value) {
                            setState(() {
                              selectedPlayer = value;
                            });
                          },
                          items: getPlayersByTeam(selectedTeam!)
                              .map((Player player) {
                            return DropdownMenuItem<Player>(
                              value: player,
                              child: Text(player.name,
                                  style: TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          dropdownColor: Colors.black,
                        ),
                      if (selectedPlayer != null) ...[
                        Text(
                          'Gross Salary (${getCurrentSeason()}): ${formatCurrency(selectedPlayer!.grossSalary)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: fineController,
                          decoration: const InputDecoration(
                            labelText: 'Enter fine amount',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        if (errorMessage != null) ...[
                          Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 16),
                        if (deductions != null) ...[
                          Row(
                            children: [
                              _buildConsolidatedPieChart(
                                  fineAmountNotifier.value, deductions),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...deductions.entries.map((entry) {
                                      if (entry.key == 'Net Income') {
                                        double netIncome = entry.value -
                                            fineAmountNotifier.value;
                                        return Text(
                                          '${entry.key}: ${formatCurrency(netIncome)}',
                                          style: TextStyle(
                                            color: _getColorForKey(entry.key),
                                            fontSize: 16,
                                          ),
                                        );
                                      }
                                      return Text(
                                        '${entry.key}: ${formatCurrency(entry.value)}',
                                        style: TextStyle(
                                          color: _getColorForKey(entry.key),
                                          fontSize: 16,
                                        ),
                                      );
                                    }).toList(),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fine Amount: ${formatCurrency(fineAmountNotifier.value)}',
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 18),
                                    ),
                                    Text(
                                      'Fine as Percentage of Net Income: ${finePercentage.toStringAsFixed(2)}%',
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        ValueListenableBuilder<double>(
                          valueListenable: fineAmountNotifier,
                          builder: (context, fineAmount, _) {
                            return ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    fineValid
                                        ? Colors.blue
                                        : Colors.grey), // Disable color
                                padding: MaterialStateProperty.all(
                                    const EdgeInsets.all(16.0)),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                elevation: MaterialStateProperty.all(5),
                              ),
                              onPressed: fineValid
                                  ? _navigateToUserInput
                                  : null, // Disable button when fine is not valid
                              child: const Text('Comparable Fine Calculator',
                                  style: TextStyle(color: Colors.white)),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            AdBanner(),
          ],
        ),
      ),
    );
  }
}
