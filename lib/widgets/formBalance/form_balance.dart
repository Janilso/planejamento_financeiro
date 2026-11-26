import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:planejamento_financeiro/commons/formats.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/repository/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/widgets/balance/enum.dart';
import 'package:planejamento_financeiro/widgets/button.dart';
import 'package:planejamento_financeiro/widgets/formBalance/balance_fields.dart';
import 'package:planejamento_financeiro/widgets/formField/enum.dart';
import 'package:planejamento_financeiro/widgets/formField/form_field.dart';

class FormBalance extends StatefulWidget {
  final String typeBalance;
  final BalanceModel? balanceEdit;
  final Future<void> Function(BalanceModel)? onSubmit;

  const FormBalance({
    super.key,
    this.typeBalance = TypeBalance.gains,
    this.balanceEdit,
    this.onSubmit,
  });

  @override
  State<FormBalance> createState() => _FormBalanceState();
}

class _FormBalanceState extends State<FormBalance> {
  final _formKey = GlobalKey<FormBuilderState>();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _saving = false;
  // Erro mostrado dentro do modal: uma SnackBar ficaria escondida atrás dele.
  String? _error;
  late Map<String, dynamic> initialValue;
  final formatterMoney = CurrencyTextInputFormatter.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();

    bool haveValue = widget.balanceEdit?.value != null;

    initialValue = {
      BalanceFields.name: widget.balanceEdit?.name,
      BalanceFields.value: haveValue
          ? formatterMoney.formatDouble(widget.balanceEdit!.value!.toDouble())
          : "",
      BalanceFields.realized: widget.balanceEdit?.realized,
      BalanceFields.totalInstallment: widget.balanceEdit?.totalInstallments,
    };
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (widget.onSubmit != null) {
        final data = _formKey.currentState!.instantValue;
        final balance =
            widget.balanceEdit?.copyWith(
              date: widget.balanceEdit?.date,
              name: data[BalanceFields.name],
              totalInstallments: data[BalanceFields.totalInstallment],
              realized: data[BalanceFields.realized],
              value: AppFormats.stringMoneyToDouble(data[BalanceFields.value]),
            ) ??
            BalanceModel(
              name: data[BalanceFields.name],
              totalInstallments: data[BalanceFields.totalInstallment] ?? 1,
              type: widget.typeBalance,
              realized: data[BalanceFields.realized] ?? false,
              value: AppFormats.stringMoneyToDouble(data[BalanceFields.value]),
            );

        setState(() {
          _saving = true;
          _error = null;
        });
        try {
          await widget.onSubmit!(balance);
          if (mounted) Navigator.of(context).pop();
        } catch (error) {
          if (mounted) {
            setState(() {
              _error = error is ApiException
                  ? error.message
                  : 'Não foi possível salvar';
            });
          }
        } finally {
          if (mounted) setState(() => _saving = false);
        }
      }
    } else {
      setState(() => _autovalidate = AutovalidateMode.always);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      autovalidateMode: _autovalidate,
      initialValue: initialValue,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFormField(
            name: BalanceFields.name,
            label: 'Nome',
            typeBalance: widget.typeBalance,
            maxLength: 30,
            hintText: widget.typeBalance == TypeBalance.gains
                ? 'Nome do ganho'
                : 'Nome do gasto',
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.maxLength(30),
            ]),
            autofocus: true,
          ),
          AppFormField(
            name: BalanceFields.value,
            label: 'Valor',
            typeBalance: widget.typeBalance,
            keyboardType: TextInputType.number,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
            inputFormatters: [formatterMoney],
          ),
          AppFormField(
            name: BalanceFields.realized,
            label: "Realizado",
            type: TypeInput.switchh,
            typeBalance: widget.typeBalance,
          ),
          AppFormField(
            name: BalanceFields.totalInstallment,
            label: 'Parcela(s)',
            typeBalance: widget.typeBalance,
            type: TypeInput.spin,
            minLength: 1,
            maxLength: 30,
          ),
          const SizedBox(height: 32),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(color: AppColors.secondary),
              ),
            ),
          AppButton(
            text: "Salvar",
            loading: _saving,
            icon: AppIcons.send,
            backgroundColor: widget.typeBalance == TypeBalance.gains
                ? AppColors.primary
                : AppColors.secondary,
            onPressed: _onSubmit,
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
