import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/data_origin.dart';
import '../../../../shared/widgets/data_status_badge.dart';
import '../providers/market_provider.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final _provider = MarketProvider();

  @override
  void initState() {
    super.initState();
    _provider.loadMovers();
    _provider.startAutoRefresh();
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
          const Text('MARKET MOVERS', style: AppTypography.monoSection),
          const SizedBox(width: 8),
          const DataStatusBadge(origin: _marketOrigin),
          const Spacer(),
          Watch((_) {
            if (_provider.lastUpdated.value != null) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'Updated ${_provider.lastUpdated.value!.minute}:${_provider.lastUpdated.value!.second.toString().padLeft(2, '0')}',
                  style: AppTypography.monoMeta,
                ),
              );
            }
            return const SizedBox();
          }),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Watch((_) {
      final movers = _provider.movers.value;
      final isLoading = _provider.isLoading.value;
      final error = _provider.error.value;

      if (isLoading && movers.isEmpty) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (error != null && movers.isEmpty) {
        return Center(child: Text(error, style: AppTypography.caption));
      }

      if (movers.isEmpty) {
        return const Center(
          child: Text('No data available', style: AppTypography.caption),
        );
      }

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
                Expanded(
                  flex: 2,
                  child: Text('Symbol', style: AppTypography.monoSection),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Name', style: AppTypography.monoSection),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Price',
                    style: AppTypography.monoSection,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Change',
                    style: AppTypography.monoSection,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Change %',
                    style: AppTypography.monoSection,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: movers.length,
              itemExtent: 32,
              itemBuilder: (context, index) {
                final item = movers[index];
                final isPositive = item.changePercent >= 0;

                return Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppThemeColors.border,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.symbol,
                          style: AppTypography.monoLabel.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.symbol,
                          style: AppTypography.monoMeta,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.price.toStringAsFixed(2),
                          style: AppTypography.monoData,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${isPositive ? '+' : ''}${item.change.toStringAsFixed(2)}',
                          style: AppTypography.monoLabel.copyWith(
                            color: isPositive
                                ? AppThemeColors.bullish
                                : AppThemeColors.bearish,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${isPositive ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%',
                          style: AppTypography.monoLabel.copyWith(
                            color: isPositive
                                ? AppThemeColors.bullish
                                : AppThemeColors.bearish,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

const DataOrigin _marketOrigin = DataOrigin(
  sourceLabel: 'Twelve Data',
  latencyClass: DataLatencyClass.delayed,
  isOfficial: false,
  isSynthetic: false,
);
