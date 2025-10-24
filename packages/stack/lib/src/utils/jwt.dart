import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as jwt;

extension type JwtToken._(String token) {
  JwtToken(String token) : this._(token);

  jwt.JWT get _decoded => jwt.JWT.decode(token);

  jwt.Audience? get audience => _decoded.audience;
  String? get issuer => _decoded.issuer;

  Object? _getFromPayload(String key) {
    if (_decoded.payload is Map) {
      return _decoded.payload[key];
    }

    return null;
  }

  DateTime? get issuedAt {
    final iat = _getFromPayload('iat');
    if (iat is int) return DateTime.fromMillisecondsSinceEpoch(iat * 1000);
    return null;
  }

  DateTime? get expiresAt {
    final exp = _getFromPayload('exp');
    if (exp is int) return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return null;
  }
}
