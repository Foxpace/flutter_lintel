import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

abstract class LintelAnalysisRuleTest extends AnalysisRuleTest {
  void givenGuardConfiguration(String source) {
    newFile('$testPackageRootPath/lintel.yaml', source);
  }

  String givenLibFile(String relativePath, String source) {
    final path = '$testPackageLibPath/$relativePath';
    newFile(path, source);
    return path;
  }

  String givenTestFile(String relativePath, String source) {
    final path = '$testPackageRootPath/test/$relativePath';
    newFile(path, source);
    return path;
  }

  Future<void> thenReportsLint(
    String path, {
    required int offset,
    required int length,
  }) => assertDiagnosticsInFile(path, [lint(offset, length)]);

  Future<void> thenReportsNoDiagnostics(String path) =>
      assertDiagnosticsInFile(path, const []);
}
