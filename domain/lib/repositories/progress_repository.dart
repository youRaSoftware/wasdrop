import '../models/progress_model.dart';

abstract interface class ProgressRepository {
  Future<ProgressModel> getProgress();
  Future<void> saveProgress(ProgressModel progress);
}
