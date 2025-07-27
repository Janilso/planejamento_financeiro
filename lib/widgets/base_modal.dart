import 'package:flutter/material.dart';
import 'package:planejamento_financeiro/theme/colors.dart';

void baseModal(BuildContext context, [Widget? child]) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    elevation: 5,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
    builder: (context) => SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 75,
                height: 5,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: AppColors.grayLight,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (child != null) child,
          ],
        ),
      ),
    ),
  );
}
