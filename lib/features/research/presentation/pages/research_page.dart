import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_state_widgets.dart';

class ResearchPage extends StatelessWidget {
  const ResearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.edit_note_outlined,
      title: 'Research Workspace',
      description: 'Notes, theses, and research workflow. This workspace is not yet implemented.',
    );
  }
}
