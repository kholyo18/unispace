import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';

class SmartReviewPlanPage extends StatelessWidget {
  const SmartReviewPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.smartReviewPlanTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.smartReviewPlanDescription,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(s.smartReviewPlanComingSoon),
                        ),
                      );
                    },
                    child: Text(s.smartReviewPlanCtaCreate),
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
