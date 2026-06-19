import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../watchlist/data/symbol_repository.dart';
import '../providers/portfolio_provider.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final _provider = PortfolioProvider();

  @override
  void initState() {
    super.initState();
    _provider.loadHoldings();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        _buildSummary(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: [
          const Text('PORTFOLIO', style: AppTypography.monoSection),
          const Spacer(),
          Watch((_) {
            final isLoading = _provider.isLoading.value;
            return SizedBox(
              height: 22,
              child: TextButton.icon(
                onPressed: () => _provider.loadPrices(),
                icon: isLoading
                    ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5))
                    : const Icon(Icons.refresh, size: 12),
                label: const Text('Refresh', style: AppTypography.monoMeta),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Watch((_) {
      final totalValue = _provider.totalValue;
      final totalPnL = _provider.totalPnL;
      final totalPnLPercent = _provider.totalPnLPercent;
      final isPositive = totalPnL >= 0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Value', style: AppTypography.monoMeta),
                Text(
                  '\$${totalValue.toStringAsFixed(2)}',
                  style: AppTypography.monoPrice,
                ),
              ],
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('P&L', style: AppTypography.monoMeta),
                Text(
                  '${isPositive ? '+' : ''}\$${totalPnL.toStringAsFixed(2)} (${isPositive ? '+' : ''}${totalPnLPercent.toStringAsFixed(2)}%)',
                  style: AppTypography.monoLabel.copyWith(
                    color: isPositive ? AppThemeColors.bullish : AppThemeColors.bearish,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 24,
              child: ElevatedButton.icon(
                onPressed: _showAddHoldingDialog,
                icon: const Icon(Icons.add, size: 12),
                label: const Text('Add', style: AppTypography.monoMeta),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildContent() {
    return Watch((_) {
      final holdings = _provider.holdings.value;
      final isLoading = _provider.isLoading.value;
      final error = _provider.error.value;

      if (isLoading && holdings.isEmpty) {
        return const Center(
          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      if (error != null && holdings.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 24, color: AppThemeColors.bearish),
              const SizedBox(height: 6),
              Text(error, style: AppTypography.caption),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _provider.loadHoldings, child: const Text(AppStrings.retry)),
            ],
          ),
        );
      }

      if (holdings.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 24, color: AppThemeColors.textTertiary),
              const SizedBox(height: 6),
              const Text('No holdings yet', style: AppTypography.caption),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _showAddHoldingDialog,
                icon: const Icon(Icons.add, size: 12),
                label: const Text('Add Holding'),
              ),
            ],
          ),
        );
      }

      return _buildHoldingsTable(holdings);
    });
  }

  Widget _buildHoldingsTable(List holdings) {
    return Column(
      children: [
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            color: AppThemeColors.backgroundLight,
            border: Border(bottom: BorderSide(color: AppThemeColors.border)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('Symbol', style: AppTypography.monoSection)),
              Expanded(flex: 1, child: Text('Qty', style: AppTypography.monoSection, textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('Avg Price', style: AppTypography.monoSection, textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('Price', style: AppTypography.monoSection, textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('Value', style: AppTypography.monoSection, textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('P&L', style: AppTypography.monoSection, textAlign: TextAlign.right)),
              SizedBox(width: 24),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: holdings.length,
            itemExtent: 32,
            itemBuilder: (context, index) => _buildHoldingRow(holdings[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildHoldingRow(dynamic holding) {
    return Watch((_) {
      final price = _provider.prices.value[holding.ticker];
      final currentPrice = price?.price ?? 0;
      final pnl = (currentPrice - holding.avgPrice) * holding.quantity;
      final pnlPercent = holding.avgPrice > 0
          ? ((currentPrice - holding.avgPrice) / holding.avgPrice) * 100
          : 0;
      final isPositive = pnl >= 0;

      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(holding.ticker ?? '-', style: AppTypography.monoLabel.copyWith(fontWeight: FontWeight.w600)),
                  Text(holding.name ?? '', style: AppTypography.monoMeta, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(holding.quantity.toString(), style: AppTypography.monoLabel, textAlign: TextAlign.right),
            ),
            Expanded(
              flex: 2,
              child: Text(holding.avgPrice.toStringAsFixed(2), style: AppTypography.monoLabel, textAlign: TextAlign.right),
            ),
            Expanded(
              flex: 2,
              child: Text(currentPrice.toStringAsFixed(2), style: AppTypography.monoData, textAlign: TextAlign.right),
            ),
            Expanded(
              flex: 2,
              child: Text(
                (currentPrice * holding.quantity).toStringAsFixed(2),
                style: AppTypography.monoData,
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${isPositive ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
                style: AppTypography.monoLabel.copyWith(
                  color: isPositive ? AppThemeColors.bullish : AppThemeColors.bearish,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: 24,
              child: IconButton(
                onPressed: () => _provider.removeHolding(holding.id),
                icon: const Icon(Icons.close, size: 12),
                padding: EdgeInsets.zero,
                color: AppThemeColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showAddHoldingDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddHoldingDialog(provider: _provider),
    );
  }
}

class _AddHoldingDialog extends StatefulWidget {
  final PortfolioProvider provider;

  const _AddHoldingDialog({required this.provider});

  @override
  State<_AddHoldingDialog> createState() => _AddHoldingDialogState();
}

class _AddHoldingDialogState extends State<_AddHoldingDialog> {
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppThemeColors.surface,
      title: const Text('Add Holding', style: AppTypography.subheading),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _symbolController,
              decoration: const InputDecoration(hintText: 'Symbol (e.g. AAPL)'),
              style: AppTypography.monoData,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(hintText: 'Quantity'),
              keyboardType: TextInputType.number,
              style: AppTypography.monoData,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(hintText: 'Avg Price'),
              keyboardType: TextInputType.number,
              style: AppTypography.monoData,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            final symbol = _symbolController.text.trim().toUpperCase();
            final qty = double.tryParse(_quantityController.text) ?? 0;
            final price = double.tryParse(_priceController.text) ?? 0;
            if (symbol.isNotEmpty && qty > 0 && price > 0) {
              final symbolRepo = SymbolRepository();
              final symbolId = await symbolRepo.getSymbolId(symbol);
              if (symbolId != null) {
                await widget.provider.addHolding(symbolId, qty, price);
              }
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
