import 'package:flutter/material.dart';
import '../models/project_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_typeahead/flutter_typeahead.dart';

const String _prefsKey = 'custom_equipment_options';

class WorkScopeWidget extends StatefulWidget {
  final bool isNewProject;
  final List<Scope>? workScopeList;
  final VoidCallback? onWorkScopeChanged;

  const WorkScopeWidget({
    Key? key, 
    required this.isNewProject, 
    this.workScopeList,
    this.onWorkScopeChanged,
    }) : super(key: key);

  @override
  WorkScopeWidgetState createState() => WorkScopeWidgetState();
}

class WorkScopeWidgetState extends State<WorkScopeWidget> {
  List<Map<String, String>> _workScopeList = [];
  final List<String> _scopeOptions = ["Lifting", "Transportation"];
  bool get isReadOnly => !widget.isNewProject && widget.workScopeList != null && widget.workScopeList!.isNotEmpty;

  List<Map<String, String>> getWorkScopeData() => _workScopeList;

  List<String> _defaultEquipmentOptions = [
    "8ft X 40ft Trailer",
    "8ft X 45ft Trailer",
    "8ft X 50ft Trailer",
    "10.5ft X 30ft Low Bed",
    "10.5ft X 40ft Low Bed",
    "Self Loader",
  ];

  Set<String> _customEquipmentOptions = {};
  Map<int, TextEditingController> _controllers = {};

  Future<void> _saveCustomEquipmentOptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _customEquipmentOptions.toList());
  }

  Future<void> _loadCustomEquipmentOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOptions = prefs.getStringList(_prefsKey);
    if (savedOptions != null) {
      setState(() {
        _customEquipmentOptions = savedOptions.toSet();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.workScopeList != null && widget.workScopeList!.isNotEmpty) {
      _workScopeList = widget.workScopeList!
          .map((scope) => {
                "startDestination": scope.startdestination,
                "endDestination": scope.enddestination,
                "scope": scope.scope,
                "equipmentList": scope.equipmentList
              })
          .toList();
    } else if (widget.isNewProject) {
      _workScopeList = [
        {"startDestination": "", "endDestination": "", "scope": "", "equipmentList": ""}
      ];
    }
  }

  void _addRow() {
    setState(() {
      _workScopeList.add({"startDestination": "", "endDestination": "", "scope": "", "equipmentList": ""});
    });
    widget.onWorkScopeChanged?.call();
  }

  void _updateWorkScope(int index, String key, String value) {
    setState(() {
      _workScopeList[index][key] = value;
    });
    widget.onWorkScopeChanged?.call();
  }

  void _removeRow(int index) {
    setState(() {
      _workScopeList.removeAt(index);
    });
    widget.onWorkScopeChanged?.call();
  }

    @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Work Scope Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Work Scope Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (widget.isNewProject && !isReadOnly)
              ElevatedButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add),
                label: const Text("Add Row"),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Scrollable Table
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: IntrinsicColumnWidth(),
            border: TableBorder.all(color: Colors.grey),
            children: [
              // Table Header
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[300]),
                children: [
                  _buildHeaderCell("Start Destination"),
                  _buildHeaderCell("End Destination"),
                  _buildHeaderCell("Scope"),
                  _buildHeaderCell("Equipment"),
                  if (widget.isNewProject) _buildHeaderCell("Action"),
                ],
              ),

              // Table Data Rows
              for (int i = 0; i < _workScopeList.length; i++)
                TableRow(
                  children: [
                    _buildTableCell(i, "startDestination"),
                    _buildTableCell(i, "endDestination"),
                    _buildDropdownCell(i),
                    _buildEquipmentCell(i),
                    if (widget.isNewProject) 
                      (i == 0 && _workScopeList.length == 1) 
                        ? _buildEmptyActionCell() 
                        : _buildActionButtons(i),
                  ],
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
      ],
    );
  }

  // Header Cell Builder
  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // Editable Table Cell
  Widget _buildTableCell(int index, String key) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: !isReadOnly
          ? TextFormField(
              initialValue: _workScopeList[index][key],
              textAlign: TextAlign.center,
              onChanged: (value) => _updateWorkScope(index, key, value),
              decoration: const InputDecoration(border: InputBorder.none),
            )
          : Text(
              _workScopeList[index][key] ?? "",
              textAlign: TextAlign.center,
            ),
    );
  }

  // Dropdown Cell
  Widget _buildDropdownCell(int index) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: !isReadOnly
          ? DropdownButtonFormField<String>(
              value: _workScopeList[index]["scope"]!.isNotEmpty ? _workScopeList[index]["scope"] : null,
              items: _scopeOptions.map((option) {
                return DropdownMenuItem(value: option, child: Text(option));
              }).toList(),
              onChanged: (value) => _updateWorkScope(index, "scope", value!),
              decoration: const InputDecoration(border: InputBorder.none),
              isExpanded: true,
            )
          : Text(
              _workScopeList[index]["scope"] ?? "",
              textAlign: TextAlign.center,
            ),
    );
  }

  // Equipment Cell
    Widget _buildEquipmentCell(int index) {
    String currentValue = _workScopeList[index]["equipmentList"] ?? "";
    _controllers[index] ??= TextEditingController(text: currentValue);

    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: isReadOnly
            ? Text(currentValue, textAlign: TextAlign.center)
            : ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
                child: _workScopeList[index]["scope"] == "Lifting"
                    ? TextFormField(
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          _updateWorkScope(index, "equipmentList", "$value ton crane");
                        },
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        cursorColor: Colors.black87,
                        decoration: const InputDecoration(
                          labelText: "Enter Crane Threshold (Tons)",
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          labelStyle: const TextStyle(color: Colors.black87),
                        ),
                      )
                    : _workScopeList[index]["scope"] == "Transportation"
                        ? Row(
                            children: [
                              Expanded(
  child: Column(
    children: [
      DropdownButtonFormField<String>(
        value: _defaultEquipmentOptions.contains(currentValue)
            ? currentValue
            : null,
        items: [
          ..._defaultEquipmentOptions,
          ..._customEquipmentOptions,
        ].map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (selected) {
          if (selected != null) {
            _controllers[index]!.text = selected;
            _updateWorkScope(index, "equipmentList", selected);
          }
        },
        decoration: const InputDecoration(
          labelText: "Select Equipment",
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _controllers[index],
        textAlign: TextAlign.center,
        onEditingComplete: () {
          String newValue = _controllers[index]!.text.trim();
          if (!_defaultEquipmentOptions.contains(newValue) &&
              !_customEquipmentOptions.contains(newValue) &&
              newValue.isNotEmpty) {
            setState(() {
              _customEquipmentOptions.add(newValue);
            });
            _saveCustomEquipmentOptions();
          }
          _updateWorkScope(index, "equipmentList", newValue);
          FocusScope.of(context).unfocus();
        },
        decoration: const InputDecoration(
          labelText: "Or Enter Custom Equipment",
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    ],
  ),
),
                            ],
                          )
                        : const SizedBox.shrink(),
              ),

      ),
    );
  }
  // Action Button Cell
  Widget _buildActionButtons(int index) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _removeRow(index),
      ),
    );
  }

  Widget _buildEmptyActionCell() {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: SizedBox(width: 40), // Empty placeholder with consistent width
    );
  }
}