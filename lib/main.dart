import 'package:flutter/material.dart';
import 'screens/vehicle_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FuelConsumptionCalculatorApp());
}

class FuelConsumptionCalculatorApp extends StatelessWidget {
  const FuelConsumptionCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fuel Consumption Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        // Global theme for buttons to ensure consistency
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const VehicleListScreen(),
    );
  }
}
