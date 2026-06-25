/// The authenticated user's public profile (backend `UserResponse`). Identified by `rid` only.
class AuthUser {
  const AuthUser({
    required this.rid,
    required this.email,
    required this.name,
    this.avatar,
    this.phone,
    required this.timezone,
    required this.defaultCurrency,
    required this.emailVerified,
    required this.provider,
    required this.hasPassword,
  });

  final String rid;
  final String email;
  final String name;
  final String? avatar;

  /// Optional phone number in E.164 (e.g. `+84912345678`); null when not set.
  final String? phone;
  final String timezone;
  final String defaultCurrency;
  final bool emailVerified;
  final String provider;

  /// False for an account created via an OAuth provider that has never set a
  /// local password — the UI then offers "set password" (no current field).
  final bool hasPassword;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      rid: json['rid'] as String? ?? '',
      email: json['email'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      timezone: json['timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
      defaultCurrency: json['defaultCurrency'] as String? ?? 'VND',
      emailVerified: json['emailVerified'] as bool? ?? false,
      provider: json['provider'] as String? ?? 'LOCAL',
      hasPassword: json['hasPassword'] as bool? ?? true,
    );
  }

  /// For caching the profile locally so a transient `/users/me` failure on startup (offline, server
  /// cold-start) doesn't sign the user out — the cached copy keeps them in until the next success.
  Map<String, dynamic> toJson() => {
        'rid': rid,
        'email': email,
        'name': name,
        'avatar': avatar,
        'phone': phone,
        'timezone': timezone,
        'defaultCurrency': defaultCurrency,
        'emailVerified': emailVerified,
        'provider': provider,
        'hasPassword': hasPassword,
      };

  AuthUser copyWith({String? name, String? phone, String? defaultCurrency}) {
    return AuthUser(
      rid: rid,
      email: email,
      name: name ?? this.name,
      avatar: avatar,
      phone: phone ?? this.phone,
      timezone: timezone,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      emailVerified: emailVerified,
      provider: provider,
      hasPassword: hasPassword,
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
