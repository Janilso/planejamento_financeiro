import 'package:flutter_test/flutter_test.dart';
import 'package:planejamento_financeiro/repository/session.dart';
import 'package:planejamento_financeiro/repository/token_storage.dart';

import '../fakes.dart';

void main() {
  const tokens = AuthTokens(token: 't', refreshToken: 'r');

  test('com Firebase e tokens há sessão', () async {
    expect(
      await hasSession(
        isFirebaseSignedIn: () => true,
        storage: InMemoryTokenStorage(tokens),
      ),
      isTrue,
    );
  });

  test('sem tokens da API não há sessão', () async {
    expect(
      await hasSession(
        isFirebaseSignedIn: () => true,
        storage: InMemoryTokenStorage(),
      ),
      isFalse,
    );
  });

  test('sem Firebase não há sessão', () async {
    expect(
      await hasSession(
        isFirebaseSignedIn: () => false,
        storage: InMemoryTokenStorage(tokens),
      ),
      isFalse,
    );
  });
}
