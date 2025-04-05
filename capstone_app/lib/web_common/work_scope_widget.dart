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
  final List<String> _scopeOptions = ["Lifting", "Vehicle"];
  bool get isReadOnly => widget.workScopeList != null && widget.workScopeList!.isNotEmpty;

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
            if (!isReadOnly)
              ElevatedButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add),
                label: const Text("Add Row"),
              ),
          ],
        ),
        const SizedBox(height: 8),

        Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: isReadOnly
              ? {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(3),
                }
              : {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(3),
                  4: FlexColumnWidth(1),
                },
          children: [
            // Table Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[300]),
              children: [
                _buildHeaderCell("Start Destination"),
                _buildHeaderCell("End Destination"),
                _buildHeaderCell("Scope"),
                _buildHeaderCell("Equipment"),
                if (!isReadOnly) _buildHeaderCell("Action"),
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
                  if (!isReadOnly) (i == 0 ? _buildEmptyActionCell() : _buildActionCell(i)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildHeaderCell(String title) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTableCell(int index, String key) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: isReadOnly
            ? Text(_workScopeList[index][key] ?? "", textAlign: TextAlign.center)
            : TextFormField(
                initialValue: _workScopeList[index][key],
                textAlign: TextAlign.center,
                onChanged: (value) => _updateWorkScope(index, key, value),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
      ),
    );
  }

  Widget _buildDropdownCell(int index) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: isReadOnly
            ? Text(_workScopeList[index]["scope"] ?? "", textAlign: TextAlign.center)
            : DropdownButtonFormField<String>(
                value: _workScopeList[index]["scope"]!.isNotEmpty ? _workScopeList[index]["scope"] : null,
                items: _scopeOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) => _updateWorkScope(index, "scope", value!),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
      ),
    );
  }

  Widget _buildEquipmentCell(int index) {
    String equipmentValue = _workScopeList[index]["equipmentList"] ?? "";

    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: isReadOnly
            ? Text(equipmentValue, textAlign: TextAlign.center)
            : _workScopeList[index]["scope"] == "Lifting"
                ? TextFormField(
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      _updateWorkScope(index, "equipmentList", "$value ton crane");
                    },
                    decoration: const InputDecoration(
                      labelText: "Enter Crane Threshold (Tons)",
                      border: InputBorder.none,
                    ),
                  )
                : _workScopeList[index]["scope"] == "Vehicle"
                    ? TextFormField(
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          _updateWorkScope(index, "equipmentList", "$value trailer");
                        },
                        decoration: const InputDecoration(
                          labelText: "Enter Trailer",
                          border: InputBorder.none,
                        ),
                      )
                    : TextFormField(
                        initialValue: equipmentValue,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          _updateWorkScope(index, "equipmentList", value);
                        },
                        decoration: const InputDecoration(
                          labelText: "",
                          border: InputBorder.none,
                        ),
                      ),
      ),
    );
  }

  Widget _buildActionCell(int index) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Center(
        child: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeRow(index),
        ),
      ),
    );
  }

  Widget _buildEmptyActionCell() {
    return const TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Center(child: SizedBox()), // Empty placeholder
    );
  }
}