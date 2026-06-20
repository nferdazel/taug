import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_state_widgets.dart';

class DataWorkspacePage extends StatelessWidget {
  const DataWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.storage_outlined,
      title: 'Data',
      description: 'Data quality, freshness, sources, and trust indicators. This workspace is not yet implemented.',
    );
  }
}
