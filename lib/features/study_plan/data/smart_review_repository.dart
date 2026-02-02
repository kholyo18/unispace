import '../domain/models/smart_review_plan.dart';
import 'smart_review_storage.dart';

class SmartReviewRepository {
  SmartReviewRepository(this._storage);

  final SmartReviewStorage _storage;

  Future<SmartReviewPlan?> loadPlan() => _storage.loadPlan();

  Future<void> savePlan(SmartReviewPlan plan) => _storage.savePlan(plan);

  Future<void> clearPlan() => _storage.clearPlan();
}
