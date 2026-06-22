import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/schema/app_schema.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_sanitizer.dart';

class ValuationPage extends StatefulWidget {
  const ValuationPage({super.key});

  @override
  State<ValuationPage> createState() => _ValuationPageState();
}

class _ValuationPageState extends State<ValuationPage> {
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from(AppSchema.companyMetricSnapshot)
          .select()
          .order('metric_code');

      setState(() {
        _rows = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorSanitizer.message(e);
        _isLoading = false;
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> get _metricsByCompany {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final row in _rows) {
      final companyId = row['company_id'] as String? ?? '';
      map.putIfAbsent(companyId, () => []).add(row);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildToolbar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: <Widget>[
          const Text('VALUATION SNAPSHOT', style: AppTypography.monoSection),
          const Spacer(),
          Text(
            '${_metricsByCompany.length} companies',
            style: AppTypography.monoTiny.copyWith(
              color: AppThemeColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: 24,
            height: 28,
            child: IconButton(
              onPressed: _loadData,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.refresh, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: AppTypography.bodySmall),
      );
    }

    final byCompany = _metricsByCompany;
    if (byCompany.isEmpty) {
      return const Center(
        child: Text('No metrics computed yet', style: AppTypography.caption),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      itemCount: byCompany.length,
      itemBuilder: (BuildContext context, int index) {
        final companyId = byCompany.keys.elementAt(index);
        final metrics = byCompany[companyId]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
          child: _buildCompanyCard(metrics),
        );
      },
    );
  }

  Widget _buildCompanyCard(List<Map<String, dynamic>> metrics) {
    final first = metrics.first;
    final displayName = first['display_name'] as String? ?? '';
    final ticker = first['primary_ticker'] as String? ?? '';

    final valuationMetrics = metrics
        .where((m) => m['metric_category'] == 'valuation')
        .toList();
    final scaleMetrics = metrics
        .where((m) => m['metric_category'] == 'scale')
        .toList();
    final profitabilityMetrics = metrics
        .where((m) => m['metric_category'] == 'profitability')
        .toList();
    final leverageMetrics = metrics
        .where((m) => m['metric_category'] == 'leverage')
        .toList();
    final cashFlowMetrics = metrics
        .where((m) => m['metric_category'] == 'cash_flow')
        .toList();
    final growthMetrics = metrics
        .where((m) => m['metric_category'] == 'growth')
        .toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppThemeColors.backgroundLight,
              border: Border(bottom: BorderSide(color: AppThemeColors.border)),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  ticker,
                  style: AppTypography.monoData.copyWith(
                    color: AppThemeColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(displayName, style: AppTypography.subheading),
              ],
            ),
          ),
          _buildMetricSection('VALUATION', valuationMetrics),
          _buildMetricSection('PROFITABILITY', profitabilityMetrics),
          _buildMetricSection('LEVERAGE', leverageMetrics),
          _buildMetricSection('CASH FLOW', cashFlowMetrics),
          _buildMetricSection('GROWTH', growthMetrics),
          _buildMetricSection('SCALE', scaleMetrics),
        ],
      ),
    );
  }

  Widget _buildMetricSection(String title, List<Map<String, dynamic>> metrics) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTypography.monoSection.copyWith(fontSize: 10)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: metrics.map((m) => _buildMetricChip(m)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(Map<String, dynamic> metric) {
    final code = metric['metric_code'] as String? ?? '';
    final value = metric['value_numeric'] as num?;
    final status = metric['computation_status'] as String? ?? 'missing_input';

    final bool isOk = status == 'ok';
    final bool isMissing = status == 'missing_input';

    String displayValue;
    if (!isOk || value == null) {
      displayValue = '--';
    } else if (code == 'market_cap' || code == 'enterprise_value' || code == 'fcf') {
      displayValue = _formatLargeNumber(value.toDouble());
    } else if (['gross_margin', 'operating_margin', 'net_margin', 'roe', 'roa',
                'fcf_margin', 'revenue_yoy', 'eps_yoy'].contains(code)) {
      displayValue = '${(value.toDouble() * 100).toStringAsFixed(1)}%';
    } else {
      displayValue = value.toDouble().toStringAsFixed(2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isOk ? null : AppThemeColors.backgroundLight.withAlpha(50),
        border: Border.all(
          color: isOk ? AppThemeColors.border : AppThemeColors.border.withAlpha(100),
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _formatCode(code),
            style: AppTypography.monoTiny.copyWith(
              color: AppThemeColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            displayValue,
            style: AppTypography.monoData.copyWith(
              color: isOk
                  ? AppThemeColors.textPrimary
                  : AppThemeColors.textTertiary,
            ),
          ),
          if (isMissing) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.info_outline,
              size: 10,
              color: AppThemeColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  String _formatCode(String code) {
    return code.toUpperCase().replaceAll('_', ' ');
  }

  String _formatLargeNumber(double v) {
    if (v.abs() >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T';
    if (v.abs() >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    return v.toStringAsFixed(0);
  }
}
