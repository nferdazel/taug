import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_badge.dart';

enum ResearchStatus {
  notResearched(label: 'Not Researched', colorValue: 0xFF71717A, icon: null),
  queued(label: 'Queued', colorValue: 0xFFF59E0B, icon: Icons.queue),
  researching(label: 'Researching', colorValue: 0xFF3B82F6, icon: Icons.edit_note),
  watchlist(label: 'Watchlist', colorValue: 0xFFA78BFA, icon: Icons.visibility),
  portfolio(label: 'Portfolio', colorValue: 0xFF10B981, icon: Icons.account_balance_wallet);

  final String label;
  final int colorValue;
  final IconData? icon;

  const ResearchStatus({required this.label, required this.colorValue, this.icon});

  Color get color => Color(colorValue);

  static ResearchStatus fromString(String? value) {
    switch (value) {
      case 'queued':
        return ResearchStatus.queued;
      case 'researching':
        return ResearchStatus.researching;
      case 'watchlist':
        return ResearchStatus.watchlist;
      case 'portfolio':
        return ResearchStatus.portfolio;
      default:
        return ResearchStatus.notResearched;
    }
  }
}

class ResearchStatusBadge extends StatelessWidget {
  final ResearchStatus status;

  const ResearchStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: status.label,
      color: status.color,
      icon: status.icon,
    );
  }
}
