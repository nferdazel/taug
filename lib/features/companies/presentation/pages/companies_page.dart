import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_state_widgets.dart';

class CompaniesPage extends StatelessWidget {
  const CompaniesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.business_outlined,
      title: 'Companies Workspace',
      description: 'Browse and discover companies for research. This workspace is not yet implemented.',
    );
  }
}
