import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fl_chart/fl_chart.dart';
import 'load_csv.dart';
import 'main.dart';
import 'utils/utils.dart'; // Import your utils.dart file

class UserInputScreen extends StatefulWidget {
  const UserInputScreen({Key? key}) : super(key: key);

  @override
  _UserInputScreenState createState() => _UserInputScreenState();
}

class _UserInputScreenState extends State<UserInputScreen> {
  late Player selectedPlayer;
  double finePercentage = 0.0;
  double userGrossSalary = 0.0;
  double hourlyWage = 0.0;
  double weeklyHours = 0.0;
  String? userState;
  double userNetSalary = 0.0;
  double comparableFine = 0.0;
  String salaryType = 'gross';
  String? errorMessage;
  final TextEditingController grossSalaryController = TextEditingController();
  final TextEditingController hourlyWageController = TextEditingController();
  final TextEditingController weeklyHoursController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    selectedPlayer = arguments['selectedPlayer'] as Player;
    finePercentage = arguments['finePercentage'] as double;
  }

  @override
  void initState() {
    super.initState();
    grossSalaryController.addListener(_onGrossSalaryChanged);
    hourlyWageController.addListener(_onHourlyWageChanged);
    weeklyHoursController.addListener(_onWeeklyHoursChanged);
  }

  @override
  void dispose() {
    grossSalaryController.removeListener(_onGrossSalaryChanged);
    hourlyWageController.removeListener(_onHourlyWageChanged);
    weeklyHoursController.removeListener(_onWeeklyHoursChanged);
    grossSalaryController.dispose();
    hourlyWageController.dispose();
    weeklyHoursController.dispose();
    super.dispose();
  }

  void _onGrossSalaryChanged() {
    final String text = grossSalaryController.text.replaceAll(',', '');
    userGrossSalary = double.tryParse(text) ?? 0.0;
    grossSalaryController.value = grossSalaryController.value.copyWith(
      text: _formatNumber(userGrossSalary),
      selection: TextSelection.collapsed(
          offset: _formatNumber(userGrossSalary).length),
    );
    setState(() {});
  }

  void _onHourlyWageChanged() {
    hourlyWage = double.tryParse(hourlyWageController.text) ?? 0.0;
    setState(() {});
  }

  void _onWeeklyHoursChanged() {
    weeklyHours = double.tryParse(weeklyHoursController.text) ?? 0.0;
    setState(() {});
  }

  String _formatNumber(double value) {
    final NumberFormat formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  String formatCurrency(double amount) {
    final NumberFormat formatter = NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: '\$',
    );
    return formatter.format(amount);
  }

  Map<String, double> getStateTaxRates() {
    return {
      'Alabama': 0.05,
      'Alaska': 0.0,
      'Arizona': 0.045,
      'Arkansas': 0.065,
      'California': 0.13,
      'Colorado': 0.0463,
      'Connecticut': 0.07,
      'Delaware': 0.066,
      'Florida': 0.0,
      'Georgia': 0.0575,
      'Hawaii': 0.0825,
      'Idaho': 0.0625,
      'Illinois': 0.0495,
      'Indiana': 0.0323,
      'Iowa': 0.0853,
      'Kansas': 0.0525,
      'Kentucky': 0.05,
      'Louisiana': 0.06,
      'Maine': 0.0715,
      'Maryland': 0.0575,
      'Massachusetts': 0.05,
      'Michigan': 0.0425,
      'Minnesota': 0.0985,
      'Mississippi': 0.05,
      'Missouri': 0.054,
      'Montana': 0.065,
      'Nebraska': 0.0684,
      'Nevada': 0.0,
      'New Hampshire': 0.05,
      'New Jersey': 0.0897,
      'New Mexico': 0.049,
      'New York': 0.0685,
      'North Carolina': 0.05499,
      'North Dakota': 0.0227,
      'Ohio': 0.04997,
      'Oklahoma': 0.05,
      'Oregon': 0.099,
      'Pennsylvania': 0.0307,
      'Rhode Island': 0.0599,
      'South Carolina': 0.07,
      'South Dakota': 0.0,
      'Tennessee': 0.0,
      'Texas': 0.0,
      'Utah': 0.0495,
      'Vermont': 0.0895,
      'Virginia': 0.0575,
      'Washington': 0.0,
      'West Virginia': 0.065,
      'Wisconsin': 0.0765,
      'Wyoming': 0.0,
      'District of Columbia': 0.085,
    };
  }

  double calculateUserNetSalary(double grossSalary, double stateTaxRate) {
    double federalTax = grossSalary * 0.37; // Federal tax rate
    double stateTax = grossSalary * stateTaxRate;
    double netSalary = grossSalary - federalTax - stateTax;
    return netSalary;
  }

  double calculateAnnualSalary(double hourlyWage, double weeklyHours) {
    return hourlyWage * weeklyHours * 52; // Assuming 52 weeks in a year
  }

  void _validateAndCalculate() {
    if (salaryType == 'gross' && userGrossSalary <= 0) {
      setState(() {
        errorMessage = 'Please enter your gross salary.';
      });
    } else if (salaryType == 'hourly' &&
        (hourlyWage <= 0 || weeklyHours <= 0)) {
      setState(() {
        errorMessage = 'Please enter your hourly wage and weekly hours.';
      });
    } else if (userState == null) {
      setState(() {
        errorMessage = 'Please select a state.';
      });
    } else {
      setState(() {
        errorMessage = null;
        double stateTaxRate = getStateTaxRates()[userState] ?? 0.05;
        if (salaryType == 'hourly') {
          userGrossSalary = calculateAnnualSalary(hourlyWage, weeklyHours);
        }
        userNetSalary = calculateUserNetSalary(userGrossSalary, stateTaxRate);
        comparableFine = userNetSalary * (finePercentage / 100);
      });
    }
  }

  Widget _buildConsolidatedPieChart(double grossSalary, double federalTax,
      double stateTax, double netIncome, double comparableFine) {
    List<PieChartSectionData> sections = [];

    sections.add(PieChartSectionData(
      value: (netIncome / grossSalary) * 100,
      color: Colors.green,
      radius: 50,
      showTitle: false,
    ));

    sections.add(PieChartSectionData(
      value: (federalTax / grossSalary) * 100,
      color: Colors.blue,
      radius: 50,
      showTitle: false,
    ));

    sections.add(PieChartSectionData(
      value: (stateTax / grossSalary) * 100,
      color: Colors.orange,
      radius: 50,
      showTitle: false,
    ));

    sections.add(PieChartSectionData(
      value: (comparableFine / grossSalary) * 100,
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

  @override
  Widget build(BuildContext context) {
    double federalTax = userGrossSalary * 0.37;
    double stateTax = userGrossSalary * (getStateTaxRates()[userState] ?? 0.05);
    double netIncome = userGrossSalary - federalTax - stateTax;
    double fineAsPercentageOfGrossIncome =
        (comparableFine / userGrossSalary) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparable Fine Calculator'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                // Landscape mode
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildConsolidatedPieChart(userGrossSalary, federalTax,
                        stateTax, netIncome, comparableFine),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Federal Tax: \$${formatCurrency(federalTax)}',
                          style:
                              const TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                        Text(
                          'State Tax: \$${formatCurrency(stateTax)}',
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 16),
                        ),
                        Text(
                          'Net Income: \$${formatCurrency(netIncome)}',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 16),
                        ),
                        Text(
                          'Comparable Fine: \$${formatCurrency(comparableFine)}',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        Text(
                          'Fine as % of Gross Income: ${formatCurrency(fineAsPercentageOfGrossIncome)}%',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Portrait mode
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                  salaryType == 'gross'
                                      ? Colors.blue
                                      : Colors.grey),
                              padding: MaterialStateProperty.all(
                                  const EdgeInsets.all(16.0)),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                salaryType = 'gross';
                                errorMessage = null;
                              });
                            },
                            child: const Text('Gross Salary',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                  salaryType == 'hourly'
                                      ? Colors.blue
                                      : Colors.grey),
                              padding: MaterialStateProperty.all(
                                  const EdgeInsets.all(16.0)),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                salaryType = 'hourly';
                                errorMessage = null;
                              });
                            },
                            child: const Text('Hourly Wage',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (salaryType == 'gross') ...[
                      TextField(
                        controller: grossSalaryController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your gross salary',
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ] else ...[
                      TextField(
                        controller: hourlyWageController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your hourly wage',
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                      ),
                      TextField(
                        controller: weeklyHoursController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your weekly hours',
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      hint: const Text('Select State',
                          style: TextStyle(color: Colors.white)),
                      value: userState,
                      onChanged: (String? value) {
                        setState(() {
                          userState = value;
                        });
                      },
                      items: getStateTaxRates().keys.map((String state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state,
                              style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      dropdownColor: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage != null) ...[
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.blue),
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.all(16.0)),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          onPressed: _validateAndCalculate,
                          child: const Text('Calculate',
                              style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.blue),
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.all(16.0)),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/home');
                          },
                          child: const Icon(Icons.home, color: Colors.white),
                        ),
                      ],
                    ),
                    if (userNetSalary > 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Your Net Salary: \$${userNetSalary.toStringAsFixed(2)}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        'Comparable Fine: \$${comparableFine.toStringAsFixed(2)}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your Net Salary Breakdown:',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      _buildConsolidatedPieChart(userGrossSalary, federalTax,
                          stateTax, netIncome, comparableFine),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Federal Tax: \$${federalTax.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.blue, fontSize: 16),
                          ),
                          Text(
                            'State Tax: \$${stateTax.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.orange, fontSize: 16),
                          ),
                          Text(
                            'Net Income: \$${netIncome.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.green, fontSize: 16),
                          ),
                          Text(
                            'Comparable Fine: \$${comparableFine.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                          ),
                          Text(
                            'Fine as % of Gross Income: ${fineAsPercentageOfGrossIncome.toStringAsFixed(2)}%',
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
