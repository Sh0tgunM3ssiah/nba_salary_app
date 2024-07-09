import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
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
      selection: TextSelection.collapsed(offset: _formatNumber(userGrossSalary).length),
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

  bool _isCalculateButtonEnabled() {
    if (salaryType == 'gross') {
      return userGrossSalary > 0 && userState != null;
    } else {
      return hourlyWage > 0 && weeklyHours > 0 && userState != null;
    }
  }

  void _validateAndCalculate() {
    if (salaryType == 'gross' && userGrossSalary <= 0) {
      setState(() {
        errorMessage = 'Please enter your gross salary.';
      });
    } else if (salaryType == 'hourly' && (hourlyWage <= 0 || weeklyHours <= 0)) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparable Fine Calculator'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Padding(
                padding: AppPadding.all,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(salaryType == 'gross' ? AppColors.primary : AppColors.secondary),
                                padding: MaterialStateProperty.all(AppPadding.all),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: AppBorderRadius.circular,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  salaryType = 'gross';
                                  errorMessage = null;
                                });
                              },
                              child: const Text('Gross Salary', style: AppTextStyles.button),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(salaryType == 'hourly' ? AppColors.primary : AppColors.secondary),
                                padding: MaterialStateProperty.all(AppPadding.all),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: AppBorderRadius.circular,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  salaryType = 'hourly';
                                  errorMessage = null;
                                });
                              },
                              child: const Text('Hourly Wage', style: AppTextStyles.button),
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
                            labelStyle: AppTextStyles.body,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: AppTextStyles.body,
                        ),
                      ] else ...[
                        TextField(
                          controller: hourlyWageController,
                          decoration: const InputDecoration(
                            labelText: 'Enter your hourly wage',
                            labelStyle: AppTextStyles.body,
                          ),
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.body,
                        ),
                        TextField(
                          controller: weeklyHoursController,
                          decoration: const InputDecoration(
                            labelText: 'Enter your weekly hours',
                            labelStyle: AppTextStyles.body,
                          ),
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.body,
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButton<String>(
                        hint: const Text('Select State', style: AppTextStyles.body),
                        value: userState,
                        onChanged: (String? value) {
                          setState(() {
                            userState = value;
                          });
                        },
                        items: getStateTaxRates().keys.map((String state) {
                          return DropdownMenuItem<String>(
                            value: state,
                            child: Text(state, style: AppTextStyles.body),
                          );
                        }).toList(),
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
                              backgroundColor: MaterialStateProperty.all(AppColors.primary),
                              padding: MaterialStateProperty.all(AppPadding.all),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: AppBorderRadius.circular,
                                ),
                              ),
                              shadowColor: MaterialStateProperty.all(AppShadows.light.first.color),
                              elevation: MaterialStateProperty.all(5),
                            ),
                            onPressed: _validateAndCalculate,
                            child: const Text('Calculate', style: AppTextStyles.button),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(AppColors.primary),
                              padding: MaterialStateProperty.all(AppPadding.all),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: AppBorderRadius.circular,
                                ),
                              ),
                              shadowColor: MaterialStateProperty.all(AppShadows.light.first.color),
                              elevation: MaterialStateProperty.all(5),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/home');
                            },
                            child: const Icon(Icons.home, color: AppColors.white),
                          ),
                        ],
                      ),
                      if (userNetSalary > 0) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Your Net Salary: \$${userNetSalary.toStringAsFixed(2)}',
                          style: AppTextStyles.heading,
                        ),
                        Text(
                          'Comparable Fine: \$${comparableFine.toStringAsFixed(2)}',
                          style: AppTextStyles.heading,
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
