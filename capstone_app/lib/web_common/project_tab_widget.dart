import 'package:flutter/material.dart';

class ProjectTabWidget extends StatelessWidget {
  final int selectedTabIndex;
  final Function(int) onTabSelected;
  final List<String> tabTitles;

  const ProjectTabWidget({
    super.key,
    required this.selectedTabIndex,
    required this.onTabSelected,
    this.tabTitles = const ["Offsite Checklist", "MS/RA Generation", "Onsite Checklist"],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(tabTitles.length, (index) {
          return _buildTab(
            context: context,
            title: tabTitles[index],
            index: index,
            isSmallScreen: isSmallScreen,
          );
        }),
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required String title,
    required int index,
    required bool isSmallScreen,
  }) {
    final theme = Theme.of(context);
    final isSelected = index == selectedTabIndex;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onTabSelected(index),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 10 : 12,
                horizontal: isSmallScreen ? 4 : 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}