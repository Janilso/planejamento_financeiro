import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';
import 'package:planejamento_financeiro/widgets/state_message.dart';
import 'package:planejamento_financeiro/widgets/balance/balance.dart';
import 'package:planejamento_financeiro/widgets/balance/enum.dart';
import 'package:planejamento_financeiro/widgets/base_modal.dart';
import 'package:planejamento_financeiro/widgets/delete_dialog.dart';
import 'package:planejamento_financeiro/widgets/formBalance/form_balance.dart';

class BalanceTabView extends StatefulWidget {
  final List<BalanceModel> gainBalances;
  final List<BalanceModel> expensesBalances;
  // A aba que abre primeiro (TypeBalance.gains ou TypeBalance.expenses): a
  // página do mês novo abre na aba em que a pessoa já está.
  final String initialType;
  final Function(String typeBalance)? onTabChanged;
  // Posição das abas durante o toque, o arraste e o assentamento: 0 em ganhos,
  // 1 em gastos, e valores no meio enquanto o dedo ou a animação se movem.
  final ValueChanged<double>? onTabProgress;
  final Future<void> Function(BalanceModel original, BalanceModel edited)?
  onEdit;
  // onlyInstallment: true exclui só a parcela; false, o lançamento inteiro.
  final Future<void> Function(BalanceModel balance, {bool onlyInstallment})?
  onDelete;

  const BalanceTabView({
    super.key,
    this.initialType = TypeBalance.gains,
    this.gainBalances = const [],
    this.expensesBalances = const [],
    this.onTabChanged,
    this.onTabProgress,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<BalanceTabView> createState() => _BalanceTabViewState();
}

class _BalanceTabViewState extends State<BalanceTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Itens já excluídos na API: saem da lista até a recarga chegar, porque o
  // Dismissible não pode continuar na árvore depois do arraste.
  final Set<String> _removed = {};

  String _keyOf(BalanceModel b) => '${b.id}-${b.installment}';

  @override
  void didUpdateWidget(covariant BalanceTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gainBalances != widget.gainBalances ||
        oldWidget.expensesBalances != widget.expensesBalances) {
      _removed.clear();
    }
  }

  Future<bool> _confirmDelete(BalanceModel balance) async {
    final onlyInstallment = await confirmDeleteBalance(context, balance);
    if (onlyInstallment == null || widget.onDelete == null) return false;
    try {
      await widget.onDelete!(balance, onlyInstallment: onlyInstallment);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir')),
        );
      }
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialType == TypeBalance.expenses ? 1 : 0,
    )..addListener(_handleChangePage);
    _tabController.animation?.addListener(_handleTabProgress);
  }

  void _handleTabProgress() {
    widget.onTabProgress?.call(_tabController.animation!.value);
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
    _tabController.animation?.removeListener(_handleTabProgress);
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
                Tab(text: 'GANHOS', height: 48),
                Tab(text: 'GASTOS', height: 48),
              ],
              unselectedLabelStyle: Theme.of(context).textTheme.bodyLarge!
                  .copyWith(color: AppColors.white),
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
    final visible = balances
        .where((b) => !_removed.contains(_keyOf(b)))
        .toList();
    // Material (e não Container) para o efeito de toque dos ListTile aparecer.
    return Material(
      color: AppColors.white,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: visible.isEmpty
          ? Align(
              alignment: Alignment.topCenter,
              child: StateMessage(
                icon: isGain
                    ? Icons.savings_outlined
                    : Icons.receipt_long_outlined,
                title: isGain
                    ? 'Nenhum ganho neste mês'
                    : 'Nenhum gasto neste mês',
                subtitle: 'Toque em + para lançar',
              ),
            )
          : ListView.builder(
              // Espaço no fim para o último item não ficar atrás do botão +.
              padding: const EdgeInsets.only(bottom: 88),
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: visible.length,
              itemBuilder: (_, index) {
                BalanceModel balance = visible[index];
                return Dismissible(
                  key: ValueKey(_keyOf(balance)),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(index == 0 ? AppRadius.lg : 0),
                      ),
                      color: AppColors.danger,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            balance.isInstallmented
                                ? "Excluir parcelamentos"
                                : "Excluir",
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(color: AppColors.white),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(
                            Icons.delete_outline,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  confirmDismiss: (_) => _confirmDelete(balance),
                  onDismissed: (_) =>
                      setState(() => _removed.add(_keyOf(balance))),
                  child: Column(
                    children: [
                      Balance(
                        onTap: () => baseModal(
                          context,
                          FormBalance(
                            typeBalance: balance.type,
                            balanceEdit: balance,
                            onSubmit: widget.onEdit == null
                                ? null
                                : (edited) => widget.onEdit!(balance, edited),
                            onDelete: widget.onDelete == null
                                ? null
                                : (only) => widget.onDelete!(
                                    balance,
                                    onlyInstallment: only,
                                  ),
                          ),
                        ),
                        name: balance.name,
                        subtitle: balanceSubtitle(balance),
                        value: balance.value,
                        isDanger: !isGain,
                        realized: balance.realized,
                      ),
                      if (index != visible.length)
                        const Divider(color: AppColors.grayLight, height: 0),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
