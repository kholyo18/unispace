import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../../ui/widgets/empty_state.dart';
import '../data/community_repository.dart';
import '../models/community_notification.dart';
import 'post_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    required this.repository,
    required this.userId,
  });

  final CommunityRepository repository;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).notificationsTitle),
        actions: [
          IconButton(
            tooltip: S.of(context).markAllRead,
            onPressed: () async {
              await repository.markAllRead(userId);
            },
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: StreamBuilder<List<CommunityNotification>>(
        stream: repository.streamNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(S.of(context).somethingWentWrong));
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none,
              title: S.of(context).noNotificationsTitle,
              subtitle: S.of(context).noNotificationsSubtitle,
            );
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: Icon(_iconForType(notification.type)),
                title: Text(_titleForNotification(context, notification)),
                subtitle: Text(_formatRelativeTime(
                  context,
                  notification.createdAt,
                )),
                trailing: notification.isRead
                    ? null
                    : Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                onTap: () async {
                  await repository.markNotificationRead(notification.id);
                  final post = await repository.fetchPost(notification.postId);
                  if (post == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).postNotFound)),
                      );
                    }
                    return;
                  }
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailsScreen(
                          repository: repository,
                          post: post,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'comment':
        return Icons.chat_bubble_outline;
      case 'reply':
        return Icons.reply_outlined;
      case 'like':
      default:
        return Icons.favorite_border;
    }
  }

  String _titleForNotification(
    BuildContext context,
    CommunityNotification notification,
  ) {
    switch (notification.type) {
      case 'comment':
        if (notification.snippet != null &&
            notification.snippet!.trim().isNotEmpty) {
          return S.of(context)
              .notificationComment(notification.snippet!.trim());
        }
        return S.of(context).notificationCommentNoSnippet;
      case 'reply':
        if (notification.snippet != null &&
            notification.snippet!.trim().isNotEmpty) {
          return S.of(context)
              .notificationReply(notification.snippet!.trim());
        }
        return S.of(context).notificationReplyNoSnippet;
      case 'like':
      default:
        return S.of(context).notificationLike;
    }
  }

  String _formatRelativeTime(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return S.of(context).timeJustNow;
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return S.of(context).timeJustNow;
    }
    if (difference.inHours < 1) {
      return S.of(context).timeMinutesAgo(difference.inMinutes);
    }
    if (difference.inDays < 1) {
      return S.of(context).timeHoursAgo(difference.inHours);
    }
    return S.of(context).timeDaysAgo(difference.inDays);
  }
}
