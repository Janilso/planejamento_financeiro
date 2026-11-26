import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/widgets/balance/balance.dart';
import 'package:planejamento_financeiro/widgets/balance/enum.dart';
import 'package:planejamento_financeiro/widgets/base_modal.dart';
import 'package:planejamento_financeiro/widgets/formBalance/form_balance.dart';
import 'package:planejamento_financeiro/widgets/infiniteTabelView/custom_tab_bar_view_scroll_physics.dart';

class BalanceTabView extends StatefulWidget {
  final List<BalanceModel> gainBalances;
  final List<BalanceModel> expensesBalances;
  final Function(String typeBalance)? onTabChanged;
  final Function(BalanceModel balance)? onSubmit;

  const BalanceTabView({
    super.key,
    this.gainBalances = const [],
    this.expensesBalances = const [],
    this.onTabChanged,
    this.onSubmit,
  });

  @override
  State<BalanceTabView> createState() => _BalanceTabViewState();
}

class _BalanceTabViewState extends State<BalanceTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleChangePage);
  }

  void _handleChangePage() {
    if (widget.onTabChanged != null) {
      widget.onTabChanged!(
        _tabController.index == 0 ? TypeBalance.gains : TypeBalance.expenses,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Center(
            child: TabBar(
              controller: _tabController,
              tabAlignment: TabAlignment.center,
              dragStartBehavior: DragStartBehavior.down,
              isScrollable: true,
              tabs: const [
                Tab(text: 'GANHOS'),
                Tab(text: 'GASTOS'),
              ],
              unselectedLabelStyle: Theme.of(context).textTheme.bodyLarge!
                  .copyWith(color: AppColors.whiteDesable),
              labelStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
              indicatorColor: AppColors.white,
              dividerColor: Colors.transparent,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 0),
              child: TabBarView(
                controller: _tabController,
                physics: const CustomTabBarViewScrollPhysics(),
                children: [
                  _buildBalances(context, widget.gainBalances),
                  _buildBalances(context, widget.expensesBalances, false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalances(
    BuildContext context,
    List<BalanceModel> balances, [
    bool isGain = true,
  ]) {
    // Material (e não Container) para o efeito de toque dos ListTile aparecer.
    return Material(
      color: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: balances.length,
        itemBuilder: (_, index) {
          BalanceModel balance = balances[index];
          return Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(index == 0 ? 16 : 0),
                ),
                color: AppColors.secondary,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      balance.isInstallmented
                          ? "Excluir parcelamentos"
                          : "Excluir",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.delete_outline, color: Colors.white),
                  ],
                ),
              ),
            ),
            onDismissed: (_) {},
            child: Column(
              children: [
                Balance(
                  onTap: () => baseModal(
                    context,
                    FormBalance(
                      typeBalance: balance.type,
                      balanceEdit: balance,
                      onSubmit: widget.onSubmit,
                    ),
                  ),
                  name: balance.isInstallmented
                      ? '${balance.name} - ${balance.installment}/${balance.totalInstallments}'
                      : balance.name,
                  value: balance.value,
                  isDanger: !isGain,
                  isDot: !balance.realized,
                ),
                if (index != balances.length)
                  const Divider(color: AppColors.grayLight, height: 0),
              ],
            ),
          );
        },
      ),
    );
  }
}
