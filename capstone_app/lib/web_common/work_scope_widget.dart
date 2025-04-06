import 'package:flutter/material.dart';
import '../models/project_model.dart';

class WorkScopeWidget extends StatefulWidget {
  final bool isNewProject;
  final List<Scope>? workScopeList;

  const WorkScopeWidget({Key? key, required this.isNewProject, this.workScopeList}) : super(key: key);

  @override
  WorkScopeWidgetState createState() => WorkScopeWidgetState();
}

class WorkScopeWidgetState extends State<WorkScopeWidget> {
  List<Map<String, String>> _workScopeList = [];
  final List<String> _scopeOptions = ["Lifting", "Transportation"];
  bool get isReadOnly => !widget.isNewProject && widget.workScopeList != null && widget.workScopeList!.isNotEmpty;

  List<Map<String, String>> getWorkScopeData() => _workScopeList;

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
  }

  void _updateWorkScope(int index, String key, String value) {
    setState(() {
      _workScopeList[index][key] = value;
    });
  }

  void _removeRow(int index) {
    setState(() {
      _workScopeList.removeAt(index);
    });
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
    String equipmentValue = _workScopeList[index]["equipmentList"] ?? "";

    if (isReadOnly) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          equipmentValue,
          textAlign: TextAlign.center,
        ),
      );
    }

    // For editable mode
    String labelText = "";
    String suffix = "";
    
    if (_workScopeList[index]["scope"] == "Lifting") {
      labelText = "Enter Crane Threshold";
      suffix = "ton crane";
    } else if (_workScopeList[index]["scope"] == "Transportation") {
      labelText = "Enter Trailer";
      suffix = "trailer";
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: TextFormField(
              initialValue: equipmentValue.isNotEmpty 
                  ? equipmentValue.replaceAll(suffix, "").trim() 
                  : "",
              textAlign: TextAlign.center,
              onChanged: (value) {
                if (_workScopeList[index]["scope"] == "Lifting") {
                  _updateWorkScope(index, "equipmentList", "$value $suffix");
                } else if (_workScopeList[index]["scope"] == "Transportation") {
                  _updateWorkScope(index, "equipmentList", "$value $suffix");
                } else {
                  _updateWorkScope(index, "equipmentList", value);
                }
              },
              decoration: InputDecoration(
                labelText: labelText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (suffix.isNotEmpty) 
            Text(" $suffix"),
        ],
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