import 'package:flutter/material.dart';

import '../data/library_store.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/loan_dialog.dart';
import '../dialogs/member_dialog.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';
import '../utils/feedback.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

enum _MemberStatus { all, active, inactive }

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController _search = TextEditingController();
  String _tier = 'All tiers';
  _MemberStatus _status = _MemberStatus.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Member> _visibleMembers(LibraryStore store) {
    final String query = _search.text.trim().toLowerCase();
    return store.members.where((Member member) {
      final bool matchesQuery = query.isEmpty ||
          member.name.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query) ||
          member.phone.contains(query) ||
          member.id.toLowerCase().contains(query);
      final bool matchesTier =
          _tier == 'All tiers' || member.tier.label == _tier;
      final bool matchesStatus = switch (_status) {
        _MemberStatus.all => true,
        _MemberStatus.active => member.isActive,
        _MemberStatus.inactive => !member.isActive,
      };
      return matchesQuery && matchesTier && matchesStatus;
    }).toList()
      ..sort((Member a, Member b) => a.name.compareTo(b.name));
  }

  Future<void> _registerMember() async {
    final bool saved = await showMemberDialog(context);
    if (saved && mounted) {
      showToast(context, 'Member registered and ready to borrow.');
    }
  }

  Future<void> _editMember(Member member) async {
    final bool saved = await showMemberDialog(context, member: member);
    if (saved && mounted) showToast(context, '${member.name} updated.');
  }

  Future<void> _issueBook(Member member) async {
    final bool created =
        await showIssueLoanDialog(context, memberId: member.id);
    if (created && mounted) {
      showToast(context, 'Book issued to ${member.name}.');
    }
  }

  Future<void> _deleteMember(Member member) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Remove ${member.name}?',
      message:
          'The membership record and its loan history will be deleted. '
          'This cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    try {
      LibraryScope.read(context).deleteMember(member.id);
      if (mounted) showToast(context, '${member.name} removed.');
    } on LibraryException catch (error) {
      if (mounted) showToast(context, error.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LibraryStore store = LibraryScope.of(context);
    final AppColors colors = context.colors;
    final List<Member> visible = _visibleMembers(store);
    final int totalLimit = store.members
        .where((Member member) => member.isActive)
        .fold(0, (int sum, Member member) => sum + member.loanLimit);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PageHeader(
                title: 'Members',
                subtitle:
                    '${store.activeMembers} active of ${store.members.length} '
                    'registered · capacity for $totalLimit concurrent loans',
                actions: <Widget>[
                  FilledButton.icon(
                    onPressed: _registerMember,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Register member'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool wide = constraints.maxWidth >= 720;
                    final Widget search = TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, phone or member ID',
                        hintStyle:
                            TextStyle(fontSize: 13.5, color: colors.muted),
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 20, color: colors.muted),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                    final Widget tier = _TabSelect<String>(
                      icon: Icons.workspace_premium_outlined,
                      value: _tier,
                      items: <String>[
                        'All tiers',
                        ...MembershipTier.values
                            .map((MembershipTier tier) => tier.label),
                      ],
                      onChanged: (String value) =>
                          setState(() => _tier = value),
                    );
                    final Widget status = _TabSelect<_MemberStatus>(
                      icon: Icons.verified_user_outlined,
                      value: _status,
                      items: _MemberStatus.values,
                      labelOf: (_MemberStatus value) => switch (value) {
                        _MemberStatus.all => 'Everyone',
                        _MemberStatus.active => 'Active',
                        _MemberStatus.inactive => 'Inactive',
                      },
                      onChanged: (_MemberStatus value) =>
                          setState(() => _status = value),
                    );

                    if (!wide) {
                      return Column(
                        children: <Widget>[
                          search,
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[tier, status],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: <Widget>[
                        Expanded(child: search),
                        const SizedBox(width: 10),
                        tier,
                        const SizedBox(width: 8),
                        status,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (store.members.isEmpty)
                AppCard(
                  child: EmptyState(
                    icon: Icons.group_add_outlined,
                    title: 'No members yet',
                    message:
                        'Register members to start issuing books and tracking '
                        'loan history.',
                    action: FilledButton.icon(
                      onPressed: _registerMember,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Register the first member'),
                    ),
                  ),
                )
              else if (visible.isEmpty)
                AppCard(
                  child: const NoResults(
                    message: 'No members match these filters.',
                  ),
                )
              else
                Column(
                  children: <Widget>[
                    for (final Member member in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MemberRow(
                          member: member,
                          store: store,
                          onIssue: () => _issueBook(member),
                          onEdit: () => _editMember(member),
                          onDelete: () => _deleteMember(member),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.store,
    required this.onIssue,
    required this.onEdit,
    required this.onDelete,
  });

  final Member member;
  final LibraryStore store;
  final VoidCallback onIssue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final int held = store.activeLoanCountForMember(member.id);
    final int seed = member.name.codeUnits.fold<int>(0, (int a, int b) => a + b);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool showContact = constraints.maxWidth >= 640;
          final bool showLoans = constraints.maxWidth >= 860;
          return Row(
            children: <Widget>[
              InitialsAvatar(initials: initialsOf(member.name), seed: seed),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!member.isActive)
                          Pill(
                            label: 'Inactive',
                            dense: true,
                            foreground: colors.danger,
                            background: colors.dangerSoft,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      showContact
                          ? '${member.email} · ${member.phone}'
                          : member.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colors.muted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        Pill(
                          label: member.tier.label,
                          dense: true,
                          icon: Icons.workspace_premium_outlined,
                          foreground: Theme.of(context).colorScheme.primary,
                          background: colors.infoSoft,
                        ),
                        Pill(
                          label: '$held/${member.loanLimit} books',
                          dense: true,
                          foreground:
                              held >= member.loanLimit ? colors.warning : null,
                          background: held >= member.loanLimit
                              ? colors.warningSoft
                              : null,
                        ),
                        Pill(
                          label: 'Joined ${formatDate(member.joinedAt)}',
                          dense: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showLoans) ...<Widget>[
                const SizedBox(width: 16),
                SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        member.isActive ? 'Active member' : 'Suspended',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: member.isActive ? colors.success : colors.danger,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: member.loanLimit == 0
                              ? 0
                              : held / member.loanLimit,
                          minHeight: 5,
                          backgroundColor: colors.border.withValues(alpha: 0.6),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            held >= member.loanLimit
                                ? colors.warning
                                : colors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Issue a book',
                onPressed: member.isActive && held < member.loanLimit
                    ? onIssue
                    : null,
                icon: const Icon(Icons.swap_horiz_rounded, size: 20),
              ),
              PopupMenuButton<String>(
                tooltip: 'Member actions',
                icon: Icon(Icons.more_vert_rounded, color: colors.muted),
                onSelected: (String value) {
                  switch (value) {
                    case 'issue':
                      onIssue();
                      break;
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'issue',
                    child: Text('Issue a book'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit member'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Remove member',
                      style: TextStyle(color: colors.danger),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Toolbar dropdown styled like a filter tab.
class _TabSelect<T> extends StatelessWidget {
  const _TabSelect({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelOf,
  });

  final IconData icon;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelOf;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: colors.muted),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: colors.muted),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              items: items
                  .map((T item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(labelOf?.call(item) ?? '$item'),
                      ))
                  .toList(),
              onChanged: (T? selected) {
                if (selected != null) onChanged(selected);
              },
            ),
          ),
        ],
      ),
    );
  }
}
