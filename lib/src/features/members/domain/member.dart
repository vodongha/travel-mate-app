/// A trip member (backend `MemberResponse`). A ghost member has no account but can be split with.
class Member {
  const Member({
    required this.rid,
    required this.displayName,
    required this.role,
    required this.ghost,
    this.email,
    this.mine = false,
    this.joinedAt,
  });

  final String rid;
  final String displayName;
  final String role;
  final bool ghost;

  /// Optional email on a ghost — lets the ghost auto-merge into the account that joins with it.
  final String? email;

  /// True for the membership belonging to the signed-in user (the "Myself" entry).
  final bool mine;
  final DateTime? joinedAt;

  factory Member.fromJson(Map<String, dynamic> json) {
    final Object? joined = json['joinedAt'];
    return Member(
      rid: json['rid'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String? ?? 'VIEWER',
      ghost: json['ghost'] as bool? ?? false,
      email: json['email'] as String?,
      mine: json['mine'] as bool? ?? false,
      joinedAt: joined is String ? DateTime.tryParse(joined) : null,
    );
  }
}

/// An invitation token + the link to render as a QR (backend `InvitationResponse`).
class Invitation {
  const Invitation({
    required this.rid,
    required this.token,
    required this.inviteUrl,
    required this.role,
    required this.maxUses,
    required this.usedCount,
  });

  final String rid;
  final String token;
  final String inviteUrl;
  final String role;
  final int maxUses;
  final int usedCount;

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      rid: json['rid'] as String,
      token: json['token'] as String,
      inviteUrl: json['inviteUrl'] as String? ?? '',
      role: json['role'] as String? ?? 'VIEWER',
      maxUses: (json['maxUses'] as num?)?.toInt() ?? 1,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Result of accepting an invitation (backend `AcceptInvitationResponse`).
class AcceptResult {
  const AcceptResult({required this.tripRid, required this.role});

  final String tripRid;
  final String role;

  factory AcceptResult.fromJson(Map<String, dynamic> json) {
    return AcceptResult(
      tripRid: json['tripRid'] as String,
      role: json['role'] as String? ?? 'VIEWER',
    );
  }
}
