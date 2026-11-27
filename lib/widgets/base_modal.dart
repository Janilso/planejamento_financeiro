import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';

void baseModal(BuildContext context, [Widget? child]) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    elevation: 5,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppRadius.lg),
        topRight: Radius.circular(AppRadius.lg),
      ),
    ),
    builder: (context) => SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.base,
          right: AppSpacing.base,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 72,
                height: 4,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
                  color: AppColors.grayLight,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ?child,
          ],
        ),
      ),
    ),
  );
}
