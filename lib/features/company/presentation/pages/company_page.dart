import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/company_models.dart';
import '../../data/company_repository.dart';
import '../providers/company_provider.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({super.key});

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  late final CompanyProvider _provider;
  final Signal<List<Map<String, dynamic>>> _companies = Signal<List<Map<String, dynamic>>>([]);
  final Signal<String> _searchQuery = Signal<String>('');
  final Signal<List<StatementItem>> _drillDownItems = Signal<List<StatementItem>>([]);
  final Signal<String?> _drillDownPeriod = Signal<String?>(null);
  final Signal<String?> _drillDownType = Signal<String?>(null);
  final Signal<bool> _isLoadingDrillDown = Signal<bool>(false);

  @override
  void initState() {
    super.initState();
    _provider = CompanyProvider();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    final client = Supabase.instance.client;
    final response = await client
        .from('company_research_summary_v')
        .select('company_id, display_name, primary_ticker, cik')
        .order('display_name');
    if (response.isNotEmpty && mounted) {
      _companies.value = List<Map<String, dynamic>>.from(response);
      _provider.loadCompany(response[0]['company_id'] as String);
    }
  }

  void _selectCompany(Map<String, dynamic> company) {
    _provider.loadCompany(company['company_id'] as String);
    _searchQuery.value = '';
    _drillDownItems.value = [];
    _drillDownPeriod.value = null;
    _drillDownType.value = null;
  }

  Future<void> _loadStatementItems({
    required String statementType,
    required String periodEnd,
  }) async {
    _drillDownType.value = statementType;
    _drillDownPeriod.value = periodEnd;
    _isLoadingDrillDown.value = true;

    final companyId = _provider.selectedCompanyId.value;
    if (companyId == null) {
      _isLoadingDrillDown.value = false;
      return;
    }

    final result = await CompanyRepository().getStatementItems(
      companyId: companyId,
      statementType: statementType,
      periodEnd: periodEnd,
    );

    if (result.isSuccess) {
      _drillDownItems.value = result.data!;
    }
    _isLoadingDrillDown.value = false;
  }

  void _clearDrillDown() {
    _drillDownItems.value = [];
    _drillDownPeriod.value = null;
    _drillDownType.value = null;
  }

  void _showCompanyPicker() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return _CompanyPickerDialog(
          companies: _companies.value,
          onSelect: _selectCompany,
        );
      },
    );
  }

  @override
  void dispose() {
    _provider.dispose();
    _companies.dispose();
    _searchQuery.dispose();
    _drillDownItems.dispose();
    _drillDownPeriod.dispose();
    _drillDownType.dispose();
    _isLoadingDrillDown.dispose();
    super.dispose();
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
    return Watch((_) {
      final CompanyFullProfile? p = _provider.profile.value;
      final bool isLoading = _provider.isLoading.value;

      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border)),
        ),
        child: Row(
          children: <Widget>[
            const Text('COMPANY RESEARCH', style: AppTypography.monoSection),
            const SizedBox(width: AppSpacing.lg),
            InkWell(
              onTap: _showCompanyPicker,
              child: Row(
                children: <Widget>[
                  if (p != null) ...<Widget>[
                    Text(
                      p.summary.primaryTicker ?? '',
                      style: AppTypography.monoData.copyWith(
                        color: AppThemeColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(p.summary.displayName, style: AppTypography.subheading),
                    if (p.summary.cik != null) ...<Widget>[
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'CIK ${p.summary.cik}',
                        style: AppTypography.monoTiny.copyWith(
                          color: AppThemeColors.textTertiary,
                        ),
                      ),
                    ],
                  ] else
                    Text(
                      'Select company',
                      style: AppTypography.caption.copyWith(
                        color: AppThemeColors.textTertiary,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.unfold_more,
                    size: 12,
                    color: AppThemeColors.textTertiary,
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildContent() {
    return Watch((_) {
      final CompanyFullProfile? p = _provider.profile.value;
      final bool isLoading = _provider.isLoading.value;
      final String? error = _provider.error.value;

      if (isLoading && p == null) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (error != null && p == null) {
        return Center(
          child: Text(error, style: AppTypography.bodySmall),
        );
      }

      if (p == null) {
        return const Center(
          child: Text('Select a company', style: AppTypography.caption),
        );
      }

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth < 768) {
            return _buildMobileLayout(p);
          }
          return _buildDesktopLayout(p);
        },
      );
    });
  }

  Widget _buildDesktopLayout(CompanyFullProfile p) {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 360,
                child: Column(
                  children: <Widget>[
                    Expanded(child: _buildMetricsPanel(p)),
                    const SizedBox(height: 1),
                    SizedBox(height: 180, child: _buildQualityPanel(p)),
                  ],
                ),
              ),
              const SizedBox(width: 1),
              Expanded(child: _buildStatementsPanel(p)),
            ],
          ),
        ),
        Watch((_) {
          final items = _drillDownItems.value;
          final period = _drillDownPeriod.value;
          final type = _drillDownType.value;
          if (items.isEmpty || period == null || type == null) {
            return const SizedBox.shrink();
          }
          return SizedBox(
            height: 220,
            child: _buildDrillDownPanel(items, period, type),
          );
        }),
      ],
    );
  }

  Widget _buildMobileLayout(CompanyFullProfile p) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      children: <Widget>[
        SizedBox(height: 280, child: _buildMetricsPanel(p)),
        const SizedBox(height: AppSpacing.sectionGap),
        SizedBox(height: 160, child: _buildQualityPanel(p)),
        const SizedBox(height: AppSpacing.sectionGap),
        SizedBox(height: 400, child: _buildStatementsPanel(p)),
      ],
    );
  }

  Widget _buildMetricsPanel(CompanyFullProfile p) {
    return _buildPanel(
      title: 'KEY METRICS',
      subtitle: '${p.metrics.where((m) => m.computationStatus == 'ok').length} computed',
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: p.metrics.length,
        itemExtent: 28,
        itemBuilder: (BuildContext context, int index) {
          final CompanyMetricSnapshot m = p.metrics[index];
          return _buildMetricRow(m);
        },
      ),
    );
  }

  Widget _buildMetricRow(CompanyMetricSnapshot m) {
    final bool isOk = m.computationStatus == 'ok';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemeColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              m.metricName,
              style: AppTypography.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isOk ? _formatMetricValue(m) : '--',
              textAlign: TextAlign.right,
              style: isOk ? AppTypography.monoData : AppTypography.monoMeta,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 50,
            child: _buildStatusChip(m.computationStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'ok':
        color = AppThemeColors.bullish;
      case 'missing_input':
        color = AppThemeColors.textTertiary;
      case 'stale_input':
        color = AppThemeColors.warning;
      default:
        color = AppThemeColors.bearish;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.monoTiny.copyWith(
          color: color,
          fontSize: 9,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatMetricValue(CompanyMetricSnapshot m) {
    if (m.valueNumeric == null) return '--';
    final double v = m.valueNumeric!;
    switch (m.metricCategory) {
      case 'profitability':
      case 'leverage':
      case 'cash_flow':
        if (m.metricCode == 'fcf') {
          return _formatLargeNumber(v);
        }
        return '${(v * 100).toStringAsFixed(1)}%';
      case 'valuation':
        return v.toStringAsFixed(2);
      case 'scale':
        return _formatLargeNumber(v);
      case 'growth':
        return '${(v * 100).toStringAsFixed(1)}%';
      default:
        return v.toStringAsFixed(2);
    }
  }

  String _formatLargeNumber(double v) {
    final NumberFormat fmt = NumberFormat.compact();
    return fmt.format(v);
  }

  Widget _buildQualityPanel(CompanyFullProfile p) {
    final CompanyDataQuality q = p.quality;
    return _buildPanel(
      title: 'DATA QUALITY',
      subtitle: q.statementFreshness,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: <Widget>[
            _buildQualityRow('Filings', '${q.totalFilings} total, ${q.annualQuarterlyFilings} 10-K/Q'),
            _buildQualityRow('Statements', '${q.totalStatements} total, ${q.statementTypesCovered} types'),
            _buildQualityRow('Fact Items', '${q.totalFactItems}'),
            _buildQualityRow('Freshness', q.statementFreshness),
            _buildQualityRow('Validation', q.validationHealthStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 80,
            child: Text(label, style: AppTypography.monoTiny),
          ),
          Expanded(
            child: Text(value, style: AppTypography.monoData),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementsPanel(CompanyFullProfile p) {
    final List<CompanyStatementRow> incomeRows = p.statements
        .where((s) => s.statementType == 'income_statement')
        .toList();
    final List<CompanyStatementRow> balanceRows = p.statements
        .where((s) => s.statementType == 'balance_sheet')
        .toList();
    final List<CompanyStatementRow> cashFlowRows = p.statements
        .where((s) => s.statementType == 'cash_flow')
        .toList();

    return _buildPanel(
      title: 'STATEMENT HISTORY',
      subtitle: '${p.statements.length} periods',
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: <Widget>[
            Container(
              height: 28,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppThemeColors.border)),
              ),
              child: TabBar(
                labelStyle: AppTypography.monoTiny.copyWith(fontSize: 10),
                unselectedLabelStyle: AppTypography.monoTiny.copyWith(fontSize: 10),
                labelColor: AppThemeColors.accent,
                unselectedLabelColor: AppThemeColors.textTertiary,
                indicatorColor: AppThemeColors.accent,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const <Tab>[
                  Tab(text: 'INCOME'),
                  Tab(text: 'BALANCE'),
                  Tab(text: 'CASH FLOW'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _buildStatementTable(incomeRows, isIncome: true),
                  _buildStatementTable(balanceRows, isBalance: true),
                  _buildStatementTable(cashFlowRows, isCashFlow: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementTable(
    List<CompanyStatementRow> rows, {
    bool isIncome = false,
    bool isBalance = false,
    bool isCashFlow = false,
  }) {
    if (rows.isEmpty) {
      return const Center(
        child: Text('No data', style: AppTypography.caption),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: isIncome ? 700 : isBalance ? 500 : 500,
        child: Column(
          children: <Widget>[
            _buildTableHeader(rows, isIncome: isIncome, isBalance: isBalance, isCashFlow: isCashFlow),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemExtent: 28,
                itemBuilder: (BuildContext context, int index) {
                  return _buildTableRow(
                    rows[index],
                    isIncome: isIncome,
                    isBalance: isBalance,
                    isCashFlow: isCashFlow,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(
    List<CompanyStatementRow> rows, {
    bool isIncome = false,
    bool isBalance = false,
    bool isCashFlow = false,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppThemeColors.backgroundLight,
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: <Widget>[
          _buildHeaderCell('PERIOD', 100),
          if (isIncome) ...<Widget>[
            _buildHeaderCell('REVENUE', 80),
            _buildHeaderCell('GROSS PR', 80),
            _buildHeaderCell('OP INC', 80),
            _buildHeaderCell('NET INC', 80),
            _buildHeaderCell('EPS', 60),
          ],
          if (isBalance) ...<Widget>[
            _buildHeaderCell('ASSETS', 80),
            _buildHeaderCell('EQUITY', 80),
            _buildHeaderCell('DEBT', 80),
            _buildHeaderCell('CASH', 80),
          ],
          if (isCashFlow) ...<Widget>[
            _buildHeaderCell('OCF', 80),
            _buildHeaderCell('CAPEX', 80),
            _buildHeaderCell('FCF', 80),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(label, style: AppTypography.monoSection.copyWith(fontSize: 10)),
    );
  }

  Widget _buildTableRow(
    CompanyStatementRow row, {
    bool isIncome = false,
    bool isBalance = false,
    bool isCashFlow = false,
  }) {
    final String periodLabel = _formatPeriod(row);
    return RepaintBoundary(
      child: InkWell(
        onTap: () => _loadStatementItems(
          statementType: row.statementType,
          periodEnd: row.periodEnd,
        ),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppThemeColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: <Widget>[
              _buildDataCell(periodLabel, 100, isBold: true),
              if (isIncome) ...<Widget>[
                _buildDataCell(_fmtMoney(row.revenue), 80),
                _buildDataCell(_fmtMoney(row.grossProfit), 80),
                _buildDataCell(_fmtMoney(row.operatingIncome), 80),
                _buildDataCell(_fmtMoney(row.netIncome), 80),
                _buildDataCell(_fmtNum(row.epsDiluted), 60),
              ],
              if (isBalance) ...<Widget>[
                _buildDataCell(_fmtMoney(row.totalAssets), 80),
                _buildDataCell(_fmtMoney(row.stockholdersEquity), 80),
                _buildDataCell(_fmtMoney(row.longTermDebt), 80),
                _buildDataCell(_fmtMoney(row.cashAndEquivalents), 80),
              ],
              if (isCashFlow) ...<Widget>[
                _buildDataCell(_fmtMoney(row.operatingCashFlow), 80),
                _buildDataCell(_fmtMoney(row.capex), 80),
                _buildDataCell(
                  row.operatingCashFlow != null && row.capex != null
                      ? _fmtMoney(row.operatingCashFlow! - row.capex!.abs())
                      : '--',
                  80,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(String value, double width, {bool isBold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: isBold ? AppTypography.monoData : AppTypography.monoMeta,
        textAlign: TextAlign.right,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatPeriod(CompanyStatementRow row) {
    final DateTime? end = DateTime.tryParse(row.periodEnd);
    if (end == null) return row.periodEnd;
    if (row.statementType == 'income_statement' ||
        row.statementType == 'cash_flow') {
      final DateTime? start = row.periodStart != null
          ? DateTime.tryParse(row.periodStart!)
          : null;
      if (start != null) {
        final int days = end.difference(start).inDays;
        if (days >= 300) {
          return 'FY${end.year}';
        }
        final int quarter = ((start.month - 1) ~/ 3) + 1;
        return 'Q$quarter ${end.year}';
      }
    }
    return DateFormat('MMM yyyy').format(end);
  }

  String _fmtMoney(double? v) {
    if (v == null) return '--';
    if (v.abs() >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    return v.toStringAsFixed(0);
  }

  String _fmtNum(double? v) {
    if (v == null) return '--';
    return v.toStringAsFixed(2);
  }

  Widget _buildPanel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppThemeColors.backgroundLight,
              border: Border(bottom: BorderSide(color: AppThemeColors.border)),
            ),
            child: Row(
              children: <Widget>[
                Text(title, style: AppTypography.monoSection),
                const SizedBox(width: AppSpacing.lg),
                Text(
                  subtitle,
                  style: AppTypography.monoTiny.copyWith(
                    color: AppThemeColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDrillDownPanel(
    List<StatementItem> items,
    String periodEnd,
    String statementType,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppThemeColors.backgroundLight,
              border: Border(bottom: BorderSide(color: AppThemeColors.border)),
            ),
            child: Row(
              children: <Widget>[
                const Text('LINE ITEMS', style: AppTypography.monoSection),
                const SizedBox(width: AppSpacing.lg),
                Text(
                  '$statementType — $periodEnd — ${items.length} items',
                  style: AppTypography.monoTiny.copyWith(
                    color: AppThemeColors.textTertiary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _clearDrillDown,
                  child: const Icon(Icons.close, size: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemExtent: 24,
              itemBuilder: (BuildContext context, int index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppThemeColors.border,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.taxonomyName ?? item.taxonomyCode ?? '',
                          style: AppTypography.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.valueNumeric != null
                              ? _fmtMoney(item.valueNumeric)
                              : '--',
                          textAlign: TextAlign.right,
                          style: AppTypography.monoData,
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          item.unit ?? '',
                          textAlign: TextAlign.right,
                          style: AppTypography.monoMeta,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyPickerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> companies;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _CompanyPickerDialog({
    required this.companies,
    required this.onSelect,
  });

  @override
  State<_CompanyPickerDialog> createState() => _CompanyPickerDialogState();
}

class _CompanyPickerDialogState extends State<_CompanyPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.companies;
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = widget.companies.where((c) {
        final name = (c['display_name'] as String? ?? '').toLowerCase();
        final ticker = (c['primary_ticker'] as String? ?? '').toLowerCase();
        final cik = (c['cik'] as String? ?? '').toLowerCase();
        return name.contains(q) || ticker.contains(q) || cik.contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppThemeColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppThemeColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: <Widget>[
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppThemeColors.border)),
              ),
              child: Row(
                children: <Widget>[
                  const Text('SELECT COMPANY', style: AppTypography.monoSection),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, size: 14),
                    color: AppThemeColors.textTertiary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: AppTypography.monoData,
                decoration: const InputDecoration(
                  hintText: 'Search by name, ticker, or CIK...',
                  hintStyle: AppTypography.monoMeta,
                  prefixIcon: Icon(Icons.search, size: 14),
                  prefixIconColor: AppThemeColors.textTertiary,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.accent),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemExtent: 32,
                itemBuilder: (BuildContext context, int index) {
                  final company = _filtered[index];
                  final name = company['display_name'] as String? ?? '';
                  final ticker = company['primary_ticker'] as String? ?? '';
                  final cik = company['cik'] as String? ?? '';
                  return InkWell(
                    onTap: () {
                      widget.onSelect(company);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppThemeColors.border,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 60,
                            child: Text(
                              ticker,
                              style: AppTypography.monoData.copyWith(
                                color: AppThemeColors.accent,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              name,
                              style: AppTypography.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            cik,
                            style: AppTypography.monoMeta,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
