import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:planejamento_financeiro/commons/formats.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/repository/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';
import 'package:planejamento_financeiro/widgets/balance/enum.dart';
import 'package:planejamento_financeiro/widgets/button.dart';
import 'package:planejamento_financeiro/widgets/delete_dialog.dart';
import 'package:planejamento_financeiro/widgets/formBalance/balance_fields.dart';
import 'package:planejamento_financeiro/widgets/formField/enum.dart';
import 'package:planejamento_financeiro/widgets/formField/form_field.dart';

class FormBalance extends StatefulWidget {
  final String typeBalance;
  final BalanceModel? balanceEdit;
  final Future<void> Function(BalanceModel)? onSubmit;
  // Exclui o lançamento em edição: true só a parcela, false o lançamento.
  final Future<void> Function(bool onlyInstallment)? onDelete;

  const FormBalance({
    super.key,
    this.typeBalance = TypeBalance.gains,
    this.balanceEdit,
    this.onSubmit,
    this.onDelete,
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

    // Em parcelado, o campo edita o valor do lançamento inteiro, não o da parcela.
    final edit = widget.balanceEdit;
    final value = _isInstallmentedEdit
        ? edit!.totalValue ?? edit.value
        : edit?.value;

    initialValue = {
      BalanceFields.name: edit?.name,
      BalanceFields.value: value != null
          ? formatterMoney.formatDouble(value.toDouble())
          : "",
      BalanceFields.realized: widget.balanceEdit?.realized,
      BalanceFields.totalInstallment: widget.balanceEdit?.totalInstallments,
    };
  }

  bool get _isInstallmentedEdit => widget.balanceEdit?.isInstallmented ?? false;

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

  // Excluir pela edição: o mesmo diálogo do arraste. O erro fica no modal.
  Future<void> _onDelete() async {
    final onlyInstallment = await confirmDeleteBalance(
      context,
      widget.balanceEdit!,
    );
    if (onlyInstallment == null || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onDelete!(onlyInstallment);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível excluir');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGain = widget.typeBalance == TypeBalance.gains;
    final Color tone = isGain ? AppColors.primary : AppColors.secondary;
    final textTheme = Theme.of(context).textTheme;
    // Cursor, puxador e seleção na cor do tipo.
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        // O foco do campo também usa a cor do tipo.
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: tone, width: 2),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: tone,
          selectionHandleColor: tone,
          selectionColor: tone.withAlpha(60),
        ),
      ),
      child: _buildForm(context, isGain, tone, textTheme),
    );
  }

  Widget _buildForm(
    BuildContext context,
    bool isGain,
    Color tone,
    TextTheme textTheme,
  ) {
    return FormBuilder(
      key: _formKey,
      autovalidateMode: _autovalidate,
      initialValue: initialValue,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.base),
            child: Text(
              '${widget.balanceEdit == null ? 'Novo' : 'Editar'} '
              '${isGain ? 'ganho' : 'gasto'}',
              style: textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
            label: _isInstallmentedEdit ? 'Valor total' : 'Valor',
            typeBalance: widget.typeBalance,
            keyboardType: TextInputType.number,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
            hintText: 'R\$ 0,00',
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
            label: 'Parcelas',
            typeBalance: widget.typeBalance,
            type: TypeInput.spin,
            minLength: 1,
            maxLength: 30,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium!.copyWith(color: AppColors.danger),
              ),
            ),
          AppButton(
            text: "Salvar",
            loading: _saving,
            backgroundColor: tone,
            onPressed: _onSubmit,
          ),
          if (widget.balanceEdit != null && widget.onDelete != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: _saving ? null : _onDelete,
                child: const Text('Excluir'),
              ),
            ),
          const SizedBox(height: AppSpacing.base),
        ],
      ),
    );
  }
}
