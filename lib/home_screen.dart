import 'package:flutter/material.dart';
import 'utils/utils.dart'; // Import the utility file
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import Google Mobile Ads
import 'main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false, // Ensures no back arrow is shown
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: AppPadding.all,
                    child: Text(
                      'Welcome to the NBA Salary and Fine Calculator App! This app allows you to compare NBA player salaries and fines to your own income. Get started by selecting a player and entering the details.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: AppPadding.horizontal,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/playerSelection');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorderRadius.circular,
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: AppBorderRadius.circular,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: const Text(
                            'Get Started!',
                            style: AppTextStyles.button,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AdBanner(),
        ],
      ),
    );
  }
}
