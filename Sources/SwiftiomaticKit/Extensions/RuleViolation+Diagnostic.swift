import Foundation
import SwiftiomaticSyntax

extension RuleViolation {
  /// Convert to the unified Diagnostic output type.
  package func toDiagnostic() -> Diagnostic {
    let ruleType = RuleRegistry.shared.rule(forID: ruleIdentifier)
    let isCorrectableType = ruleType?.isCorrectable ?? false
    return Diagnostic(
      ruleID: ruleIdentifier,
      source: .lint,
      severity: severity,
      confidence: confidence,
      file: location.file ?? "<unknown>",
      line: location.line ?? 0,
      column: location.column ?? 0,
      message: reason.text,
      suggestion: suggestion,
      canAutoFix: isCorrectableType,
    )
  }
}

#if DEBUG
  /// Install the real `validateReason` implementation that requires `RuleRegistry`.
  ///
  /// Called automatically via a module-level side effect when SwiftiomaticKit is linked.
  private let _installValidateReason: Void = {
    RuleViolation._validateReasonImpl = { reason, ruleIdentifier in
      if reason.text.trimmingTrailingCharacters(in: .whitespaces).last == ".",
        RuleRegistry.shared.rule(forID: ruleIdentifier) != nil
      {
        Console.fatalError(
          """
          Reasons shall not end with a period. Got "\(reason
                      .text)". Either rewrite the rule's summary \
          or set a custom reason in the RuleViolation's constructor.
          """,
        )
      }
    }
  }()

  extension RuleRegistry {
    /// Ensure the validation hook is installed when rules are registered.
    static func installViolationValidation() {
      _ = _installValidateReason
    }
  }
#endif
