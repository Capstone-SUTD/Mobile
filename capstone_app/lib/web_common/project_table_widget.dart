// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project_model.dart';
import '../web_screens/project_screen.dart';

class ProjectTableWidget extends StatefulWidget {
  final List<Project> projects;

  const ProjectTableWidget({super.key, required this.projects});

  @override
  _ProjectTableWidgetState createState() => _ProjectTableWidgetState();
}

class _ProjectTableWidgetState extends State<ProjectTableWidget> {
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  String _searchQuery = '';
  String? _sortColumn;
  bool _sortAscending = true;

  void _refreshProjects() {
    setState(() {});
  }

  void _navigateToProject(BuildContext context, String projectId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectScreen(projectId: projectId),
        fullscreenDialog: true,
      ),
    ).then((_) => _refreshProjects());
  }

  List<Project> _filterAndSortProjects(List<Project> projects) {
    // Filter projects based on search query
    var filtered = projects.where((project) {
      return project.projectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.startDestination.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.endDestination.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.projectStatus.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort projects if sort column is selected
    if (_sortColumn != null) {
      filtered.sort((a, b) {
        int compareResult;
        switch (_sortColumn) {
          case 'Project Name':
            compareResult = a.projectName.compareTo(b.projectName);
            break;
          case 'Start Destination':
            compareResult = a.startDestination.compareTo(b.startDestination);
            break;
          case 'End Destination':
            compareResult = a.endDestination.compareTo(b.endDestination);
            break;
          case 'Status':
            compareResult = a.projectStatus.compareTo(b.projectStatus);
            break;
          case 'Date':
            compareResult = a.startDate.compareTo(b.startDate);
            break;
          default:
            compareResult = 0;
        }
        return _sortAscending ? compareResult : -compareResult;
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (widget.projects.length / _rowsPerPage).ceil();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.95,
              child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 40,
                dataRowHeight: 50,
                columns: const [
                  DataColumn(label: Text("Project Name")),
                  DataColumn(label: Text("Start Destination")),
                  DataColumn(label: Text("End Destination")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Date")),
                ],
                rows: widget.projects
                    .skip(_currentPage * _rowsPerPage)
                    .take(_rowsPerPage)
                    .map((project) => DataRow(
                          cells: [
                            DataCell(
                              Text(project.projectName),
                              onTap: () => _navigateToProject(context, project.projectId),
                            ),
                            DataCell(Text(project.startDestination)),
                            DataCell(Text(project.endDestination)),
                            DataCell(_buildStatusBadge(project.projectStatus)),
                            DataCell(Text(_formatDate(project.startDate))),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Page ${_currentPage + 1} out of $totalPages"),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  child: const Text("Previous"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  child: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final Map<String, Color> statusColors = {
      'In Progress': Colors.blue,
      'Completed': Colors.green,
      'On Hold': Colors.orange,
      'Unstarted': Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColors[status] ?? Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}