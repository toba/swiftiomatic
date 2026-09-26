import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseOptionalMapTests: RuleTesting {
    private static let message =
        "use 'map' or 'flatMap' on the optional instead of binding it only to return a transform or 'nil'"

    @Test func ifLetFollowedByReturnNil() {
        assertLint(
            UseOptionalMap.self,
            """
            func boundary(named name: String) -> Atom? {
              1️⃣if let value = delimiters[name] { return Atom(value: value) }
              return nil
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func ifLetWithElseReturnNil() {
        assertLint(
            UseOptionalMap.self,
            """
            func label(for id: Int) -> String? {
              1️⃣if let item = items[id] {
                return item.title.uppercased()
              } else {
                return nil
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func shorthandIfLet() {
        assertLint(
            UseOptionalMap.self,
            """
            func doubled(_ value: Int?) -> Int? {
              1️⃣if let value { return value * 2 }
              return nil
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func guardLetReturnNilThenReturnTransform() {
        assertLint(
            UseOptionalMap.self,
            """
            func measure() throws -> Info? {
              1️⃣guard let list = try typeset() else { return nil }

              return Info(ascent: list.ascent, descent: list.descent)
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func getterAndClosureBodies() {
        assertLint(
            UseOptionalMap.self,
            """
            var title: String? {
              1️⃣if let item { return item.name }
              return nil
            }
            let transform = { (x: Int?) -> Int? in
              2️⃣guard let x else { return nil }
              return x + 1
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message), FindingSpec("2️⃣", message: Self.message),
            ]
        )
    }

    @Test func guardAfterOtherStatementsDoesNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func name() -> String? {
              let key = makeKey()
              guard let entry = table[key] else { return nil }
              return entry.name
            }
            """,
            findings: []
        )
    }

    @Test func lastStepOfBindingCascadeDoesNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func name(of type: TypeSyntax) -> String? {
              if let identifier = type.as(IdentifierTypeSyntax.self) { return identifier.name.text }
              if let member = type.as(MemberTypeSyntax.self) { return member.name.text }
              return nil
            }
            """,
            findings: []
        )
    }

    @Test func switchCaseBodyDoesNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func token(for atom: Atom) -> Token? {
              switch atom.type {
                case .fraction:
                  guard let fraction = atom as? Fraction else { return nil }
                  return tokenize(fraction)
                default:
                  return nil
              }
            }
            """,
            findings: []
        )
    }

    @Test func nestedBranchDoesNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func build(_ list: List?) -> Tree? {
              if flag {
                return Tree()
              } else {
                if let table = makeTable(list) {
                  return Tree(atom: table)
                } else {
                  return nil
                }
              }
            }
            """,
            findings: []
        )
    }

    @Test func bodyWithMoreThanOneStatementDoesNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func f(_ x: Int?) -> Int? {
              if let x {
                log(x)
                return x + 1
              }
              return nil
            }
            """,
            findings: []
        )
    }

    @Test func statementBetweenIfAndReturnNilDoesNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func f(_ x: Int?) -> Int? {
              if let x { return x + 1 }
              log("missing")
              return nil
            }
            """,
            findings: []
        )
    }

    @Test func moreThanOneConditionDoesNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func f(_ a: Int?, _ b: Int?) -> Int? {
              if let a, let b { return a + b }
              if let a, a > 0 { return a }
              guard let a, flag else { return nil }
              return a
            }
            """,
            findings: []
        )
    }

    @Test func ifVarAndCaseLetDoNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func f(_ x: Int?, _ e: E) -> Int? {
              if var x { return x + 1 }
              if case let .some(y) = e.value { return y }
              return nil
            }
            """,
            findings: []
        )
    }

    @Test func successReturnsNilOrAwaitsDoesNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func f(_ x: Int?) async -> Int? {
              if let x { return nil }
              return nil
            }
            func g(_ x: Int?) async -> Int? {
              guard let x else { return nil }
              return await compute(x)
            }
            """,
            findings: []
        )
    }

    @Test func elseThatDoesMoreThanReturnNilDoesNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func f(_ x: Int?) -> Int? {
              guard let x else {
                log("missing")
                return nil
              }
              return x + 1
            }
            func g(_ x: Int?) -> Int? {
              if let x { return x + 1 } else { return 0 }
            }
            func h(_ x: Int?) throws -> Int? {
              guard let x else { throw E.missing }
              return x + 1
            }
            """,
            findings: []
        )
    }

    @Test func guardNotFollowedBySingleReturnDoesNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func f(_ x: Int?) -> Int? {
              guard let x else { return nil }
              let y = x + 1
              return y
            }
            """,
            findings: []
        )
    }

    @Test func boundNameUnusedDoesNotTrigger() {
        assertLint(
            UseOptionalMap.self,
            """
            func f(_ x: Int?) -> Int? {
              if let _ = x { return 1 }
              return nil
            }
            func g(_ x: Int?) -> Int? {
              if let y = x { return 1 }
              return nil
            }
            """,
            findings: []
        )
    }
}
