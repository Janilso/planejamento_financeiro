import 'package:planejamento_financeiro/network/http_client.dart';
import 'package:planejamento_financeiro/repository/token_storage.dart';

// Fala com as rotas /auth da API. Usa um HttpClient sem o AuthInterceptor,
// para o refresh não disparar outro refresh.
class AuthRepository {
  AuthRepository(this._client, this._storage);

  final HttpClient _client;
  final TokenStorage _storage;

  Future<void> loginWithGoogleIdToken(String idToken) async {
    final response = await _client.post(
      ClientRequest(url: '/auth/login', body: {'googleToken': idToken}),
    );
    await _storage.save(_tokensFrom(response.data));
  }

  // true se renovou; false se a sessão não pode mais ser renovada.
  Future<bool> refresh() async {
    final current = await _storage.read();
    if (current == null) return false;
    try {
      final response = await _client.post(
        ClientRequest(
          url: '/auth/refresh',
          body: {'refreshToken': current.refreshToken},
        ),
      );
      await _storage.save(_tokensFrom(response.data));
      return true;
    } catch (_) {
      return false;
    }
  }

  // Revoga o refresh na API quando possível; os tokens locais sempre saem.
  Future<void> logout() async {
    final current = await _storage.read();
    if (current != null) {
      try {
        await _client.post(
          ClientRequest(
            url: '/auth/logout',
            headers: {'Authorization': 'Bearer ${current.token}'},
          ),
        );
      } catch (_) {}
    }
    await _storage.clear();
  }

  AuthTokens _tokensFrom(dynamic data) {
    final map = data as Map<String, dynamic>;
    return AuthTokens(
      token: map['token'] as String,
      refreshToken: map['refreshToken'] as String,
    );
  }
}
