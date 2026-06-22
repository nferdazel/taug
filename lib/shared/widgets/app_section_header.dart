import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AppSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    // A11Y: Mark as header for screen readers.
    return Semantics(
      header: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Text(title.toUpperCase(), style: AppTypography.monoSection),
            const Spacer(),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class AppWorkspaceHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final List<Widget>? badges;

  const AppWorkspaceHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.badges,
  });

  @override
  Widget build(BuildContext context) {
    // A11Y: Mark as header and build descriptive label.
    final String semanticLabel = subtitle != null
        ? '$title: $subtitle'
        : title;

    return Semantics(
      header: true,
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.heading),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.caption),
                  ],
                  if (badges != null && badges!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, children: badges!),
                  ],
                ],
              ),
            ),
            if (actions != null) ...[const SizedBox(width: 12), ...actions!],
          ],
        ),
      ),
    );
  }
}
