import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_state_widgets.dart';

class CompanyWorkspacePage extends StatelessWidget {
  final String companyId;

  const CompanyWorkspacePage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header placeholder
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
          ),
          child: Row(
            children: [
              const Text('Company Workspace', style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
              const SizedBox(width: 8),
              Text('($companyId)', style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              )),
            ],
          ),
        ),
        // Tab bar placeholder
        Container(
          height: 36,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
          ),
          child: const Row(
            children: [
              _TabButton(label: 'Overview', selected: true),
              _TabButton(label: 'Financials', selected: false),
              _TabButton(label: 'Research', selected: false),
            ],
          ),
        ),
        // Content
        const Expanded(
          child: AppEmptyState(
            icon: Icons.business_outlined,
            title: 'Company Workspace',
            description: 'Company research workspace is not yet implemented.',
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;

  const _TabButton({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
