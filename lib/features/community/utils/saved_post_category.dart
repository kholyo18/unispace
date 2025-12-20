import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';

enum SavedPostCategory {
  later,
  exams,
  advice,
}

SavedPostCategory savedPostCategoryFromValue(String? value) {
  switch (value) {
    case 'exams':
      return SavedPostCategory.exams;
    case 'advice':
      return SavedPostCategory.advice;
    case 'later':
    default:
      return SavedPostCategory.later;
  }
}

String savedPostCategoryValue(SavedPostCategory category) {
  switch (category) {
    case SavedPostCategory.later:
      return 'later';
    case SavedPostCategory.exams:
      return 'exams';
    case SavedPostCategory.advice:
      return 'advice';
  }
}

String savedPostCategoryLabel(BuildContext context, SavedPostCategory category) {
  switch (category) {
    case SavedPostCategory.later:
      return S.of(context).savedCategoryLater;
    case SavedPostCategory.exams:
      return S.of(context).savedCategoryExams;
    case SavedPostCategory.advice:
      return S.of(context).savedCategoryAdvice;
  }
}
