import 'package:planejamento_financeiro/repository/token_storage.dart';

// Há sessão quando o Firebase está logado e os tokens da API existem.
Future<bool> hasSession({
  required bool Function() isFirebaseSignedIn,
  required TokenStorage storage,
}) async {
  if (!isFirebaseSignedIn()) return false;
  return await storage.read() != null;
}
