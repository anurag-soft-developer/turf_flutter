import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../../components/rankings/player_avatar.dart';
import '../../components/shared/app_search_field.dart';
import '../../components/shared/confirm_phone_dialog.dart';
import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/models/user/user_model.dart';
import '../../core/query/query_retry.dart';
import '../../core/services/user_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/phone_util.dart';
import 'team_invites_controller.dart';

Future<void> showTeamInviteSheet({
  required BuildContext context,
  required TeamInvitesController controller,
  Set<String> alreadyInvitedTargets = const {},
}) {
  controller.seedSentTargets(alreadyInvitedTargets);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(AppColors.surfaceColor),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => TeamInviteSheet(controller: controller),
  );
}

bool _looksLikeContact(String query) {
  final q = query.trim();
  if (q.isEmpty) return false;
  if (q.contains('@')) return true;
  return looksLikePhone(q) || hasPhoneCountryCode(q);
}

class TeamInviteSheet extends HookWidget {
  const TeamInviteSheet({super.key, required this.controller});

  final TeamInvitesController controller;

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final searchText = useState('');
    final debouncedSearch = useState('');

    useEffect(() {
      void listener() => searchText.value = searchController.text;
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 400), () {
        debouncedSearch.value = searchText.value.trim();
      });
      return timer.cancel;
    }, [searchText.value]);

    final query = debouncedSearch.value;
    final usersQuery = useQuery<PaginatedResponse<UserModel>, Object>(
      ['teamInviteUserSearch', query],
      (_) async {
        if (query.isEmpty) {
          return EmptyPaginatedResponse<UserModel>();
        }
        return await UserService().searchPublicProfiles(
              query: query,
              page: 1,
              limit: 20,
            ) ??
            EmptyPaginatedResponse<UserModel>();
      },
      enabled: query.isNotEmpty,
      retry: noRetry,
    );

    final myId = Get.find<AuthStateController>().user?.id;
    final users = (usersQuery.data?.data ?? const <UserModel>[])
        .where((u) => u.id != null && u.id!.isNotEmpty && u.id != myId)
        .toList();

    final hasQuery = query.isNotEmpty;
    final isLoading = hasQuery &&
        (usersQuery.isLoading ||
            (usersQuery.isFetching && usersQuery.data == null));
    final searchDone =
        hasQuery && !isLoading && !usersQuery.isFetching;
    final showContactCard =
        searchDone && users.isEmpty && _looksLikeContact(query);
    final showNoResults =
        searchDone && users.isEmpty && !_looksLikeContact(query);

    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: maxHeight,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Invite to team',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.textColor),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Search by name, email, or phone.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(AppColors.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 14),
                AppSearchField(
                  controller: searchController,
                  autofocus: true,
                  hintText: 'Search name, email, or phone',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: !hasQuery
                      ? const Center(
                          child: Text(
                            'Start typing to find people',
                            style: TextStyle(
                              color: Color(AppColors.textSecondaryColor),
                            ),
                          ),
                        )
                      : isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(AppColors.primaryColor),
                                ),
                              ),
                            )
                          : showContactCard
                              ? ListView(
                                  children: [
                                    _InviteContactRow(
                                      contact: query,
                                      controller: controller,
                                    ),
                                  ],
                                )
                              : showNoResults
                                  ? const Center(
                                      child: Text(
                                        'No users found.\nTry an email or phone number.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(
                                            AppColors.textSecondaryColor,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: users.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final user = users[index];
                                        return _InviteUserRow(
                                          user: user,
                                          controller: controller,
                                        );
                                      },
                                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteUserRow extends StatelessWidget {
  const _InviteUserRow({
    required this.user,
    required this.controller,
  });

  final UserModel user;
  final TeamInvitesController controller;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName;
    final userId = user.id ?? '';

    return _InviteTargetCard(
      leading: PlayerAvatar(url: user.avatar ?? '', name: name, size: 40),
      title: name,
      isSent: () => controller.isInviteSent(userId),
      isBusy: () => controller.invitingTargetKey.value == userId,
      onInvite: userId.isEmpty
          ? null
          : () => controller.invite(inviteeUserId: userId),
      controller: controller,
    );
  }
}

class _InviteContactRow extends StatelessWidget {
  const _InviteContactRow({
    required this.contact,
    required this.controller,
  });

  final String contact;
  final TeamInvitesController controller;

  static String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  bool _matchesContactTarget(String key) {
    final label = contact.trim();
    if (label.contains('@')) {
      return key == TeamInvitesController.contactKey(email: label);
    }
    if (!key.startsWith('phone:')) return false;
    final a = _digits(key);
    final b = _digits(label);
    if (a.isEmpty || b.isEmpty) return false;
    return a.endsWith(b) || b.endsWith(a);
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = contact.contains('@');
    final label = contact.trim();

    return _InviteTargetCard(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(AppColors.primaryColor).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          isEmail ? Icons.email_outlined : Icons.phone_outlined,
          size: 20,
          color: const Color(AppColors.primaryColor),
        ),
      ),
      title: label,
      subtitle: 'Not registered yet',
      isSent: () => controller.sentInviteTargets.any(_matchesContactTarget),
      isBusy: () {
        final key = controller.invitingTargetKey.value;
        return controller.inviting.value &&
            key != null &&
            _matchesContactTarget(key);
      },
      onInvite: () async {
        try {
          final identifier = await resolveAuthIdentifier(context, label);
          if (identifier == null) return;
          await controller.invite(
            email: identifier.email,
            phone: identifier.phone,
          );
        } on FormatException catch (e) {
          AppSnackbar.error(
            title: 'Invalid contact',
            message: e.message,
          );
        }
      },
      controller: controller,
    );
  }
}

class _InviteTargetCard extends StatelessWidget {
  const _InviteTargetCard({
    required this.leading,
    required this.title,
    required this.isSent,
    required this.isBusy,
    required this.controller,
    required this.onInvite,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool Function() isSent;
  final bool Function() isBusy;
  final TeamInvitesController controller;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(AppColors.dividerColor).withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textColor),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            controller.sentInviteTargets.length;
            controller.invitingTargetKey.value;
            controller.inviting.value;
            final sent = isSent();
            final busy = isBusy();
            return _InviteActionButton(
              isSent: sent,
              isBusy: busy,
              onTap: sent || busy || onInvite == null ? null : onInvite,
            );
          }),
        ],
      ),
    );
  }
}

class _InviteActionButton extends StatelessWidget {
  const _InviteActionButton({
    required this.isSent,
    required this.isBusy,
    required this.onTap,
  });

  final bool isSent;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSent
        ? const Color(AppColors.dividerColor)
        : const Color(AppColors.primaryColor);
    final foregroundColor =
        isSent ? const Color(AppColors.textSecondaryColor) : Colors.white;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: isBusy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSent
                          ? Icons.check_circle_outline
                          : Icons.person_add_alt_1_rounded,
                      size: 13,
                      color: foregroundColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSent ? 'Sent' : 'Invite',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: foregroundColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
