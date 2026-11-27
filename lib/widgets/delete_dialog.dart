import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/theme/colors.dart';

// Pergunta como excluir. Devolve null (Cancelar), false (o lançamento inteiro)
// ou true (só a parcela aberta).
Future<bool?> confirmDeleteBalance(BuildContext context, BalanceModel balance) {
  final danger = TextButton.styleFrom(foregroundColor: AppColors.danger);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Excluir "${balance.name}"?'),
      content: Text(
        balance.isInstallmented
            ? 'Este lançamento tem ${balance.totalInstallments} parcelas. '
                  'Você pode excluir só a parcela ${balance.installment} ou todas.'
            : 'Esta ação não pode ser desfeita.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (balance.isInstallmented) ...[
          TextButton(
            style: danger,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Todas'),
          ),
          TextButton(
            style: danger,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Só esta'),
          ),
        ] else
          TextButton(
            style: danger,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Excluir'),
          ),
      ],
    ),
  );
}
