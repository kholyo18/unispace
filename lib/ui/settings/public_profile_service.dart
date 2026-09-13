import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PublicProfileService {
  static Future<Map<String, dynamic>> load(String userId) async {
    final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('readPublicProfile')
        .call<Map<String, dynamic>>({'userId': userId});
    final data = Map<String, dynamic>.from(response.data);
    if (data['canViewContent'] is! bool || data['privacy'] is! Map) {
      throw StateError('Invalid profile response');
    }
    final lastSeen = data['lastSeenAt'];
    if (lastSeen is num)
      data['lastSeenAt'] =
          Timestamp.fromMillisecondsSinceEpoch(lastSeen.toInt());
    return data;
  }

  // Each refresh is authorized again; no full user document or persistent cache.
  static Stream<Map<String, dynamic>> watch(String userId) async* {
    yield await load(userId);
    yield* Stream<void>.periodic(const Duration(seconds: 30))
        .asyncMap((_) => load(userId));
  }
}

/// Uses only the authorized photo URL; never opens the private user document.
class PublicProfilePhoto extends StatelessWidget {
  const PublicProfilePhoto(
      {super.key,
      required this.userId,
      this.fallbackUrl,
      required this.size,
      required this.radius,
      required this.iconSize});
  final String userId;
  final String? fallbackUrl;
  final double size, radius, iconSize;
  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(Icons.person, size: iconSize);
    return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: fallbackUrl == null || fallbackUrl!.isEmpty
              ? placeholder
              : Image.network(fallbackUrl!,
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
        ));
  }
}
