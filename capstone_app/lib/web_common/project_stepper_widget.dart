import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'step_label.dart';

class ProjectStepperWidget extends StatefulWidget {
  final Function(int) onStepTapped;
  final dynamic projectId;
  final String? currentStage;
  final Function(String newStage)? onStageUpdated;

  const ProjectStepperWidget({
    Key? key,
    required this.projectId,
    required this.currentStage,
    required this.onStepTapped,
    this.onStageUpdated,
  }) : super(key: key);

  @override
  _ProjectStepperWidgetState createState() => _ProjectStepperWidgetState();
}

class _ProjectStepperWidgetState extends State<ProjectStepperWidget> {
  late int _selectedStep;
  final List<String> _stepLabels = kStepLabels;
  bool _isUpdatingStage = false;

  @override
  void initState() {
    super.initState();
    _selectedStep = _getStepIndex(widget.currentStage);
  }

  @override
  void didUpdateWidget(ProjectStepperWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStage != oldWidget.currentStage) {
      _selectedStep = _getStepIndex(widget.currentStage);
    }
  }

  int _getStepIndex(String? stage) {
    if (stage == null) return 0;
    final index = _stepLabels.indexWhere(
        (label) => label.toLowerCase() == stage.toLowerCase());
    return index >= 0 ? index : 0;
  }

  Future<void> _onStepTapped(int index) async {
    if (_isUpdatingStage) return;

    setState(() {
      _isUpdatingStage = true;
      _selectedStep = index;
    });

    final String stage = _stepLabels[index];

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("Authentication token not found");
      }

      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/project/update-stage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'projectid': widget.projectId,
          'stage': stage,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (widget.onStageUpdated != null) {
          widget.onStageUpdated!(stage);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Stage updated to: $stage")),
        );
      } else {
        throw Exception("Server responded with ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: ${e.message}")),
      );
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request timed out")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating stage: ${e.toString()}")),
      );
      // Revert to previous step if update fails
      if (mounted) {
        setState(() => _selectedStep = _getStepIndex(widget.currentStage));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStage = false);
      }
      widget.onStepTapped(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final circleSize = isSmallScreen ? 24.0 : 30.0;
        final fontSize = isSmallScreen ? 10.0 : 12.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            width: constraints.maxWidth,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress line
                    Positioned(
                      top: circleSize / 2,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: List.generate(_stepLabels.length - 1, (index) {
                          final isCompleted = index < _selectedStep;
                          return Expanded(
                            child: Container(
                              height: 4,
                              color: isCompleted ? Colors.green : Colors.grey[300],
                            ),
                          );
                        }),
                      ),
                    ),
                    // Steps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_stepLabels.length, (index) {
                        final isCompleted = index <= _selectedStep;
                        final isActive = index == _selectedStep;

                        return GestureDetector(
                          onTap: _isUpdatingStage ? null : () => _onStepTapped(index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: circleSize,
                                  height: circleSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted ? Colors.green : Colors.grey[300],
                                    border: Border.all(
                                      color: isActive ? Colors.blue : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: isCompleted
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: circleSize * 0.5,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: circleSize * 3,
                                  child: Text(
                                    _stepLabels[index],
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? Colors.blue : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                if (_isUpdatingStage)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 2,
                      child: LinearProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}