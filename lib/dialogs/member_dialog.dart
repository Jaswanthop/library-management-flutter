import 'package:flutter/material.dart';

import '../data/library_store.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';
import '../widgets/fields.dart';

/// Adds a member, or edits [member] when provided.
Future<bool> showMemberDialog(BuildContext context, {Member? member}) async {
  final bool? saved = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => _MemberFormDialog(member: member),
  );
  return saved ?? false;
}

class _MemberFormDialog extends StatefulWidget {
  const _MemberFormDialog({this.member});

  final Member? member;

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late MembershipTier _tier;
  late bool _isActive;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final Member? member = widget.member;
    _name = TextEditingController(text: member?.name ?? '');
    _email = TextEditingController(text: member?.email ?? '');
    _phone = TextEditingController(text: member?.phone ?? '');
    _tier = member?.tier ?? MembershipTier.student;
    _isActive = member?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final LibraryStore store = LibraryScope.read(context);
    try {
      if (_isEditing) {
        store.updateMember(
          id: widget.member!.id,
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          tier: _tier,
          isActive: _isActive,
        );
      } else {
        store.addMember(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          tier: _tier,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on LibraryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.infoSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _isEditing ? 'Edit member' : 'Register a member',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Membership tier sets how many books can be borrowed.',
                          style: TextStyle(fontSize: 12.5, color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppTextField(
                        controller: _name,
                        label: 'Full name *',
                        hint: 'Ananya Iyer',
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        validator: (String? value) =>
                            (value ?? '').trim().isEmpty
                                ? 'A name is required'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _email,
                        label: 'Email *',
                        hint: 'ananya@example.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (String? value) {
                          final String email = (value ?? '').trim();
                          if (email.isEmpty) return 'An email is required';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _phone,
                        label: 'Phone',
                        hint: '+91 98765 43210',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 14),
                      AppDropdown<MembershipTier>(
                        label: 'Membership tier',
                        value: _tier,
                        items: MembershipTier.values
                            .map((MembershipTier tier) =>
                                DropdownMenuItem<MembershipTier>(
                                  value: tier,
                                  child: Text(
                                    '${tier.label} · up to ${tier.loanLimit} books',
                                  ),
                                ))
                            .toList(),
                        onChanged: (MembershipTier? tier) {
                          if (tier != null) setState(() => _tier = tier);
                        },
                      ),
                      if (_isEditing) ...<Widget>[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text(
                                      'Membership active',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Inactive members cannot borrow books.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: colors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isActive,
                                onChanged: (bool value) =>
                                    setState(() => _isActive = value),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _isEditing ? 'Save changes' : 'Register member',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
