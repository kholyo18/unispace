import 'app_settings.dart';

/// Persist only explicit changes, never a potentially stale profile snapshot.
Map<String, dynamic> profileSettingsPatch(
        {ProfileVisibility? profileVisibility,
        bool? showEmailInProfile,
        bool? twoFactorEnabled}) =>
    {
      if (profileVisibility != null)
        'profileVisibility': profileVisibility == ProfileVisibility.private
            ? 'private'
            : 'public',
      if (showEmailInProfile != null) 'showEmailInProfile': showEmailInProfile,
      if (profileVisibility != null || showEmailInProfile != null) 'privacy': {
        if (profileVisibility != null) 'privateAccount': profileVisibility == ProfileVisibility.private,
        if (showEmailInProfile != null) 'showEmailOnProfile': showEmailInProfile,
      },
      if (twoFactorEnabled != null) 'twoFactorEnabled': twoFactorEnabled,
    };
