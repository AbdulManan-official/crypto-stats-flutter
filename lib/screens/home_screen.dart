import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import '../viewmodels/coin_viewmodel.dart';
import '../models/coin_model.dart';
import 'widgets.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<CoinViewModel>();
    final hp = context.horizontalPadding;
    final scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 300) {
        vm.loadMoreCoins();
      }
    });
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: vm.refreshAll,
            child: CustomScrollView(
              controller: scrollController,

              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── App Bar ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: hp.copyWith(top: 20, bottom: 0),
                    child: _HomeAppBar(vm: vm),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Search Bar ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: hp,
                    child: _SearchBar(vm: vm),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Search Results ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Obx(() {
                    if (!vm.isSearching) return const SizedBox.shrink();
                    return Padding(
                      padding: hp,
                      child: _SearchResults(vm: vm),
                    );
                  }),
                ),

                // ── Global Stats ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Obx(() {
                    if (vm.isSearching) return const SizedBox.shrink();
                    return Padding(
                      padding: hp,
                      child: _StatsSection(vm: vm),
                    );
                  }),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Coins Header + Filters ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Obx(() {
                    if (vm.isSearching) return const SizedBox.shrink();
                    return Padding(
                      padding: hp,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Top Coins'),
                          const SizedBox(height: 14),
                          _FiltersRow(vm: vm),
                        ],
                      ),
                    );
                  }),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Coins List ───────────────────────────────────────────────
                Obx(() {
                  if (vm.isSearching)
                    return const SliverToBoxAdapter(child: SizedBox.shrink());

                  // Loading state
                  if (vm.coinsLoading.value) {
                    return SliverPadding(
                      padding: hp,
                      sliver: SliverToBoxAdapter(child: CoinListShimmer()),
                    );
                  }

                  // Error state
                  if (vm.coinsError.value.isNotEmpty && vm.coins.isEmpty) {
                    return SliverToBoxAdapter(
                      child: AppErrorWidget(
                        message: vm.coinsError.value,
                        onRetry: () => vm.fetchCoins(refresh: true),
                        fullScreen: true,
                      ),
                    );
                  }

                  // Empty state
                  if (vm.coins.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: AppEmptyWidget(
                        icon: Icons.currency_bitcoin,
                        title: 'No coins found',
                        subtitle: 'Pull down to refresh',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: hp,
                    sliver: SliverList.separated(
                      itemCount: vm.coins.length + 1, // +1 for load more
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        // Load more trigger
                        if (index == vm.coins.length) {
                          return Obx(() {
                            if (vm.coinsLoadingMore.value) {
                              return const LoadMoreIndicator();
                            }
                            if (vm.hasMoreCoins) {
                              return const SizedBox(height: 20);
                            }
                            return const SizedBox(height: 20);
                          });
                        }

                        final coin = vm.coins[index];
                        return CoinCard(
                          coin: coin,
                          onTap: () => _openDetail(context, coin, vm),
                        );
                      },
                    ),
                  );
                }),

                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    CoinModel coin,
    CoinViewModel vm,
  ) async {
    FocusScope.of(context).unfocus(); // ✅ this is enough

    vm.fetchCoinDetail(coin.uuid);
    vm.fetchPriceHistory(coin.uuid, timePeriod: '7d');

    await Get.to(() => DetailScreen(coin: coin));
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  final CoinViewModel vm;
  const _HomeAppBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CryptoTrack',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Obx(() {
              if (vm.statsLoading.value) {
                return const Text(
                  'Loading market data...',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                );
              }
              final total = vm.stats.value?.totalCoins ?? 0;
              return Text(
                '$total coins tracked',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              );
            }),
          ],
        ),
        const Spacer(),
        // Live indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  final CoinViewModel vm;
  const _SearchBar({required this.vm});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: false,
      controller: _ctrl,
      focusNode: _focus,

      onChanged: widget.vm.onSearchChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search coins...',
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textMuted,
          size: 20,
        ),
        suffixIcon: Obx(() {
          if (!widget.vm.isSearching) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () {
              _ctrl.clear();
              widget.vm.clearSearch();
              _focus.unfocus();
            },
            child: const Icon(
              Icons.close,
              color: AppColors.textMuted,
              size: 18,
            ),
          );
        }),
      ),
    );
  }
}

// ─── Search Results ───────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final CoinViewModel vm;
  const _SearchResults({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (vm.searchLoading.value) {
        return CoinListShimmer(count: 4);
      }

      if (vm.searchResults.isEmpty) {
        return AppEmptyWidget(
          icon: Icons.search_off_outlined,
          title: 'No results',
          subtitle: 'Try searching for a different coin',
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${vm.searchResults.length} results',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          ...vm.searchResults.map(
            (coin) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CoinCard(
                coin: coin,
                onTap: () {
                  vm.fetchCoinDetail(coin.uuid);
                  vm.fetchPriceHistory(coin.uuid);
                  Get.to(() => DetailScreen(coin: coin));
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ─── Stats Section ────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final CoinViewModel vm;
  const _StatsSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (vm.statsLoading.value) {
        return Column(
          children: [
            const StatsRowShimmer(),
            const SizedBox(height: 10),
            const StatsRowShimmer(),
          ],
        );
      }

      if (vm.statsError.value.isNotEmpty || vm.stats.value == null) {
        return const SizedBox.shrink();
      }

      final s = vm.stats.value!;
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'MARKET CAP',
                  value: formatCompact(double.tryParse(s.totalMarketCap) ?? 0),
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: '24H VOLUME',
                  value: formatCompact(double.tryParse(s.total24hVolume) ?? 0),
                  icon: Icons.swap_horiz_rounded,
                  iconColor: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'TOTAL COINS',
                  value: s.totalCoins.toString(),
                  icon: Icons.toll_rounded,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'BTC DOMINANCE',
                  value: '${s.btcDominance.toStringAsFixed(1)}%',
                  icon: Icons.currency_bitcoin,
                  iconColor: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

// ─── Filters Row ──────────────────────────────────────────────────────────────

class _FiltersRow extends StatelessWidget {
  final CoinViewModel vm;
  const _FiltersRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => TimePeriodSelector(
        selected: vm.selectedTimePeriod.value,
        options: CoinViewModel.timePeriods,
        onSelected: vm.setTimePeriod,
      ),
    );
  }
}
