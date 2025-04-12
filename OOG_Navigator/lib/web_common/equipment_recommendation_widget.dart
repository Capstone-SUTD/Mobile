import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EquipmentRecommendationDialog extends StatefulWidget {
  const EquipmentRecommendationDialog({super.key});

  @override
  _EquipmentRecommendationDialogState createState() =>
      _EquipmentRecommendationDialogState();
}

class _EquipmentRecommendationDialogState
    extends State<EquipmentRecommendationDialog> {
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String crane = "";
  String threshold = "";
  String trailer = "";
  String crane_rule = "";
  String threshold_rule = "";

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _callBackendApi(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? "";

      final response = await http.post(
        Uri.parse('https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/equipment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "weight": double.parse(_weightController.text),
          "length": double.parse(_lengthController.text),
          "width": double.parse(_widthController.text),
          "height": double.parse(_heightController.text),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          crane = data['crane'] ?? "N/A";
          threshold = data['threshold']?.toString() ?? "N/A";
          trailer = data['trailer'] ?? "N/A";
          crane_rule = data['crane_rule'] ?? "N/A";
          threshold_rule = data['threshold_rule']?.toString() ?? "N/A";
        });
        _showResultsDialog(context);
      } else {
        throw Exception("Server responded with ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      _showErrorSnackbar("Network error: ${e.message}");
    } on TimeoutException {
      _showErrorSnackbar("Request timed out");
    } on FormatException {
      _showErrorSnackbar("Invalid server response");
    } catch (e) {
      _showErrorSnackbar("An error occurred: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showResultsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: SizedBox(
            width: 400,
            height: 520,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Recommended Equipment",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "By Threshold Rule",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: TextEditingController(text: crane_rule),
                    decoration: const InputDecoration(labelText: "Crane"),
                    readOnly: true,
                  ),
                  TextField(
                    controller: TextEditingController(text: threshold_rule),
                    decoration: const InputDecoration(labelText: "Threshold (kg)"),
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "By ML Model",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: TextEditingController(text: crane),
                    decoration: const InputDecoration(labelText: "Crane"),
                    readOnly: true,
                  ),
                  TextField(
                    controller: TextEditingController(text: threshold),
                    decoration: const InputDecoration(labelText: "Threshold (kg)"),
                    readOnly: true,
                  ),
                  TextField(
                    controller: TextEditingController(text: trailer),
                    decoration: const InputDecoration(labelText: "Trailer"),
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          String copyText =
                              "By Rule\nCrane: $crane_rule\nThreshold (kg): $threshold_rule\nBy ML Model\nCrane: $crane\nThreshold (kg): $threshold\nTrailer: $trailer";
                          Clipboard.setData(ClipboardData(text: copyText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Copied to clipboard")),
                          );
                        },
                        child: const Text("Copy"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _validateNumberInput(String? value) {
    if (value == null || value.isEmpty) return "Required field";
    final numValue = double.tryParse(value);
    if (numValue == null) return "Enter a valid number";
    if (numValue <= 0) return "Must be greater than 0";
    return null;
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: SizedBox(
        width: 400,
        height: 330,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            //child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Cargo Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lengthController,
                    decoration: const InputDecoration(
                      labelText: "Length (m)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validateNumberInput,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _widthController,
                    decoration: const InputDecoration(
                      labelText: "Width (m)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validateNumberInput,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: "Height (m)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validateNumberInput,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: "Weight (kg)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validateNumberInput,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      //),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("CANCEL"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _callBackendApi(context),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("RUN"),
        ),
      ],
    );
  }
}