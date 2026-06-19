import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../models/coin_model.dart';
import '../utils/app_theme.dart';
import '../viewmodels/coin_viewmodel.dart';
import 'widgets.dart';

class DetailScreen extends StatefulWidget {
  final CoinModel coin;
  const DetailScreen({super.key, required this.coin});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final vm = Get.find<CoinViewModel>();
  String _selectedPeriod = '7d';

  static const _chartPeriods = ['24h', '7d', '30d', '3m', '1y'];

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
    vm.fetchPriceHistory(widget.coin.uuid, timePeriod: period);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (vm.detailLoading.value) {
          return _DetailShimmer();
        }
        if (vm.detailError.value.isNotEmpty && vm.selectedCoin.value == null) {
          return AppErrorWidget(
            message: vm.detailError.value,
            onRetry: () => vm.fetchCoinDetail(widget.coin.uuid),
            fullScreen: true,
          );
        }

        final coin = vm.selectedCoin.value;
        if (coin == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Price Header ─────────────────────────────────────────────
              _PriceHeader(coin: coin),
              const SizedBox(height: 24),

              // ── Price Chart ──────────────────────────────────────────────
              _ChartSection(
                vm: vm,
                selectedPeriod: _selectedPeriod,
                periods: _chartPeriods,
                onPeriodChanged: _onPeriodChanged,
                isPositive: coin.isPositive,
              ),
              const SizedBox(height: 24),

              // ── Stats Grid ───────────────────────────────────────────────
              _StatsGrid(coin: coin),
              const SizedBox(height: 24),

              // ── About ────────────────────────────────────────────────────
              if (coin.description != null && coin.description!.isNotEmpty)
                _AboutSection(description: coin.description!),

              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      title: Row(
        children: [
          CoinIcon(iconUrl: widget.coin.iconUrl, size: 28),
          const SizedBox(width: 8),
          Text(
            widget.coin.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.coin.symbol,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '#${widget.coin.rank}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Price Header ─────────────────────────────────────────────────────────────

class _PriceHeader extends StatelessWidget {
  final CoinDetail coin;
  const _PriceHeader({required this.coin});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatPrice(coin.priceDouble),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ChangeBadge(change: coin.changeDouble, fontSize: 13),
                  const SizedBox(width: 8),
                  const Text(
                    'vs yesterday',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Chart Section ────────────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final CoinViewModel vm;
  final String selectedPeriod;
  final List<String> periods;
  final ValueChanged<String> onPeriodChanged;
  final bool isPositive;

  const _ChartSection({
    required this.vm,
    required this.selectedPeriod,
    required this.periods,
    required this.onPeriodChanged,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period selector
        TimePeriodSelector(
          selected: selectedPeriod,
          options: periods,
          onSelected: onPeriodChanged,
        ),
        const SizedBox(height: 16),

        // Chart
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: Obx(() {
            if (vm.historyLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              );
            }

            final history = vm.priceHistory;
            if (history.isEmpty) {
              return const Center(
                child: Text(
                  'No chart data',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              );
            }

            return _PriceLineChart(history: history, isPositive: isPositive);
          }),
        ),
      ],
    );
  }
}

// ─── Price Line Chart ─────────────────────────────────────────────────────────

class _PriceLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final bool isPositive;

  const _PriceLineChart({required this.history, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.success : AppColors.error;

    final spots = history.asMap().entries.map((e) {
      final price = (e.value['price'] as double?) ?? 0.0;
      return FlSpot(e.key.toDouble(), price);
    }).toList();

    final prices = history.map((e) => (e['price'] as double?) ?? 0.0).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b);
    final maxY = prices.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              interval: (maxY - minY) / 4,
              getTitlesWidget: (value, _) => Text(
                formatCompact(value),
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.cardLight,
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                formatPrice(s.y),
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final CoinDetail coin;
  const _StatsGrid({required this.coin});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        label: 'Market Cap',
        value: formatCompact(coin.marketCapDouble),
        icon: Icons.bar_chart_rounded,
        iconColor: AppColors.primary,
      ),
      _StatItem(
        label: '24H Volume',
        value: formatCompact(coin.volumeDouble),
        icon: Icons.swap_horiz_rounded,
        iconColor: AppColors.warning,
      ),
      _StatItem(
        label: 'All Time High',
        value: coin.allTimeHigh != null
            ? formatPrice(double.tryParse(coin.allTimeHigh!) ?? 0)
            : 'N/A',
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.success,
      ),
      _StatItem(
        label: 'Rank',
        value: '#${coin.rank}',
        icon: Icons.leaderboard_rounded,
        iconColor: AppColors.primaryLight,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Statistics'),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: items
              .map(
                (item) => StatCard(
                  label: item.label.toUpperCase(),
                  value: item.value,
                  icon: item.icon,
                  iconColor: item.iconColor,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });
}

// ─── About Section ────────────────────────────────────────────────────────────

class _AboutSection extends StatefulWidget {
  final String description;
  const _AboutSection({required this.description});

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Strip HTML tags from description
    final clean = widget.description.replaceAll(RegExp(r'<[^>]*>'), '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'About'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clean,
                maxLines: _expanded ? null : 4,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Detail Shimmer ───────────────────────────────────────────────────────────

class _DetailShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price
            Container(width: 180, height: 36, decoration: _box()),
            const SizedBox(height: 10),
            Container(width: 100, height: 20, decoration: _box()),
            const SizedBox(height: 24),
            // Chart placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: _box(radius: 16),
            ),
            const SizedBox(height: 24),
            // Stats
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: List.generate(
                4,
                (_) => Container(decoration: _box(radius: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _box({double radius = 8}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
  );
}
