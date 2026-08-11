import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/error/error.dart';

abstract class GuardRule extends AnalysisRule {
  GuardRule(String name, String description)
    : super(name: name, description: description);
}

LintCode warningCode(String name, String message, String correction) =>
    LintCode(
      name,
      message,
      correctionMessage: correction,
      severity: DiagnosticSeverity.WARNING,
    );
