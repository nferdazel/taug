import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../../companies/presentation/widgets/research_status_badge.dart';
import '../../data/research_models.dart';
import '../providers/research_provider.dart';

class ResearchWorkspacePage extends StatefulWidget {
  const ResearchWorkspacePage({super.key});

  @override
  State<ResearchWorkspacePage> createState() => _ResearchWorkspacePageState();
}

class _ResearchWorkspacePageState extends State<ResearchWorkspacePage> {
  late final ResearchProvider _provider;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = ResearchProvider();
    _provider.loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Watch((_) {
      final totalResearch = _provider.researchCompanies.length;
      final totalTheses = _provider.theses.length;
      final totalNotes = _provider.notes.length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Research', style: AppTypography.heading),
            const SizedBox(height: 2),
            Text(
              '$totalResearch companies · $totalTheses theses · $totalNotes notes',
              style: AppTypography.caption,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabBar() {
    return Watch((_) {
      return Container(
        height: 36,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
        ),
        child: Row(
          children: [
            _TabButton(
              label: 'Queue',
              selected: _provider.activeTab.value == 0,
              onTap: () => _provider.activeTab.value = 0,
            ),
            _TabButton(
              label: 'Theses',
              selected: _provider.activeTab.value == 1,
              onTap: () => _provider.activeTab.value = 1,
            ),
            _TabButton(
              label: 'Notes',
              selected: _provider.activeTab.value == 2,
              onTap: () => _provider.activeTab.value = 2,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildContent() {
    return Watch((_) {
      if (_provider.isLoading.value) {
        return const AppLoadingState(message: 'Loading research...');
      }

      return Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildTabContent()),
        ],
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 32,
        child: TextField(
          controller: _searchController,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: 'Search companies, theses, notes...',
            hintStyle: AppTypography.caption,
            prefixIcon: const Icon(Icons.search, size: 16),
            prefixIconColor: AppThemeColors.textTertiary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppThemeColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppThemeColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppThemeColors.accent),
            ),
            filled: true,
            fillColor: AppThemeColors.surfaceMuted,
          ),
          onChanged: (v) => _provider.setSearchQuery(v),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_provider.activeTab.value) {
      case 0:
        return _buildQueueView();
      case 1:
        return _buildThesesView();
      case 2:
        return _buildNotesView();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQueueView() {
    return Watch((_) {
      final companies = _provider.filteredCompanies;

      if (companies.isEmpty) {
        return const AppEmptyState(
          icon: Icons.edit_note_outlined,
          title: 'No active research',
          description: 'Start researching companies from the Companies page. Notes and theses will appear here.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: companies.length,
        itemBuilder: (context, index) {
          final company = companies[index];
          return _CompanyResearchCard(
            company: company,
            onTap: () => context.go('/companies/${company.companyId}'),
          );
        },
      );
    });
  }

  Widget _buildThesesView() {
    return Watch((_) {
      final theses = _provider.filteredTheses;

      if (theses.isEmpty) {
        return const AppEmptyState(
          icon: Icons.lightbulb_outline,
          title: 'No theses yet',
          description: 'Create investment theses from company research pages.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: theses.length,
        itemBuilder: (context, index) {
          final thesis = theses[index];
          return _ThesisIndexCard(
            thesis: thesis,
            onTap: () => context.go('/companies/${thesis.companyId}'),
          );
        },
      );
    });
  }

  Widget _buildNotesView() {
    return Watch((_) {
      final notes = _provider.filteredNotes;

      if (notes.isEmpty) {
        return const AppEmptyState(
          icon: Icons.note_outlined,
          title: 'No notes yet',
          description: 'Create research notes from company research pages.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _NoteIndexCard(
            note: note,
            onTap: () => context.go('/companies/${note.companyId}'),
          );
        },
      );
    });
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppThemeColors.accent : Colors.transparent,
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
              color: selected ? AppThemeColors.textPrimary : AppThemeColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyResearchCard extends StatelessWidget {
  final ResearchCompany company;
  final VoidCallback onTap;

  const _CompanyResearchCard({required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppThemeColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.displayName,
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                      ),
                      if (company.ticker != null)
                        Text(
                          company.ticker!,
                          style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ResearchStatusBadge(
                      status: ResearchStatus.fromString(company.researchStatus),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${company.notesCount} notes · ${company.thesesCount} theses',
                      style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 16, color: AppThemeColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThesisIndexCard extends StatelessWidget {
  final ResearchThesisIndex thesis;
  final VoidCallback onTap;

  const _ThesisIndexCard({required this.thesis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppThemeColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thesis.title,
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${thesis.companyName}${thesis.ticker != null ? " (${thesis.ticker})" : ""}',
                        style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                _StanceChip(stance: thesis.stance),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 16, color: AppThemeColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteIndexCard extends StatelessWidget {
  final ResearchNoteIndex note;
  final VoidCallback onTap;

  const _NoteIndexCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppThemeColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${note.companyName}${note.ticker != null ? " (${note.ticker})" : ""}',
                        style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                      ),
                      if (note.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          note.body,
                          style: AppTypography.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 16, color: AppThemeColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StanceChip extends StatelessWidget {
  final String stance;

  const _StanceChip({required this.stance});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (stance) {
      case 'bullish':
        color = AppThemeColors.success;
        label = 'Bullish';
        break;
      case 'bearish':
        color = AppThemeColors.critical;
        label = 'Bearish';
        break;
      default:
        color = AppThemeColors.neutral;
        label = 'Neutral';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
