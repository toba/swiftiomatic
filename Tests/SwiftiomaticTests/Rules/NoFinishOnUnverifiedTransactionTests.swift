@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoFinishOnUnverifiedTransactionTests: RuleTesting {
    private static let message =
        "do not call 'finish()' on an unverified transaction. Finish a transaction only after you verify it and deliver the content"

    @Test func finishInUnverifiedCaseFlagged() {
        assertLint(
            NoFinishOnUnverifiedTransaction.self,
            """
            func handle(_ result: VerificationResult<Transaction>) async {
              switch result {
              case .verified(let transaction):
                await deliver(transaction)
                await transaction.finish()
              case .unverified(let transaction, _):
                await 1️⃣transaction.finish()
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func letBindingAndQualifiedCaseFlagged() {
        assertLint(
            NoFinishOnUnverifiedTransaction.self,
            """
            func handle(_ result: VerificationResult<Transaction>) async {
              switch result {
              case let VerificationResult.unverified(transaction, error):
                log(error)
                await 1️⃣transaction.finish()
              default:
                break
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func finishInIfCaseUnverifiedFlagged() {
        assertLint(
            NoFinishOnUnverifiedTransaction.self,
            """
            func handle(_ update: VerificationResult<Transaction>) async {
              if case .unverified(let transaction, _) = update {
                await 1️⃣transaction.finish()
              } else if case .verified(let transaction) = update {
                await transaction.finish()
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func finishInVerifiedCaseNotFlagged() {
        assertLint(
            NoFinishOnUnverifiedTransaction.self,
            """
            func handle(_ result: VerificationResult<Transaction>) async {
              switch result {
              case .verified(let transaction):
                await transaction.finish()
              case .unverified(let transaction, let error):
                report(transaction, error)
              }
            }
            """,
            findings: []
        )
    }

    @Test func otherCallsInUnverifiedCaseNotFlagged() {
        assertLint(
            NoFinishOnUnverifiedTransaction.self,
            """
            func handle(_ result: VerificationResult<Transaction>) async {
              switch result {
              case .unverified(let transaction, _):
                await transaction.finish(reason: .refund)
                finish()
                logger.finishing()
              case .verified:
                break
              }
            }
            """,
            findings: []
        )
    }
}
