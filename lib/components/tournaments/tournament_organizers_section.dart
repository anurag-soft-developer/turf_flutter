import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_query/flutter_query.dart';
import 'package:get/get.dart';

import '../rankings/player_avatar.dart';
import '../shared/app_search_field.dart';
import '../../core/auth/auth_state_controller.dart';
import '../../core/config/constants.dart';
import '../../core/models/paginated_response.dart';
import '../../core/models/user/user_model.dart';
import '../../core/query/query_retry.dart';
import '../../core/services/user_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../tournament/model/tournament_models.dart';
import '../../tournament/detail/tournament_detail_controller.dart';

class TournamentOrganizersSection extends StatelessWidget {
  const TournamentOrganizersSection({
    super.key,
    required this.tournament,
  });

  final TournamentModel tournament;

  @override
  Widget build(BuildContext context) {
    final people = tournament.organizerList;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Organizers',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textSecondaryColor),
          ),
        ),
        const SizedBox(height: 8),
        for (final person in people)
          TournamentOrganizerTile(
            person: person,
            isCreator: tournament.isCreator(person.id),
          ),
      ],
    );
  }
}

class TournamentOrganizerTile extends StatelessWidget {
  const TournamentOrganizerTile({
    super.key,
    required this.person,
    required this.isCreator,
    this.onRemove,
  });

  final TournamentOrganizerRef person;
  final bool isCreator;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          PlayerAvatar(
            url: person.avatar ?? '',
            name: person.displayName,
            userId: person.id,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textColor),
                  ),
                ),
                if (isCreator)
                  const Text(
                    'Creator',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(AppColors.textSecondaryColor),
                    ),
                  ),
              ],
            ),
          ),
          if (onRemove != null && !isCreator)
            IconButton(
              tooltip: 'Remove organizer',
              onPressed: onRemove,
              icon: Icon(Icons.close, color: Colors.red.shade700, size: 20),
            ),
        ],
      ),
    );
  }
}

Future<void> showTournamentAddOrganizerSheet({
  required BuildContext context,
  required TournamentDetailController controller,
  required Set<String> existingIds,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(AppColors.surfaceColor),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _AddOrganizerSheet(
      controller: controller,
      existingIds: existingIds,
    ),
  );
}

class _AddOrganizerSheet extends HookWidget {
  const _AddOrganizerSheet({
    required this.controller,
    required this.existingIds,
  });

  final TournamentDetailController controller;
  final Set<String> existingIds;

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final searchText = useState('');
    final debouncedSearch = useState('');
    final addingId = useState<String?>(null);

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
      ['tournamentOrganizerSearch', query],
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
        .where((user) => user.id != null && user.id!.isNotEmpty && user.id != myId)
        .toList();
    final hasQuery = query.isNotEmpty;
    final isLoading = hasQuery &&
        (usersQuery.isLoading || (usersQuery.isFetching && usersQuery.data == null));
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
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
                  'Add organizer',
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
                          : users.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No users found.',
                                    style: TextStyle(
                                      color: Color(AppColors.textSecondaryColor),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: users.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final user = users[index];
                                    final id = user.id!;
                                    final already = existingIds.contains(id);
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: PlayerAvatar(
                                        url: user.avatar ?? '',
                                        name: user.displayName,
                                        userId: id,
                                        size: 40,
                                      ),
                                      title: Text(user.displayName),
                                      trailing: already
                                          ? const Text(
                                              'Added',
                                              style: TextStyle(
                                                color: Color(
                                                  AppColors.textSecondaryColor,
                                                ),
                                              ),
                                            )
                                          : addingId.value == id
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(Icons.add),
                                      onTap: already || addingId.value != null
                                          ? null
                                          : () async {
                                              addingId.value = id;
                                              final ok = await controller
                                                  .addOrganizer(id);
                                              if (!context.mounted) return;
                                              addingId.value = null;
                                              if (!ok) return;
                                              Navigator.pop(context);
                                              AppSnackbar.success(
                                                title: 'Organizer added',
                                                message:
                                                    '${user.displayName} can manage this tournament.',
                                              );
                                            },
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
