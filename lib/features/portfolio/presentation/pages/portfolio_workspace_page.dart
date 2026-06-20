import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_state_widgets.dart';

class PortfolioWorkspacePage extends StatelessWidget {
  const PortfolioWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Portfolio',
      description: 'Track positions, theses, and investment decisions. This workspace is not yet implemented.',
    );
  }
}
