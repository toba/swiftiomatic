---
# vu2-he3
title: Migrate PrettyPrint tests to Swift Testing
status: completed
type: task
priority: normal
created_at: 2026-04-14T02:55:02Z
updated_at: 2026-04-14T03:24:19Z
parent: rwb-wt3
blocked_by:
    - 9mz-jmv
sync:
    github:
        issue_number: "279"
        synced_at: "2026-04-14T03:28:23Z"
---

Convert 71 test files in `Tests/SwiftiomaticTests/PrettyPrint/` from XCTest to Swift Testing. Blocked by infrastructure rewrite (`9mz-jmv`).

## Files

69 files extend `PrettyPrintTestCase`, 2 extend `WhitespaceTestCase`. After infrastructure converts these base classes to free functions, each file needs:

- [ ] Replace `import XCTest` with `import Testing` (where present)
- [ ] Replace `final class FooTests: PrettyPrintTestCase` with `@Suite struct FooTests`
- [ ] Replace `final class FooTests: WhitespaceTestCase` with `@Suite struct FooTests`
- [ ] Replace `func testFoo()` with `@Test func foo()`
- [ ] Update `assertPrettyPrintEqual(...)` calls (now a free function, same signature minus file:/line:)
- [ ] Update `assertWhitespaceLint(...)` calls (same)

## Scope

This is largely mechanical — no logic changes needed. The assertion helpers will already be free functions after `9mz-jmv`.

### PrettyPrintTestCase subclasses (69 files)
AccessorTests, ArrayDeclTests, AsExprTests, AssignmentExprTests, AttributeTests, AvailabilityConditionTests, BackDeployAttributeTests, BacktickTests, BinaryOperatorExprTests, BorrowExprTests, ClassDeclTests, ClosureExprTests, CommaTests, CommentTests, ConstrainedSugarTypeTests, ConsumeExprTests, CopyExprSyntax, DeclNameArgumentTests, DeinitializerDeclTests, DictionaryDeclTests, DifferentiationAttributeTests, DiscardStmtTests, DoStmtTests, EnumDeclTests, ExpressionModifierTests, ExtensionDeclTests, ForInStmtTests, FunctionCallTests, FunctionDeclTests, FunctionTypeTests, GarbageTextTests, GuardStmtTests, IfConfigTests, IfStmtTests, IgnoreNodeTests, ImportTests, IndentBlankLinesTests, InitializerDeclTests, KeyPathExprTests, LineNumbersTests, MacroCallTests, MacroDeclTests, MemberAccessExprTests, MemberTypeIdentifierTests, NewlineTests, ObjectLiteralExprTests, OperatorDeclTests, ParameterPackTests, ParenthesizedExprTests, PatternBindingTests, ProtocolDeclTests, RepeatStmtTests, RespectsExistingLineBreaksTests, SemicolonTests, StringTests, StructDeclTests, SubscriptDeclTests, SubscriptExprTests, SwitchCaseIndentConfigTests, SwitchStmtTests, TernaryExprTests, TupleDeclTests, TypeAliasTests, ValueGenericsTests, VariableDeclTests, WhileStmtTests, YieldStmtTests

### WhitespaceTestCase subclasses (2 files)
WhitespaceLintTests, WhitespaceTestCase (base — converted in 9mz-jmv)

## Notes

- None of these files define setUp/tearDown
- None use XCTest assertions directly (all go through base class helpers)
- Some files import `XCTest` explicitly, others inherit it — remove all explicit imports
- Test methods use `throws` — keep that, Swift Testing supports it
