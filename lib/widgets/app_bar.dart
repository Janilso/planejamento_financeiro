import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/theme/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.preferredSize = const Size.fromHeight(48.0),
    this.isDanger = false,
    this.actions,
  });

  final String title;
  final bool isDanger;
  final List<Widget>? actions;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    Color color = isDanger ? AppColors.secondary : AppColors.primary;
    return PreferredSize(
      preferredSize: preferredSize,
      child: AppBar(
        centerTitle: true,
        actions: actions,
        backgroundColor: AppColors.white,
        title: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 5),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge!
                .copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
