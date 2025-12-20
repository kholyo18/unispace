import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../models/post_model.dart';

enum CommunityBadge {
  helper,
  topContributor,
}

CommunityBadge? badgeForScore(int score) {
  if (score >= 500) return CommunityBadge.topContributor;
  if (score >= 100) return CommunityBadge.helper;
  return null;
}

String badgeLabel(BuildContext context, CommunityBadge badge) {
  switch (badge) {
    case CommunityBadge.helper:
      return S.of(context).helperBadge;
    case CommunityBadge.topContributor:
      return S.of(context).topContributorBadge;
  }
}

int trendingScore(PostModel post, DateTime now) {
  final createdAt = post.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final ageHours = now.difference(createdAt).inHours;
  final freshnessBonus = (72 - ageHours).clamp(0, 72);
  return post.likesCount * 2 + post.commentsCount * 3 + freshnessBonus;
}
