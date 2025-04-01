import 'package:flutter/material.dart';
import '../web_common/sidebar_widget.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use responsive layout based on screen width
          final bool isMobile = constraints.maxWidth < 600;
          
          return Row(
            children: [
              // Sidebar - hidden on mobile if needed
              if (!isMobile) Sidebar(selectedPage: '/dashboard'),

              // Main Dashboard Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 10.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Text
                      Text(
                        "Welcome, user!",
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "HSE Officer, ID: 123456",
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Top Row: Summary Cards - stack vertically on mobile
                      isMobile
                          ? Column(
                              children: [
                                _buildSummaryCard(
                                  title: "Current Projects",
                                  count: 3,
                                  icon: Icons.work,
                                  isMobile: isMobile,
                                ),
                                SizedBox(height: 10),
                                _buildSummaryCard(
                                  title: "Current Tasks",
                                  count: 5,
                                  icon: Icons.task,
                                  isMobile: isMobile,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    title: "Current Projects",
                                    count: 3,
                                    icon: Icons.work,
                                    isMobile: isMobile,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: _buildSummaryCard(
                                    title: "Current Tasks",
                                    count: 5,
                                    icon: Icons.task,
                                    isMobile: isMobile,
                                  ),
                                ),
                              ],
                            ),
                      SizedBox(height: 20),

                      // Main Content: Project Directory + Task List
                      // Stack vertically on mobile
                      Expanded(
                        child: isMobile
                            ? SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildProjectDirectory(isMobile: isMobile),
                                    SizedBox(height: 20),
                                    _buildTaskList(isMobile: isMobile),
                                  ],
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Project Directory
                                  Expanded(
                                    flex: 2,
                                    child: _buildProjectDirectory(
                                        isMobile: isMobile),
                                  ),
                                  SizedBox(width: 20),
                                  // Task List
                                  Expanded(
                                    flex: 3,
                                    child: _buildTaskList(isMobile: isMobile),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🔹 Summary Card (Current Projects & Tasks)
  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isMobile ? 30 : 40, color: Colors.orange),
          SizedBox(height: isMobile ? 5 : 10),
          Text(title, style: TextStyle(fontSize: isMobile ? 14 : 16)),
          SizedBox(height: isMobile ? 3 : 5),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Project Directory Widget
  Widget _buildProjectDirectory({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Project Directory",
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          _buildProjectItem("Project 1", isActive: true, isMobile: isMobile),
          _buildProjectItem("Project 2", isMobile: isMobile),
          _buildProjectItem("Project 5", isMobile: isMobile),
          _buildProjectItem("Project 4", isOnHold: true, isMobile: isMobile),
        ],
      ),
    );
  }

  // 🔹 Individual Project Item
  Widget _buildProjectItem(
    String projectName, {
    bool isActive = false,
    bool isOnHold = false,
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 3 : 5),
      child: Row(
        children: [
          Icon(Icons.device_hub, color: Colors.grey.shade700),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              projectName,
              style: TextStyle(fontSize: isMobile ? 14 : 16),
            ),
          ),
          if (isActive)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 6 : 8, vertical: isMobile ? 2 : 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                "Currently Working",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ),
          if (isOnHold)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 6 : 8,
                vertical: isMobile ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                "On Hold",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🔹 Task List Widget
  Widget _buildTaskList({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Task List",
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          _buildTaskItem(
            "Project 2 - Onsite Checklist",
            "Ensure All Safety Protocols Are In Place",
            isMobile: isMobile,
          ),
          _buildTaskItem(
            "Project 1 - Approvals",
            "Re-Upload Of MSRA",
            isMobile: isMobile,
          ),
          _buildTaskItem(
            "Project 1 - Approvals",
            "Approval Of MSRA",
            isMobile: isMobile,
          ),
          _buildTaskItem(
            "Project 1 - Approvals",
            "Approval Of MSRA",
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  // 🔹 Task Item Widget
  Widget _buildTaskItem(String title, String subtitle, {required bool isMobile}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isMobile ? 3 : 5),
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (value) {},
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: isMobile ? 14 : 18,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}