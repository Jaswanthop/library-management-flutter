/// Membership tiers and how many books each tier may borrow at once.
enum MembershipTier {
  student('Student', 3),
  faculty('Faculty', 6),
  community('Community', 2);

  const MembershipTier(this.label, this.loanLimit);

  final String label;
  final int loanLimit;

  static MembershipTier fromLabel(String label) {
    return MembershipTier.values.firstWhere(
      (MembershipTier tier) => tier.label == label,
      orElse: () => MembershipTier.student,
    );
  }
}

/// A registered library member.
class Member {
  const Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.tier,
    required this.joinedAt,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final MembershipTier tier;
  final DateTime joinedAt;
  final bool isActive;

  int get loanLimit => tier.loanLimit;

  Member copyWith({
    String? name,
    String? email,
    String? phone,
    MembershipTier? tier,
    bool? isActive,
  }) {
    return Member(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      tier: tier ?? this.tier,
      joinedAt: joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
