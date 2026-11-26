import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/widgets/balance/enum.dart';
import 'package:planejamento_financeiro/widgets/formField/enum.dart';

class AppFormField extends StatelessWidget {
  final String name;
  final TypeInput type;
  final String label;
  final String typeBalance;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final Color fillColor;
  final String hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final FormFieldValidator? validator;
  final ValueChanged<dynamic>? onChanged;
  final bool enabled;
  final int? maxLength;
  final int? minLength;

  const AppFormField({
    super.key,
    this.type = TypeInput.text,
    this.typeBalance = TypeBalance.gains,
    this.label = "",
    this.inputFormatters,
    this.autofocus = false,
    this.fillColor = AppColors.primary,
    this.hintText = "",
    this.controller,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.enabled = true,
    required this.name,
    this.maxLength,
    this.minLength = 0,
  });

  @override
  Widget build(BuildContext context) {
    bool isDanger = typeBalance == TypeBalance.expenses;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Wrap(
        children: [
          if (type == TypeInput.text)
            FormBuilderTextField(
              name: name,
              inputFormatters: inputFormatters,
              autofocus: autofocus,
              decoration: InputDecoration(
                fillColor: fillColor,
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.bodyLarge!
                    .copyWith(color: AppColors.black.withAlpha(120)),
                labelText: label,
                labelStyle: WidgetStateTextStyle.resolveWith(
                  (state) =>
                      Theme.of(context).textTheme.bodyLarge!
                          .copyWith(color: _getLabelColor(state)),
                ),
                floatingLabelStyle: WidgetStateTextStyle.resolveWith(
                  (state) =>
                      Theme.of(context).textTheme.bodyLarge!
                          .copyWith(color: _getLabelColor(state)),
                ),
                errorStyle: Theme.of(context).textTheme.bodySmall!
                    .copyWith(color: AppColors.secondary),
                border: _getBorder(),
                enabledBorder: _getBorder(),
                focusedBorder: _getBorder(2),
              ),
              controller: controller,
              maxLength: maxLength,
              keyboardType: keyboardType,
              validator: validator,
              onChanged: onChanged,
              enabled: enabled,
              cursorColor: _getColorAplha(isDanger),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge!
                  .copyWith(color: _getColorAplha(isDanger)),
            ),
          if (type == TypeInput.switchh)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: _getColorAplha(isDanger, 70),
                      highlightColor: _getColorAplha(isDanger, 20),
                    ),
                    child: FormBuilderSwitch(
                      name: name,
                      title: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge!
                            .copyWith(color: AppColors.black),
                      ),
                      onChanged: onChanged,
                      activeTrackColor: _getColorAplha(isDanger, 150),
                      activeColor: _getColorAplha(isDanger),
                      inactiveTrackColor: Colors.black.withAlpha(15),
                      decoration: InputDecoration(enabledBorder: _getBorder(1)),
                    ),
                  ),
                ),
              ],
            ),
          if (type == TypeInput.spin)
            FormBuilderField<int>(
              name: name,
              // initialValue: 1,
              validator: validator,
              builder: (field) {
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.grayLight,
                        width: 1.0,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(
                                color: field.hasError
                                    ? AppColors.secondary
                                    : AppColors.black,
                              ),
                        ),
                      ),
                      IntrinsicWidth(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                AppIcons.minus,
                                color: _getColorAplha(
                                  isDanger,
                                  field.value == (minLength) ||
                                          field.value == null
                                      ? 80
                                      : 255,
                                ),
                              ),
                              onPressed: () {
                                final novoValor = (field.value ?? 0) - 1;
                                if (novoValor >= minLength!) {
                                  field.didChange(novoValor);
                                }
                              },
                            ),
                            IntrinsicWidth(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: 40),
                                child: TextFormField(
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  maxLength: maxLength,
                                  buildCounter: (
                                    BuildContext context, {
                                    required int currentLength,
                                    required bool isFocused,
                                    required int? maxLength,
                                  }) => null,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    errorText: field.errorText,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text:
                                        field.value?.toStringAsFixed(0) ??
                                        minLength!.toStringAsFixed(0),
                                  ),
                                  onChanged: (value) {
                                    final parsed = int.tryParse(value);
                                    if (parsed != null) field.didChange(parsed);
                                  },
                                  style: Theme.of(context).textTheme.bodyLarge!
                                      .copyWith(color: AppColors.black),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                AppIcons.plus,
                                color: _getColorAplha(
                                  isDanger,
                                  field.value == maxLength ? 80 : 255,
                                ),
                              ),
                              onPressed: () {
                                final novoValor =
                                    (field.value ?? minLength)! + 1;
                                if (novoValor <= (maxLength ?? 0)) {
                                  field.didChange(novoValor);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getColorAplha(bool isDanger, [int alpha = 255]) {
    return isDanger
        ? AppColors.secondary.withAlpha(alpha)
        : AppColors.primary.withAlpha(alpha);
  }

  Color _getLabelColor(Set<WidgetState> state) {
    return state.contains(WidgetState.error)
        ? AppColors.secondary
        : AppColors.black;
  }

  InputBorder _getBorder([double width = 1.0]) {
    return UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.grayLight, width: width),
    );
  }
}
