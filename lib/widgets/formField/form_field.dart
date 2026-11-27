import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/widgets/balance/enum.dart';
import 'package:planejamento_financeiro/widgets/formField/enum.dart';

// O único estilo dos valores digitados (Nome, Valor) e do número de parcelas.
TextStyle formValueStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge!
        .copyWith(color: AppColors.black, fontWeight: FontWeight.w400);

class AppFormField extends StatelessWidget {
  final String name;
  final TypeInput type;
  final String label;
  final String typeBalance;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
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

  // O contador só aparece nos 5 últimos caracteres antes do limite.
  Widget? _counter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    if (maxLength == null || currentLength < maxLength - 5) return null;
    return Text(
      '$currentLength/$maxLength',
      style: Theme.of(context).textTheme.labelSmall!
          .copyWith(color: AppColors.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDanger = typeBalance == TypeBalance.expenses;
    final Color tone = isDanger ? AppColors.secondary : AppColors.primary;
    final textTheme = Theme.of(context).textTheme;

    switch (type) {
      case TypeInput.text:
        // Rótulo, exemplo, erro e sublinhado vêm do inputDecorationTheme.
        return FormBuilderTextField(
          name: name,
          inputFormatters: inputFormatters,
          autofocus: autofocus,
          // helperText em branco reserva a linha do erro: os erros de
          // validação aparecem sem empurrar o formulário.
          decoration: InputDecoration(
            hintText: hintText,
            labelText: label,
            helperText: ' ',
          ),
          controller: controller,
          maxLength: maxLength,
          buildCounter: _counter,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          cursorColor: tone,
          style: formValueStyle(context),
        );
      case TypeInput.switchh:
        return Theme(
          data: Theme.of(context).copyWith(
            splashColor: tone.withAlpha(31),
            highlightColor: tone.withAlpha(20),
          ),
          child: FormBuilderSwitch(
            name: name,
            title: Text(label, style: textTheme.bodyMedium),
            onChanged: onChanged,
            activeTrackColor: tone.withAlpha(150),
            activeColor: tone,
            decoration: const InputDecoration(),
          ),
        );
      case TypeInput.spin:
        return FormBuilderField<int>(
          name: name,
          validator: validator,
          builder: (field) {
            final int min = minLength ?? 1;
            final int max = maxLength ?? 1;
            final int quantidade = field.value ?? min;
            return Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grayLight, width: 1.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rótulo à esquerda e − número + à direita, como antes.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: textTheme.bodyMedium!.copyWith(
                            color: field.hasError
                                ? AppColors.danger
                                : AppColors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Menos uma parcela',
                        icon: Icon(
                          AppIcons.minus,
                          color: tone.withAlpha(quantidade <= min ? 80 : 255),
                        ),
                        onPressed: () {
                          if (quantidade - 1 >= min) {
                            field.didChange(quantidade - 1);
                          }
                        },
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 40),
                        child: Text(
                          '$quantidade',
                          textAlign: TextAlign.center,
                          style: formValueStyle(context),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Mais uma parcela',
                        icon: Icon(
                          AppIcons.plus,
                          color: tone.withAlpha(quantidade >= max ? 80 : 255),
                        ),
                        onPressed: () {
                          if (quantidade + 1 <= max) {
                            field.didChange(quantidade + 1);
                          }
                        },
                      ),
                    ],
                  ),
                  if (field.errorText != null)
                    Text(
                      field.errorText!,
                      style: textTheme.labelSmall!.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                ],
              ),
            );
          },
        );
    }
  }
}
