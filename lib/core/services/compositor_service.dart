import '../models/composite_job.dart';

abstract class CompositorService {
  Future<String> renderStrip(CompositeJob job);
}
