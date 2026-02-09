import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSpace/generated/l10n.dart';

import 'privacy/privacy_account_overview_tab.dart';
import 'drawer_screens.dart';

enum _SecurityPrivacySegment { security, privacy }

class SecurityPrivacyScreen extends StatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen> {
  static const _segmentKey = 'settings_security_privacy_segment';
  _SecurityPrivacySegment _segment = _SecurityPrivacySegment.security;

  @override
  void initState() {
    super.initState();
    _loadSegment();
  }

  Future<void> _loadSegment() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_segmentKey);
    if (!mounted || value == null) return;
    setState(() {
      _segment = value == 'privacy'
          ? _SecurityPrivacySegment.privacy
          : _SecurityPrivacySegment.security;
    });
  }

  Future<void> _saveSegment(_SecurityPrivacySegment value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _segmentKey,
      value == _SecurityPrivacySegment.privacy ? 'privacy' : 'security',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.securityPrivacyTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: CupertinoSlidingSegmentedControl<_SecurityPrivacySegment>(
                groupValue: _segment,
                children: {
                  _SecurityPrivacySegment.security: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(s.securitySegmentTitle),
                  ),
                  _SecurityPrivacySegment.privacy: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(s.privacySegmentTitle),
                  ),
                },
                onValueChanged: (value) {
                  if (value == null) return;
                  setState(() => _segment = value);
                  _saveSegment(value);
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: IndexedStack(
              index: _segment == _SecurityPrivacySegment.security ? 0 : 1,
              children: const [
                SecurityCenterContent(),
                PrivacyAccountOverviewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
