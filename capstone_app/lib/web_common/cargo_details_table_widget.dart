import 'package:flutter/material.dart';
import '../models/project_model.dart';

class CargoDetailsTableWidget extends StatefulWidget {
  final List<Cargo> cargoList;
  final bool isEditable;
  final bool isNewProject;
  final bool hasRun;
  final VoidCallback? onRunPressed;
  final List<String>? resultList;

  const CargoDetailsTableWidget({
    super.key,
    required this.cargoList,
    required this.isEditable,
    required this.isNewProject,
    required this.hasRun,
    required this.onRunPressed,
    this.resultList,
  });

  @override
  CargoDetailsTableWidgetState createState() => CargoDetailsTableWidgetState();
}

class CargoDetailsTableWidgetState extends State<CargoDetailsTableWidget> {
  List<Map<String, String>> _cargoList = [];
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeCargoList();
  }

  void _initializeCargoList() {
    _cargoList = widget.isNewProject
        ? [{"cargoname": "", "length": "", "breadth": "", "height": "", "weight": "", "quantity": "", "result": ""}]
        : widget.cargoList.map((cargo) => {
            "cargoname": cargo.cargoname,
            "length": cargo.length,
            "breadth": cargo.breadth,
            "height": cargo.height,
            "weight": cargo.weight,
            "quantity": cargo.quantity,
            "result": cargo.result,
          }).toList();
  }

  void _addRow() => setState(() => _cargoList.add({
        "cargoname": "", "length": "", "breadth": "", "height": "", 
        "weight": "", "quantity": "", "result": ""
      }));

  void _updateCargo(int index, String key, String value) {
    setState(() => _cargoList[index][key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Cargo Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (widget.isNewProject && widget.isEditable)
              ElevatedButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Row"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Responsive table container
        Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: isMobile ? MediaQuery.of(context).size.width : 600,
              ),
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder.all(color: Colors.grey),
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[300]),
                    children: [
                      _buildHeaderCell("Cargo Name", 120),
                      _buildHeaderCell("Dimensions (m)", isMobile ? 120 : 160),
                      _buildHeaderCell("Weight (kg)", 80),
                      _buildHeaderCell("Units", 60),
                      _buildHeaderCell("Result", 80),
                      if (widget.isNewProject) _buildHeaderCell("Action", 60),
                    ],
                  ),
                  // Data rows
                  ..._cargoList.asMap().entries.map((entry) => TableRow(
                    children: [
                      _buildTableCell(entry.key, "cargoname", 120),
                      _buildCompactDimensionCell(entry.key, isMobile ? 120 : 160),
                      _buildWeightCell(entry.key, 80),
                      _buildTableCell(entry.key, "quantity", 60),
                      _buildResultCell(entry.key, 80),
                      if (widget.isNewProject) _buildActionButtons(entry.key, 60),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ),

        if (widget.isNewProject && !widget.hasRun)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton(
                onPressed: widget.onRunPressed,
                child: const Text("Run"),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderCell(String title, double minWidth) {
    return TableCell(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(int index, String key, double minWidth) {
    return TableCell(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: widget.isEditable
              ? TextFormField(
                  initialValue: _cargoList[index][key],
                  textAlign: TextAlign.center,
                  onChanged: (value) => _updateCargo(index, key, value),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                )
              : Text(
                  _cargoList[index][key] ?? "",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
        ),
      ),
    );
  }

  Widget _buildCompactDimensionCell(int index, double minWidth) {
    return TableCell(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCompactInput(index, "length", 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("×", style: TextStyle(fontSize: 10)),
              ),
              _buildCompactInput(index, "breadth", 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("×", style: TextStyle(fontSize: 10)),
              ),
              _buildCompactInput(index, "height", 30),
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(" ", style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInput(int index, String key, double width) {
    return SizedBox(
      width: width,
      child: widget.isEditable
          ? TextFormField(
              initialValue: _cargoList[index][key],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onChanged: (value) => _updateCargo(index, key, value),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
            )
          : Text(
              _cargoList[index][key] ?? "",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
    );
  }

  Widget _buildWeightCell(int index, double minWidth) {
    return TableCell(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                child: widget.isEditable
                    ? TextFormField(
                        initialValue: _cargoList[index]["weight"],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _updateCargo(index, "weight", value),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                      )
                    : Text(
                        _cargoList[index]["weight"] ?? "",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(" ", style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCell(int index, double minWidth) {
    return TableCell(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            (widget.resultList != null && index < widget.resultList!.length)
                ? widget.resultList![index]
                : (_cargoList[index]["result"] ?? "-"),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(int index, double minWidth) {
    return TableCell(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: IconButton(
          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => _cargoList.removeAt(index)),
        ),
      ),
    );
  }

  List<Map<String, String>> getCargoList() => _cargoList;
}