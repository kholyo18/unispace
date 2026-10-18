/// Recognizes only the invitation route; joining remains an explicit action.
bool isChatGroupJoinLink(Uri uri) =>
    uri.scheme == 'unispace' &&
    uri.host == 'group' &&
    uri.path == '/join' &&
    uri.userInfo.isEmpty &&
    !uri.hasPort &&
    uri.fragment.isEmpty &&
    uri.queryParametersAll.length == 2 &&
    uri.queryParametersAll.values.every((values) => values.length == 1) &&
    RegExp(r'^group_[A-Za-z0-9_-]{1,254}$')
        .hasMatch(uri.queryParameters['groupId'] ?? '') &&
    RegExp(r'^[a-f0-9]{64}$').hasMatch(uri.queryParameters['token'] ?? '');
