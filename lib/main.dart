import 'package:flutter/material.dart';

void main() {
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
      ),
      home: const FuelConsumptionCalculatorPage(),
    );
  }
}

class FuelConsumptionCalculatorPage extends StatefulWidget {
  const FuelConsumptionCalculatorPage({super.key});

  @override
  State<FuelConsumptionCalculatorPage> createState() =>
      _FuelConsumptionCalculatorPageState();
}

class _FuelConsumptionCalculatorPageState
    extends State<FuelConsumptionCalculatorPage> {
  // Global key for the form to handle validation state
  final _formKey = GlobalKey<FormState>();

  // TextEditingControllers to retrieve and manage the text in input fields
  final _distanceController = TextEditingController();
  final _fuelController = TextEditingController();

  // State variable to store the calculated result string
  String _result = '';

  @override
  void dispose() {
    // Properly dispose of controllers when the widget is removed from the tree
    _distanceController.dispose();
    _fuelController.dispose();
    super.dispose();
  }

  /// Triggers validation and performs the fuel consumption calculation.
  void _calculate() {
    // Validate the form using the TextFormField validator functions
    if (_formKey.currentState!.validate()) {
      // Parse the inputs to double. Since validators passed, these should be valid numbers.
      final double distance = double.parse(_distanceController.text);
      final double fuel = double.parse(_fuelController.text);

      // Calculation logic: (liters / km) * 100 = liters per 100km
      final double consumption = (fuel / distance) * 100;

      setState(() {
        // Update the result string, rounding to 2 decimal places
        _result = 'Consum mediu: ${consumption.toStringAsFixed(2)} L/100km';
      });
    } else {
      // If validation fails, clear the result to keep the UI clean
      setState(() {
        _result = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Consumption Calculator'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        // SingleChildScrollView ensures the UI is scrollable on smaller screens or when the keyboard appears
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Input for Distance traveled
                TextFormField(
                  controller: _distanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Distanța parcursă (km)',
                    hintText: 'Ex: 450.5',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.route),
                  ),
                  // Validation logic for distance
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Completează ambele câmpuri.';
                    }
                    final n = double.tryParse(value);
                    if (n == null) {
                      return 'Introdu o valoare numerică validă.';
                    }
                    if (n <= 0) {
                      return 'Distanța trebuie să fie mai mare decât 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Input for Fuel consumed
                TextFormField(
                  controller: _fuelController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Combustibil consumat (litri)',
                    hintText: 'Ex: 35.2',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_gas_station),
                  ),
                  // Validation logic for fuel quantity
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Completează ambele câmpuri.';
                    }
                    final n = double.tryParse(value);
                    if (n == null) {
                      return 'Introdu o valoare numerică validă.';
                    }
                    if (n < 0) {
                      return 'Cantitatea de combustibil nu poate fi negativă.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                // Action button to trigger calculation
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Calculează',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Display result only when it is calculated and valid
                if (_result.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _result,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
