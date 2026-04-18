@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct SimplifyGenericConstraintsTests: RuleTesting {
  @Test func functionWithSimpleConstraint() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func process<T>(_ value: T) where 1️⃣T: Codable {}
        """,
      expected: """
        func process<T: Codable>(_ value: T) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func structWithSimpleConstraint() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        struct Foo<T> where 1️⃣T: Hashable {}
        """,
      expected: """
        struct Foo<T: Hashable> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func multipleConstraints() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        struct Foo<T, U> where 1️⃣T: Hashable, 2️⃣U: Codable {}
        """,
      expected: """
        struct Foo<T: Hashable, U: Codable> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
        FindingSpec("2️⃣", message: "constraint on 'U' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func sameTypeConstraintNotFlagged() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func foo<T>(_ value: T) where T == Int {}
        """,
      expected: """
        func foo<T>(_ value: T) where T == Int {}
        """,
      findings: []
    )
  }

  @Test func associatedTypeConstraintNotFlagged() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func foo<C: Collection>(_ c: C) where C.Element: Hashable {}
        """,
      expected: """
        func foo<C: Collection>(_ c: C) where C.Element: Hashable {}
        """,
      findings: []
    )
  }

  @Test func alreadyInlineNotFlagged() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func process<T: Codable>(_ value: T) {}
        """,
      expected: """
        func process<T: Codable>(_ value: T) {}
        """,
      findings: []
    )
  }

  @Test func noGenericParamsNotFlagged() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func process(_ value: Int) {}
        """,
      expected: """
        func process(_ value: Int) {}
        """,
      findings: []
    )
  }

  @Test func enumWithConstraint() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        enum Result<Value, Error> where 1️⃣Value: Decodable, 2️⃣Error: Swift.Error {}
        """,
      expected: """
        enum Result<Value: Decodable, Error: Swift.Error> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'Value' can be simplified to an inline constraint"),
        FindingSpec("2️⃣", message: "constraint on 'Error' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func mixedConstraints() {
    // Only the simple conformance is inlined; the associated type constraint remains
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func foo<C>(_ c: C) where 1️⃣C: Collection, C.Element: Hashable {}
        """,
      expected: """
        func foo<C: Collection>(_ c: C) where C.Element: Hashable {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'C' can be simplified to an inline constraint"),
      ]
    )
  }

  // MARK: - Adapted from SwiftFormat reference tests

  @Test func classWithSimpleConstraint() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        class Bar<Element> where 1️⃣Element: Equatable {
            // ...
        }
        """,
      expected: """
        class Bar<Element: Equatable> {
            // ...
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'Element' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func actorWithSimpleConstraint() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        actor Worker<T> where 1️⃣T: Sendable {}
        """,
      expected: """
        actor Worker<T: Sendable> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func preserveExistingInlineConstraints() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        struct Foo<T: Equatable, U> where 1️⃣U: Codable {}
        """,
      expected: """
        struct Foo<T: Equatable, U: Codable> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'U' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func realWorldURLImageExample() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        public struct URLImage<Content, Placeholder> where 1️⃣Content: View, 2️⃣Placeholder: View {
            let url: URL
            let content: (Image) -> Content
            let placeholder: () -> Placeholder
        }
        """,
      expected: """
        public struct URLImage<Content: View, Placeholder: View> {
            let url: URL
            let content: (Image) -> Content
            let placeholder: () -> Placeholder
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'Content' can be simplified to an inline constraint"),
        FindingSpec("2️⃣", message: "constraint on 'Placeholder' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func functionWithMultipleGenericParameters() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func compare<T, U>(_ lhs: T, _ rhs: U) where 1️⃣T: Equatable, 2️⃣U: Comparable {}
        """,
      expected: """
        func compare<T: Equatable, U: Comparable>(_ lhs: T, _ rhs: U) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
        FindingSpec("2️⃣", message: "constraint on 'U' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func functionWithMixedConstraints() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func process<T>(_ value: T) where 1️⃣T: Collection, T.Element == String {}
        """,
      expected: """
        func process<T: Collection>(_ value: T) where T.Element == String {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func partialSimplificationWithUnknownGeneric() {
    // U is not in the struct's generic parameter list
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        struct Foo<T, U> where 1️⃣T: Hashable, U.Element == String {}
        """,
      expected: """
        struct Foo<T: Hashable, U> where U.Element == String {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func structWithFourGenerics() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        struct Foo<A, B, C, D> where 1️⃣A: Hashable, 2️⃣B: Codable, 3️⃣C: Equatable, 4️⃣D: Comparable {}
        """,
      expected: """
        struct Foo<A: Hashable, B: Codable, C: Equatable, D: Comparable> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'A' can be simplified to an inline constraint"),
        FindingSpec("2️⃣", message: "constraint on 'B' can be simplified to an inline constraint"),
        FindingSpec("3️⃣", message: "constraint on 'C' can be simplified to an inline constraint"),
        FindingSpec("4️⃣", message: "constraint on 'D' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func preserveConstraintsForGenericsNotInParameterList() {
    // U is not in the function's generic parameters
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func process<T>(value: T) where U: Hashable {}
        """,
      expected: """
        func process<T>(value: T) where U: Hashable {}
        """,
      findings: []
    )
  }

  @Test func protocolMethodWithWhereClause() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        protocol Foo {
            func bar<T>(_ value: T) async throws -> T where 1️⃣T: Codable
        }
        """,
      expected: """
        protocol Foo {
            func bar<T: Codable>(_ value: T) async throws -> T
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func preserveProtocolMethodWithoutGenericParameters() {
    // Protocol method has where clause but no generic parameters
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        protocol DatabaseMigrator {
            func runDatabaseMigration(migration: T.Type, version: Int) throws where T: Migration
        }
        """,
      expected: """
        protocol DatabaseMigrator {
            func runDatabaseMigration(migration: T.Type, version: Int) throws where T: Migration
        }
        """,
      findings: []
    )
  }

  @Test func preserveProtocolMethodWithAssociatedTypeConstraint() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        protocol Migration {}

        protocol DatabaseMigrator {
            associatedtype T
            func runDatabaseMigration(migration: T.Type, version: Int) throws where T: Migration
        }
        """,
      expected: """
        protocol Migration {}

        protocol DatabaseMigrator {
            associatedtype T
            func runDatabaseMigration(migration: T.Type, version: Int) throws where T: Migration
        }
        """,
      findings: []
    )
  }

  @Test func preserveMethodWithWhereClauseReferencingOuterGeneric() {
    // Function with no generic parameters referencing generic from containing type
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        struct Container<T> {
            func process() where T: Codable {}
        }
        """,
      expected: """
        struct Container<T> {
            func process() where T: Codable {}
        }
        """,
      findings: []
    )
  }

  @Test func simplifyProtocolMethodWithGenerics() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        protocol DatabaseMigrator {
            func runDatabaseMigration<T>(migration: T.Type, version: Int) throws where 1️⃣T: Migration
        }
        """,
      expected: """
        protocol DatabaseMigrator {
            func runDatabaseMigration<T: Migration>(migration: T.Type, version: Int) throws
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func simplifyProtocolMethodFollowedByAnotherMethod() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        protocol DatabaseMigrator {
            func runDatabaseMigration<T>(migration: T.Type, version: Int) throws where 1️⃣T: Migration
            func migrateDatabase(version: Int, migration: () throws -> Void) throws
        }
        """,
      expected: """
        protocol DatabaseMigrator {
            func runDatabaseMigration<T: Migration>(migration: T.Type, version: Int) throws
            func migrateDatabase(version: Int, migration: () throws -> Void) throws
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func sameConstraintOnDifferentTypes() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func test<T, U>(_ a: T, _ b: U) where 1️⃣T: Service, 2️⃣U: Service {}
        """,
      expected: """
        func test<T: Service, U: Service>(_ a: T, _ b: U) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
        FindingSpec("2️⃣", message: "constraint on 'U' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func inlineForOneTypeAndWhereForAnother() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func test<T: Service, U>(_ a: T, _ b: U) where 1️⃣U: Service {}
        """,
      expected: """
        func test<T: Service, U: Service>(_ a: T, _ b: U) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'U' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func manyGenericsWithMixedConstraints() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        struct Foo<A, B, C, D, E> where 1️⃣A: Hashable, 2️⃣B: Collection, B.Element == String, 3️⃣C: Codable, D.Index == Int, 4️⃣E: Equatable {
            var values: (A, B, C, D, E)
        }
        """,
      expected: """
        struct Foo<A: Hashable, B: Collection, C: Codable, D, E: Equatable> where B.Element == String, D.Index == Int {
            var values: (A, B, C, D, E)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'A' can be simplified to an inline constraint"),
        FindingSpec("2️⃣", message: "constraint on 'B' can be simplified to an inline constraint"),
        FindingSpec("3️⃣", message: "constraint on 'C' can be simplified to an inline constraint"),
        FindingSpec("4️⃣", message: "constraint on 'E' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func whereClauseWithOnlyConcreteTypes() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        struct Foo<T, U> where T == U {}
        """,
      expected: """
        struct Foo<T, U> where T == U {}
        """,
      findings: []
    )
  }
}
