import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/formats.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/extensions/string.dart';
import 'package:planejamento_financeiro/theme/colors.dart';

class Balance extends StatelessWidget {
  final String name;
  final double? value;
  final bool isDanger;
  final bool isDot;
  final GestureTapCallback? onTap;

  const Balance({
    super.key,
    required this.name,
    this.value,
    this.isDanger = false,
    this.isDot = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onTap: onTap,
      leading: Stack(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: isDanger
                  ? AppColors.secondaryLight
                  : AppColors.primaryLight,
              borderRadius: const BorderRadius.all(Radius.circular(35)),
            ),
            child: Icon(
              AppIcons.dollar,
              size: 20,
              color: isDanger ? AppColors.secondary : AppColors.primary,
            ),
          ),
          if (isDot)
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDanger ? AppColors.secondary : AppColors.primary,
                  borderRadius: const BorderRadius.all(Radius.circular(35)),
                ),
              ),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        name.capitalize(),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(color: AppColors.black),
      ),
      trailing: Text(
        AppFormats.valueToMoney(value),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: isDanger ? AppColors.secondary : AppColors.primary,
        ),
      ),
    );
  }
}
