/// The authenticated user's public profile (backend `UserResponse`). Identified by `rid` only.
class AuthUser {
  const AuthUser({
    required this.rid,
    required this.email,
    required this.name,
    this.avatar,
    required this.timezone,
    required this.defaultCurrency,
    required this.emailVerified,
    required this.provider,
  });

  final String rid;
  final String email;
  final String name;
  final String? avatar;
  final String timezone;
  final String defaultCurrency;
  final bool emailVerified;
  final String provider;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      rid: json['rid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      timezone: json['timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
      defaultCurrency: json['defaultCurrency'] as String? ?? 'VND',
      emailVerified: json['emailVerified'] as bool? ?? false,
      provider: json['provider'] as String? ?? 'LOCAL',
    );
  }
}

/// Result of a successful login/register: tokens + the user profile (backend `AuthResponse`).
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
