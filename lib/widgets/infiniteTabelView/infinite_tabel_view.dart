import 'package:flutter/material.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/texts_style.dart';
import 'package:planejamento_financeiro/widgets/infiniteTabelView/custom_tab_bar_view_scroll_physics.dart';

class InfiniteTabView extends StatefulWidget {
  final int length;
  final int initialIndex;
  final String Function(BuildContext context, int index)? buildTabBar;
  final Widget Function(BuildContext context, int index)? buildTabView;
  final void Function(int index)? onChangePage;

  const InfiniteTabView({
    super.key,
    required this.length,
    this.initialIndex = 0,
    this.buildTabBar,
    this.buildTabView,
    this.onChangePage,
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
          TabBar(
            controller: _tabController,
            labelPadding: EdgeInsets.symmetric(horizontal: 12),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            unselectedLabelStyle: AppTextsStyle.bodyLarge(
              color: AppColors.whiteDesable,
            ),
            labelStyle: AppTextsStyle.bodyLarge(
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
            tabs: List.generate(
              widget.length,
              (index) => Tab(text: widget.buildTabBar!(context, index)),
            ),
            indicatorColor: AppColors.white,
            dividerHeight: 0,
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
