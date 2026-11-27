import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';
import 'package:planejamento_financeiro/theme/texts_style.dart';
import 'package:planejamento_financeiro/widgets/infiniteTabelView/custom_tab_bar_view_scroll_physics.dart';

class InfiniteTabView extends StatefulWidget {
  final int length;
  final int initialIndex;
  final String Function(BuildContext context, int index)? buildTabBar;
  final Widget Function(BuildContext context, int index)? buildTabView;
  final void Function(int index)? onChangePage;
  // Fica à direita das abas, na mesma linha (por exemplo, o menu ⋮).
  final Widget? trailing;

  const InfiniteTabView({
    super.key,
    required this.length,
    this.initialIndex = 0,
    this.buildTabBar,
    this.buildTabView,
    this.onChangePage,
    this.trailing,
  });

  @override
  InfiniteTabViewState createState() => InfiniteTabViewState();
}

class InfiniteTabViewState extends State<InfiniteTabView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _createTabController();
  }

  @override
  void didUpdateWidget(covariant InfiniteTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length) {
      _tabController.removeListener(_handleChangePage);
      _tabController.dispose();
      _createTabController();
      setState(() {});
    }
  }

  void _createTabController() {
    _tabController = TabController(
      length: widget.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    )..addListener(_handleChangePage);
  }

  void _handleChangePage() {
    if (!_tabController.indexIsChanging && widget.onChangePage != null) {
      widget.onChangePage!(_tabController.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.length,
      initialIndex: widget.initialIndex,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  // Recria ao mudar a escala da fonte, para a aba selecionada
                  // continuar visível.
                  key: ValueKey(MediaQuery.textScalerOf(context)),
                  controller: _tabController,
                  labelPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  unselectedLabelStyle: AppTextsStyle.bodyLarge(
                    color: AppColors.white,
                  ),
                  labelStyle: AppTextsStyle.bodyLarge(
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                  tabs: List.generate(
                    widget.length,
                    (index) => Tab(
                      text: widget.buildTabBar!(context, index),
                      height: 48,
                    ),
                  ),
                  indicatorColor: AppColors.white,
                  dividerHeight: 0,
                ),
              ),
              ?widget.trailing,
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const CustomTabBarViewScrollPhysics(),
              children: List.generate(
                widget.length,
                (index) => widget.buildTabView!(context, index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleChangePage);
    _tabController.dispose();
    super.dispose();
  }
}
