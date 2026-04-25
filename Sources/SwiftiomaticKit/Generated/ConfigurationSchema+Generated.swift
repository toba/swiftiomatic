// Auto-generated — do not edit.

import Foundation

/// The JSON Schema for `swiftiomatic.json` configuration files, embedded
/// as a decoded `JSONValue` for runtime validation.
package enum ConfigurationSchema {
    package static let schema: JSONValue = {
        let json = ##"""
{
  "$defs" : {
    "lintOnlyBase" : {
      "description" : "Lint-only rule configuration.",
      "properties" : {
        "lint" : {
          "default" : "warn",
          "description" : "Finding severity when the rule is active. Options: warn, error, no.",
          "enum" : [
            "warn",
            "error",
            "no"
          ],
          "type" : "string"
        }
      },
      "type" : "object"
    },
    "ruleBase" : {
      "description" : "Rule configuration with rewrite and lint properties.",
      "properties" : {
        "lint" : {
          "default" : "warn",
          "description" : "Finding severity when the rule is active. Options: warn, error, no.",
          "enum" : [
            "warn",
            "error",
            "no"
          ],
          "type" : "string"
        },
        "rewrite" : {
          "default" : true,
          "description" : "Whether the rule auto-fixes source code.",
          "type" : "boolean"
        }
      },
      "type" : "object"
    }
  },
  "$id" : "https://raw.githubusercontent.com/toba/swiftiomatic/refs/heads/main/schema.json",
  "$schema" : "https://json-schema.org/draft/2020-12/schema",
  "additionalProperties" : false,
  "description" : "Configuration for Swiftiomatic formatter and linter.",
  "properties" : {
    "$schema" : {
      "description" : "JSON Schema reference URL.",
      "type" : "string"
    },
    "access" : {
      "additionalProperties" : false,
      "description" : "access rule group.",
      "properties" : {
        "extensionAccessLevel" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Controls placement of access level modifiers on extensions vs. their members.\n\nThe behavior of this rule is controlled by `Configuration.extensionAccessControl.placement`:\n\n- `onMembers` (default): Access levels on extensions are moved to individual members.\n- `onExtension`: When all members share the same access level, it is hoisted to the extension.\n\nLint: A lint error is raised when access control placement doesn't match the configuration.\n\nFormat: Access control modifiers are moved to match the configured placement.\n",
          "properties" : {
            "placement" : {
              "default" : "onMembers",
              "description" : "placement Options: onMembers, onExtension.",
              "enum" : [
                "onMembers",
                "onExtension"
              ],
              "type" : "string"
            }
          }
        },
        "fileScopedDeclarationPrivacy" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Declarations at file scope with effective private access should be consistently declared as\neither `fileprivate` or `private`, determined by configuration.\n\nLint: If a file-scoped declaration has formal access opposite to the desired access level in the\n      formatter's configuration, a lint error is raised.\n\nFormat: File-scoped declarations that have formal access opposite to the desired access level in\n        the formatter's configuration will have their access level changed.\n",
          "properties" : {
            "accessLevel" : {
              "default" : "private",
              "description" : "accessLevel Options: private, fileprivate.",
              "enum" : [
                "private",
                "fileprivate"
              ],
              "type" : "string"
            }
          }
        },
        "preferFinalClasses" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer `final class` unless a class is designed for subclassing.\n\nClasses should be `final` by default to communicate that they are not designed to be\nsubclassed. Classes are left non-final if they are `open`, have \"Base\" in the name,\nhave a comment mentioning \"base\" or \"subclass\", or are subclassed within the same file.\n\nWhen a class is made `final`, any `open` members are converted to `public` since\n`final` classes cannot have `open` members.\n\nLint: A non-final, non-open class declaration raises a warning.\n\nFormat: The `final` modifier is added and `open` members are converted to `public`.\n [opt-in]"
        },
        "privateStateVariables" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Add `private` to `@State` properties without explicit access control.\n\nSwiftUI `@State` and `@StateObject` properties should be `private` because they are\nowned by the view and should not be set from outside. If no access control modifier is\npresent, `private` is added. Existing access modifiers (including `private(set)`) and\n`@Previewable` properties are left unchanged.\n\nLint: A `@State` or `@StateObject` property without access control raises a warning.\n\nFormat: The `private` modifier is added before the binding keyword.\n [opt-in]"
        }
      },
      "type" : "object"
    },
    "afterGuardStatements" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove blank lines between consecutive guard statements and insert a blank line after\nthe last guard.\n\nGuard blocks at the top of a function form a precondition section. Keeping them tight\n(no blank lines between them) and separated from the body (one blank line after) improves\nreadability. Comments between guards break the \"consecutive\" chain — each guard followed\nby a comment gets its own trailing blank line.\n\nLint: If there are blank lines between consecutive guards, or no blank line after the\n      last guard before other code, a lint warning is raised.\n\nFormat: Blank lines between consecutive guards are removed. A blank line is inserted\n        after the last guard when followed by non-guard code.\n [opt-in]"
    },
    "afterImports" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Insert a blank line after the last import statement.\n\nWhen import statements are followed directly by other declarations without a separating blank\nline, readability suffers. This rule ensures exactly one blank line separates the import block\nfrom the rest of the code.\n\nLint: If the first non-import declaration is not preceded by a blank line, a lint warning is raised.\n\nFormat: A blank line is inserted after the last import statement.\n"
    },
    "afterSwitchCase" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Insert a blank line after multiline switch case bodies.\n\nWhen a switch case body spans multiple statements, a blank line after it improves readability\nby visually separating it from the next case. Single-statement cases do not require blank lines.\nThe last case in a switch is never followed by a blank line (the closing brace provides\nvisual separation).\n\nLint: If a multiline case body is not followed by a blank line, a lint warning is raised.\n      If the last case is followed by a blank line before `}`, a lint warning is raised.\n\nFormat: Blank lines are inserted after multiline cases and removed after the last case.\n [opt-in]"
    },
    "ambiguousTrailingClosureOverload" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Overloads with only a closure argument should not be disambiguated by parameter labels.\n\nLint: If two overloaded functions with one closure parameter appear in the same scope, a lint\n      error is raised.\n",
      "unevaluatedProperties" : false
    },
    "avoidNoneName" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Avoid naming enum cases or static members `none`.\n\nA `case none` or `static let none` (or `static var`/`class var`) can be confused with\n`Optional<T>.none`. Especially when the enclosing type itself becomes optional, the compiler\nwill silently prefer `Optional.none`, leading to subtle bugs.\n\nLint: A warning is raised for any `case none` (without associated values), or any `static`/\n`class` property named `none`.\n\nFormat: Not auto-fixed; renaming requires understanding the call sites.\n [opt-in]"
    },
    "beforeAndAfterMark" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Insert blank lines before and after `// MARK:` comments.\n\nMARK comments serve as section dividers. Surrounding them with blank lines makes the\nvisual separation clear. A blank line before MARK is skipped when the MARK immediately\nfollows an opening brace (start of scope). A blank line after MARK is skipped when\nthe MARK immediately precedes a closing brace (end of scope) or end of file.\n\nLint: If a MARK comment is missing a blank line before or after it, a lint warning is raised.\n\nFormat: Blank lines are inserted around MARK comments.\n [opt-in]"
    },
    "beforeControlFlowBlocks" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Insert a blank line before control flow statements with multi-line bodies.\n\nWhen a `for`, `while`, `repeat`, `if`, `switch`, `do`, or `defer` statement has a\nmulti-line body and is preceded by another statement, a blank line before it improves\nreadability. Single-line (inline) control flow is excluded. Guard statements are excluded\nbecause `BlankLinesAfterGuardStatements` already handles spacing around guards.\n\nLint: If a multi-line control flow statement is not preceded by a blank line, a lint\n      warning is raised.\n\nFormat: A blank line is inserted before the control flow statement.\n [opt-in]"
    },
    "betweenScopes" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Insert a blank line after declarations with multi-line bodies.\n\nWhen a type declaration (class, struct, enum, extension, protocol, actor) or function\ndeclaration has a multi-line body, a blank line after it improves readability by\nvisually separating it from the next declaration. Single-line (inline) bodies are\nexcluded. This rule operates at the top level and inside type member blocks — not\ninside function bodies (if/for/while don't need separation).\n\nLint: If a multi-line scoped declaration is not followed by a blank line, a lint\n      warning is raised.\n\nFormat: A blank line is inserted after the declaration.\n [opt-in]"
    },
    "blankLines" : {
      "additionalProperties" : false,
      "description" : "blankLines rule group.",
      "properties" : {
        "afterGuardStatements" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove blank lines between consecutive guard statements and insert a blank line after\nthe last guard.\n\nGuard blocks at the top of a function form a precondition section. Keeping them tight\n(no blank lines between them) and separated from the body (one blank line after) improves\nreadability. Comments between guards break the \"consecutive\" chain — each guard followed\nby a comment gets its own trailing blank line.\n\nLint: If there are blank lines between consecutive guards, or no blank line after the\n      last guard before other code, a lint warning is raised.\n\nFormat: Blank lines between consecutive guards are removed. A blank line is inserted\n        after the last guard when followed by non-guard code.\n [opt-in]"
        },
        "afterImports" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Insert a blank line after the last import statement.\n\nWhen import statements are followed directly by other declarations without a separating blank\nline, readability suffers. This rule ensures exactly one blank line separates the import block\nfrom the rest of the code.\n\nLint: If the first non-import declaration is not preceded by a blank line, a lint warning is raised.\n\nFormat: A blank line is inserted after the last import statement.\n"
        },
        "afterSwitchCase" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Insert a blank line after multiline switch case bodies.\n\nWhen a switch case body spans multiple statements, a blank line after it improves readability\nby visually separating it from the next case. Single-statement cases do not require blank lines.\nThe last case in a switch is never followed by a blank line (the closing brace provides\nvisual separation).\n\nLint: If a multiline case body is not followed by a blank line, a lint warning is raised.\n      If the last case is followed by a blank line before `}`, a lint warning is raised.\n\nFormat: Blank lines are inserted after multiline cases and removed after the last case.\n [opt-in]"
        },
        "beforeAndAfterMark" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Insert blank lines before and after `// MARK:` comments.\n\nMARK comments serve as section dividers. Surrounding them with blank lines makes the\nvisual separation clear. A blank line before MARK is skipped when the MARK immediately\nfollows an opening brace (start of scope). A blank line after MARK is skipped when\nthe MARK immediately precedes a closing brace (end of scope) or end of file.\n\nLint: If a MARK comment is missing a blank line before or after it, a lint warning is raised.\n\nFormat: Blank lines are inserted around MARK comments.\n [opt-in]"
        },
        "beforeControlFlowBlocks" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Insert a blank line before control flow statements with multi-line bodies.\n\nWhen a `for`, `while`, `repeat`, `if`, `switch`, `do`, or `defer` statement has a\nmulti-line body and is preceded by another statement, a blank line before it improves\nreadability. Single-line (inline) control flow is excluded. Guard statements are excluded\nbecause `BlankLinesAfterGuardStatements` already handles spacing around guards.\n\nLint: If a multi-line control flow statement is not preceded by a blank line, a lint\n      warning is raised.\n\nFormat: A blank line is inserted before the control flow statement.\n [opt-in]"
        },
        "betweenScopes" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Insert a blank line after declarations with multi-line bodies.\n\nWhen a type declaration (class, struct, enum, extension, protocol, actor) or function\ndeclaration has a multi-line body, a blank line after it improves readability by\nvisually separating it from the next declaration. Single-line (inline) bodies are\nexcluded. This rule operates at the top level and inside type member blocks — not\ninside function bodies (if/for/while don't need separation).\n\nLint: If a multi-line scoped declaration is not followed by a blank line, a lint\n      warning is raised.\n\nFormat: A blank line is inserted after the declaration.\n [opt-in]"
        },
        "closingBraceAsBlankLine" : {
          "description" : "Treat a solitary closing brace as a blank line.",
          "type" : "boolean"
        },
        "commentAsBlankLine" : {
          "description" : "Treat a comment line as a blank line.",
          "type" : "boolean"
        },
        "consistentSwitchCaseSpacing" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Ensure consistent blank-line spacing among all cases in a switch statement.\n\nWhen some cases in a switch are separated by blank lines and others aren't, the\ninconsistency looks sloppy. This rule normalizes to whichever style is used by\nthe majority of cases: if more cases have blank lines, missing ones are added;\nif fewer do, extra ones are removed. The last case is excluded (it's always\nfollowed by `}`).\n\nLint: If any case's spacing is inconsistent with the majority, a lint warning is raised.\n\nFormat: Blank lines are added or removed to make spacing consistent.\n [opt-in]"
        },
        "maximumBlankLines" : {
          "description" : "Maximum consecutive blank lines.",
          "type" : "integer"
        }
      },
      "type" : "object"
    },
    "camelCaseIdentifiers" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "All values should be written in lower camel-case (`lowerCamelCase`).\nUnderscores (except at the beginning of an identifier) are disallowed.\n\nThis rule does not apply to test code, defined as code which:\n  * Contains the line `import XCTest`\n  * The function is marked with `@Test` attribute\n\nLint: If an identifier contains underscores or begins with a capital letter, a lint error is\n      raised.\n",
      "unevaluatedProperties" : false
    },
    "capitalizeTypeNames" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "`struct`, `class`, `enum` and `protocol` declarations should have a capitalized name.\n\nLint:  Types with un-capitalized names will yield a lint error.\n",
      "unevaluatedProperties" : false
    },
    "caseLet" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Enforce consistent placement of `let`/`var` in case patterns.\n\nControlled by `Configuration.patternLet.placement`:\n\n- `eachBinding` (default): Each variable has its own `let`/`var`:\n  `case .foo(let x, let y)`.\n- `outerPattern`: The `let`/`var` is hoisted to the pattern level:\n  `case let .foo(x, y)`.\n\nLint: Using the non-preferred placement yields a lint error.\n\nFormat: The `let`/`var` is repositioned to match the configured placement.\n",
      "properties" : {
        "placement" : {
          "default" : "eachBinding",
          "description" : "placement Options: eachBinding, outerPattern.",
          "enum" : [
            "eachBinding",
            "outerPattern"
          ],
          "type" : "string"
        }
      }
    },
    "closures" : {
      "additionalProperties" : false,
      "description" : "closures rule group.",
      "properties" : {
        "ambiguousTrailingClosureOverload" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Overloads with only a closure argument should not be disambiguated by parameter labels.\n\nLint: If two overloaded functions with one closure parameter appear in the same scope, a lint\n      error is raised.\n",
          "unevaluatedProperties" : false
        },
        "mutableCapture" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Capturing a `var` by name in a closure captures its current value, not the\nvariable. Subsequent mutations through the original binding are invisible\nto the closure, which is almost always surprising.\n\nThis rule is purely syntactic: it pre-scans the source file for `var`\ndeclarations (excluding `lazy var` and IUOs) and flags closure captures\nwhose name matches any such declaration. Captures with an explicit\ninitializer (`[x = self.x]`) and `weak`/`unowned` captures are not flagged.\n\nLint: When a closure captures a name that matches a `var` declaration in\nthe same file, a warning is raised.\n",
          "unevaluatedProperties" : false
        },
        "namedClosureParams" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Use named arguments in multi-line closures.\n\nInside a single-line closure, `$0`/`$1` is concise and idiomatic. Inside a multi-line closure\nthe anonymous form forces readers to track which argument is which by counting; an explicit\n`arg in` parameter list reads more clearly.\n\nLint: A warning is raised for each `$0`/`$1`/... reference inside a multi-line closure.\n\nFormat: Not auto-fixed; the rule cannot pick a meaningful parameter name.\n [opt-in]"
        },
        "noParensInClosureParams" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove parentheses around closure parameter lists when no parameter has a type annotation.\n\n`{ (x, y) in ... }` is equivalent to `{ x, y in ... }` when the parameters are untyped —\nthe parens add visual noise. Typed parameter lists (`{ (x: Int) in }`) keep the parens\nbecause shorthand parameters can't carry types.\n\nLint: A finding is raised at the parameter clause.\n\nFormat: The parenthesized parameter list is converted to shorthand (`x, y`).\n"
        },
        "noTrailingClosureParens" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Function calls with no arguments and a trailing closure should not have empty parentheses.\n\nLint: If a function call with a trailing closure has an empty argument list with parentheses,\n      a lint error is raised.\n\nFormat: Empty parentheses in function calls with trailing closures will be removed.\n"
        },
        "onlyOneTrailingClosureArgument" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Function calls should never mix normal closure arguments and trailing closures.\n\nLint: If a function call with a trailing closure also contains a non-trailing closure argument,\n      a lint error is raised.\n",
          "unevaluatedProperties" : false
        },
        "preferTrailingClosures" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Use trailing closure syntax where applicable.\n\nWhen the last argument(s) to a function call are closure expressions, convert\nthem to trailing closure syntax. For a single trailing closure, the closure must\nbe unlabeled unless the function is in the \"always trailing\" list (e.g. `async`,\n`sync`, `autoreleasepool`). For multiple trailing closures, the first must be\nunlabeled and the rest must be labeled.\n\nLint: When closure arguments could use trailing closure syntax.\n\nFormat: The closure arguments are moved to trailing closure position.\n"
        },
        "unhandledThrowingTask" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "`Task { try ... }` silently swallows thrown errors when the error type is\ninferred (or written as `_`).\n\nWithout an explicit `Failure` generic argument, a `Task` that throws an\nunhandled error doesn't surface the error anywhere — there is no `throws`\nsignature on the closure call site, and the value/result of the task is\nusually discarded.\n\nSee: https://forums.swift.org/t/task-initializer-with-throwing-closure-swallows-error/56066\n\nLint: When a `Task { ... }` (with implicit or wildcard error type) contains\nan unhandled `throw` or `try`, an error is raised. Tasks whose value or\nresult is consumed (`let t = Task { ... }`, `Task { ... }.value`,\n`return Task { ... }`) are exempt.\n [opt-in]",
          "unevaluatedProperties" : false
        }
      },
      "type" : "object"
    },
    "collapseSimpleEnums" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Collapses simple enums with no associated values, no raw values, and no\nmembers other than cases onto a single line.\n\n```swift\n// Before\nprivate enum Kind {\n    case chained\n    case forced\n}\n\n// After\nprivate enum Kind { case chained, forced }\n```\n\nThe rule only applies when the collapsed form fits within the configured\nline length. Enums with associated values, explicit raw value assignments,\nraw-value types (e.g. `: Int`, `: String`), computed properties, methods,\nor any non-case member are left untouched.\n [opt-in]"
    },
    "collapseSimpleIfElse" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Collapses multi-line `if`/`else` (and `else if` chains) onto a single line\nwhen every branch contains exactly one statement and the collapsed form fits\nwithin the configured line length.\n\nComplements `PreferTernary` for cases ternary can't reach: `if let`/`if case`\nconditional bindings, `if #available`, and multi-clause conditions.\n\n```swift\n// Before\nif let defaultValue = last?.defaultValue {\n    defaultValue\n} else {\n    last?.type\n}\n\n// After\nif let defaultValue = last?.defaultValue { defaultValue } else { last?.type }\n```\n\nLint: A multi-line if/else where each branch has a single statement and the\n      collapsed form fits within line length raises a warning.\n\nFormat: The chain is collapsed onto a single line.\n [opt-in]"
    },
    "comments" : {
      "additionalProperties" : false,
      "description" : "comments rule group.",
      "properties" : {
        "convertRegularCommentToDocC" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Use doc comments for API declarations, otherwise use regular comments.\n\nComments immediately before type declarations, properties, methods, and other\nAPI-level constructs use `///` doc comment syntax. Comments inside function\nbodies use `//` regular comment syntax, except for nested function declarations.\n\nLint: When a regular comment should be a doc comment, or vice versa.\n\nFormat: The comment style is corrected.\n [opt-in]"
        },
        "disallowBlockComments" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Block comments should be avoided in favor of line comments.\n\nLint: If a block comment appears, a lint error is raised.\n",
          "unevaluatedProperties" : false
        },
        "documentParameters" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Documentation comments must be complete and valid.\n\n\"Command + Option + /\" in Xcode produces a minimal valid documentation comment.\n\nLint: Documentation comments that are incomplete (e.g. missing parameter documentation) or\n      invalid (uses `Parameters` when there is only one parameter) will yield a lint error.\n [opt-in]",
          "unevaluatedProperties" : false
        },
        "documentPublicDeclarations" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "All public or open declarations must have a top-level documentation comment.\n\nLint: If a public declaration is missing a documentation comment, a lint error is raised.\n",
          "unevaluatedProperties" : false
        },
        "formatTypePrefix" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Use correct formatting for `TODO:`, `MARK:`, and `FIXME:` comments.\n\nThese special comment tags must be uppercase, followed by a colon and a space. `MARK:` comments\nwith a dash separator must use `// MARK: - text` format. Standalone `/// MARK:` doc comments are\nconverted to `// MARK:` since MARK is not a documentation concept.\n\nLint: If a special comment tag is not correctly formatted, a lint warning is raised.\n\nFormat: The comment is reformatted to use the correct style.\n"
        },
        "precedeModifiers" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Place doc comments before any declaration modifiers or attributes.\n\nDoc comments (`///` or `/** */`) should appear before all attributes and access modifiers,\nnot between them.\n\nLint: If a doc comment appears after an attribute or modifier, a lint warning is raised.\n\nFormat: The doc comment is moved before all attributes and modifiers.\n"
        },
        "requireSummary" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "All documentation comments must begin with a one-line summary of the declaration.\n\nLint: If a comment does not begin with a single-line summary, a lint error is raised.\n [opt-in]",
          "unevaluatedProperties" : false
        },
        "tripleSlashDocC" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Documentation comments must use the `///` form.\n\nThis is similar to `NoBlockComments` but is meant to prevent documentation block comments.\n\nLint: If a doc block comment appears, a lint error is raised.\n\nFormat: If a doc block comment appears on its own on a line, or if a doc block comment spans\n        multiple lines without appearing on the same line as code, it will be replaced with\n        multiple doc line comments.\n"
        }
      },
      "type" : "object"
    },
    "compoundCaseItems" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Comma-delimited switch case items are wrapped onto separate lines.\n\nSwitch cases with multiple patterns separated by commas are expanded so each\npattern appears on its own line, aligned after `case `.\n\nLint: A switch case with multiple comma-separated items on a single line\n      raises a warning.\n\nFormat: Each item is placed on its own line with alignment indentation.\n [opt-in]"
    },
    "conditionalAssignment" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Multiline conditional assignment expressions are wrapped after the\nassignment operator.\n\nWhen assigning an `if` or `switch` expression that spans multiple lines,\nthe `=` should be on the same line as the property, and a line break\nshould follow `=` before the `if`/`switch` keyword.\n\nLint: A multiline `if`/`switch` expression on the same line as `=` raises\n      a warning.\n\nFormat: A line break is inserted after `=`.\n [opt-in]"
    },
    "conditions" : {
      "additionalProperties" : false,
      "description" : "conditions rule group.",
      "properties" : {
        "duplicateConditions" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "The same condition appearing twice in an if/else-if chain or switch is dead code.\n\nWalks each top-level if/else-if chain and groups branches by their normalized\ncondition set (order-insensitive). Any condition appearing in more than one\nbranch is flagged.\n\nWalks each switch's case list and groups case items by their normalized\n`pattern + where`. Any case item appearing more than once is flagged.\n\nLint: When the same condition or case appears multiple times in the same\nbranch instruction, an error is raised.\n",
          "unevaluatedProperties" : false
        },
        "explicitNilCheck" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "When checking an optional value for `nil`-ness, prefer writing an explicit `nil` check rather\nthan binding and immediately discarding the value.\n\nFor example, `if let _ = someValue { ... }` is forbidden. Use `if someValue != nil { ... }`\ninstead.\n\nNote: If the conditional binding carries an explicit type annotation (e.g. `if let _: S? = expr`),\nwe skip the transformation. Such annotations can be necessary to drive generic type inference\nwhen a function mentions a type only in its return position.\n\nLint: `let _ = expr` inside a condition list will yield a lint error.\n\nFormat: `let _ = expr` inside a condition list will be replaced by `expr != nil`.\n"
        },
        "identicalOperands" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Comparing two identical operands is almost always a copy-paste bug.\n\nCatches expressions like `x == x`, `foo.bar < foo.bar`, and `$0 != $0`.\nCompares operands by their non-trivia token text so internal whitespace\nand formatting differences are ignored.\n\nLint: When both operands of a comparison operator are textually identical\n(ignoring whitespace), a warning is raised.\n [opt-in]",
          "unevaluatedProperties" : false
        },
        "noParensAroundConditions" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Enforces rules around parentheses in conditions, matched expressions, return statements, and\ninitializer assignments.\n\nParentheses are not used around any condition of an `if`, `guard`, or `while` statement, around\nthe matched expression in a `switch` statement, around `return` values, or around initializer\nvalues in variable/constant declarations.\n\nLint: If a top-most expression in a `switch`, `if`, `guard`, `while`, or `return` statement, or\n      in a variable initializer, is surrounded by parentheses, and it does not include a function\n      call with a trailing closure, a lint error is raised.\n\nFormat: Parentheses around such expressions are removed, if they do not cause a parse ambiguity.\n        Specifically, parentheses are allowed if and only if the expression contains a function\n        call with a trailing closure.\n"
        },
        "noYodaConditions" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer the constant value on the right-hand side of comparison expressions.\n\n\"Yoda conditions\" place the constant on the left (`0 == x`), which reads unnaturally.\nThe conventional Swift style places the variable first (`x == 0`).\n\nFor ordered comparisons (`<`, `<=`, `>`, `>=`), the operator is flipped when swapping\nsides so the semantics are preserved.\n\nLint: A comparison with a constant on the left raises a warning.\n\nFormat: The operands are swapped and the operator is flipped if necessary.\n"
        },
        "preferCommaConditions" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer comma over `&&` in `if`, `guard`, and `while` conditions.\n\nSwift condition lists use commas to separate independent boolean conditions,\nwhich short-circuit identically to `&&` but read more naturally and enable\nindividual conditions to use optional binding or pattern matching.\n\nThis rule only fires when `&&` is the top-level operator in a condition element\n(no `||` mixed in at the same precedence level, since that would change semantics).\n\nLint: Using `&&` in a condition list raises a warning.\n\nFormat: `&&` is replaced with commas, splitting the condition into separate\ncondition elements.\n"
        },
        "preferConditionalExpression" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Use if/switch expressions for conditional property assignment.\n\nWhen a property with a type annotation and no initializer is immediately\nfollowed by an exhaustive `if` or `switch` that assigns the property in\nevery branch, the two statements are merged into a single assignment\nexpression. Nested conditionals are handled recursively.\n\nLint: A property followed by an exhaustive conditional assignment raises\n      a warning.\n\nFormat: The separate statements are merged into a conditional expression\n        assignment.\n [opt-in]"
        },
        "preferEarlyExits" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Early exits should be used whenever possible.\n\nThis means that `if ... else { return/throw/break/continue }` constructs should be replaced by\n`guard ... else { return/throw/break/continue }` constructs in order to keep indentation levels\nlow. Specifically, code of the following form:\n\n```swift\nif condition {\n  trueBlock\n} else {\n  falseBlock\n  return/throw/break/continue\n}\n```\n\nwill be transformed into:\n\n```swift\nguard condition else {\n  falseBlock\n  return/throw/break/continue\n}\ntrueBlock\n```\n\nLint: `if ... else { return/throw/break/continue }` constructs will yield a lint error.\n\nFormat: `if ... else { return/throw/break/continue }` constructs will be replaced with\n        equivalent `guard ... else { return/throw/break/continue }` constructs.\n [opt-in]"
        },
        "preferIfElseChain" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Consecutive single-return `if` statements followed by a final `return` should\nbe expressed as a chained `if/else` expression.\n\nWhen a sequence of `if` statements each contain only a `return` and are\nfollowed by a trailing `return`, the chain is converted into a single\n`if/else if/.../else` expression (two or more `if` branches required).\n\n```swift\n// Before\nif case .spaces = $0 { return true }\nif case .tabs = $0 { return true }\nreturn false\n\n// After\nif case .spaces = $0 {\n    true\n} else if case .tabs = $0 {\n    true\n} else {\n    false\n}\n```\n\nLint: A chain of early-return `if` statements raises a warning.\n\nFormat: The chain is replaced with an `if/else` expression.\n"
        },
        "preferTernary" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Use ternary conditional expressions for simple if-else returns or assignments.\n\nWhen an `if`-`else` has exactly two branches, each containing a single\n`return` statement or a single assignment to the same variable, and the\ncondition is a simple expression (no else-if chains), the construct is\ncollapsed into a ternary conditional expression.\n\n```swift\n// Before\nif condition {\n    return trueValue\n} else {\n    return falseValue\n}\n// After\nreturn condition ? trueValue : falseValue\n\n// Before\nif condition {\n    result = trueValue\n} else {\n    result = falseValue\n}\n// After\nresult = condition ? trueValue : falseValue\n```\n\nLint: A simple if-else with single returns or same-variable assignments\n      in both branches raises a warning.\n\nFormat: The if-else is replaced with a ternary expression.\n [opt-in]"
        },
        "preferUnavailable" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer `#unavailable(...)` over `#available(...) {} else { ... }`.\n\nInverting an availability check via an empty `if`-body and a non-empty `else`-body is harder to\nread than the direct `#unavailable` form (Swift 5.6+). This rule rewrites the simple shape; it\ndoes not touch chains where the `else` body has its own availability check (rewriting those is\nnot a simple inversion).\n\nLint: A warning is raised on `if #available(iOS X, *) {} else { body }`.\n\nFormat: The `if` is rewritten to `if #unavailable(iOS X, *) { body }`.\n"
        }
      },
      "type" : "object"
    },
    "consistentSwitchCaseSpacing" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Ensure consistent blank-line spacing among all cases in a switch statement.\n\nWhen some cases in a switch are separated by blank lines and others aren't, the\ninconsistency looks sloppy. This rule normalizes to whichever style is used by\nthe majority of cases: if more cases have blank lines, missing ones are added;\nif fewer do, extra ones are removed. The last case is excluded (it's always\nfollowed by `}`).\n\nLint: If any case's spacing is inconsistent with the majority, a lint warning is raised.\n\nFormat: Blank lines are added or removed to make spacing consistent.\n [opt-in]"
    },
    "convertRegularCommentToDocC" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Use doc comments for API declarations, otherwise use regular comments.\n\nComments immediately before type declarations, properties, methods, and other\nAPI-level constructs use `///` doc comment syntax. Comments inside function\nbodies use `//` regular comment syntax, except for nested function declarations.\n\nLint: When a regular comment should be a doc comment, or vice versa.\n\nFormat: The comment style is corrected.\n [opt-in]"
    },
    "declarations" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Sort declarations between `// swiftiomatic:sort:begin` and `// swiftiomatic:sort:end` markers.\n\nDeclarations within the marked region are sorted alphabetically by name. Comments and trivia\nassociated with each declaration move with it. The markers themselves are preserved in place.\n\nLint: If declarations in a marked region are not sorted, a lint warning is raised.\n\nFormat: The declarations are reordered alphabetically by name.\n"
    },
    "deinitObserverRemoval" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "`NotificationCenter.default.removeObserver(self)` should only appear in `deinit`.\n\nRemoving the observer earlier (e.g. in `viewWillDisappear`) prevents notifications from being\ndelivered when the object is otherwise still alive. The correct place to detach is `deinit`,\nwhich runs exactly once at the end of the object's lifetime.\n\nLint: A call to `NotificationCenter.default.removeObserver(self)` outside `deinit` yields a\nwarning. Removing other observers (e.g. `removeObserver(otherObject)`) is allowed anywhere.\n",
      "unevaluatedProperties" : false
    },
    "delegateProtocolRequiresAnyObject" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Protocols whose name ends in `Delegate` should be class-constrained.\n\nDelegate properties are typically declared `weak` to avoid retain cycles. The `weak` modifier\nis only valid on class-bound references, so a delegate protocol must inherit from `AnyObject`\n(or `NSObjectProtocol`, `Actor`, another `*Delegate` protocol) — otherwise it cannot be held\nweakly.\n\nLint: A protocol whose name ends in `Delegate` and is not class-constrained yields a warning.\n",
      "unevaluatedProperties" : false
    },
    "disallowBlockComments" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Block comments should be avoided in favor of line comments.\n\nLint: If a block comment appears, a lint error is raised.\n",
      "unevaluatedProperties" : false
    },
    "documentParameters" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Documentation comments must be complete and valid.\n\n\"Command + Option + /\" in Xcode produces a minimal valid documentation comment.\n\nLint: Documentation comments that are incomplete (e.g. missing parameter documentation) or\n      invalid (uses `Parameters` when there is only one parameter) will yield a lint error.\n [opt-in]",
      "unevaluatedProperties" : false
    },
    "documentPublicDeclarations" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "All public or open declarations must have a top-level documentation comment.\n\nLint: If a public declaration is missing a documentation comment, a lint error is raised.\n",
      "unevaluatedProperties" : false
    },
    "duplicateConditions" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "The same condition appearing twice in an if/else-if chain or switch is dead code.\n\nWalks each top-level if/else-if chain and groups branches by their normalized\ncondition set (order-insensitive). Any condition appearing in more than one\nbranch is flagged.\n\nWalks each switch's case list and groups case items by their normalized\n`pattern + where`. Any case item appearing more than once is flagged.\n\nLint: When the same condition or case appears multiple times in the same\nbranch instruction, an error is raised.\n",
      "unevaluatedProperties" : false
    },
    "duplicateDictionaryKeys" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Dictionary literals with duplicate keys silently overwrite earlier values.\n\nThe Swift compiler accepts duplicate static keys but the resulting dictionary\nonly retains the *last* value for each key — almost always a copy-paste bug.\n\nOnly static keys are checked: literals, identifiers, and member access\nexpressions. Dynamic keys like `UUID()` or `#line` can legitimately produce\ndistinct values at runtime and are skipped.\n\nLint: When a static key appears more than once in the same dictionary\nliteral, every occurrence after the first is flagged.\n",
      "unevaluatedProperties" : false
    },
    "emptyExtensions" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove empty extensions that do not add protocol conformance.\n\nAn extension with no members and no inheritance clause serves no purpose and should be removed.\nExtensions that add protocol conformance (e.g. `extension Foo: Equatable {}`) are kept even\nwhen empty, because the conformance itself is meaningful.\n\nExtensions containing only comments are preserved.\n\nLint: If an empty, non-conforming extension is found, a lint warning is raised.\n\nFormat: The entire extension declaration is removed.\n"
    },
    "ensureLineBreakAtEOF" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Ensure the file ends with exactly one newline.\n\nMany Unix tools expect files to end with a newline. Missing trailing newlines cause\n`diff` noise and `cat` concatenation issues. Extra trailing newlines waste space.\n\nLint: If the file does not end with exactly one newline, a lint warning is raised.\n\nFormat: A trailing newline is added if missing, or extra newlines are removed.\n [opt-in]"
    },
    "explicitNilCheck" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "When checking an optional value for `nil`-ness, prefer writing an explicit `nil` check rather\nthan binding and immediately discarding the value.\n\nFor example, `if let _ = someValue { ... }` is forbidden. Use `if someValue != nil { ... }`\ninstead.\n\nNote: If the conditional binding carries an explicit type annotation (e.g. `if let _: S? = expr`),\nwe skip the transformation. Such annotations can be necessary to drive generic type inference\nwhen a function mentions a type only in its return position.\n\nLint: `let _ = expr` inside a condition list will yield a lint error.\n\nFormat: `let _ = expr` inside a condition list will be replaced by `expr != nil`.\n"
    },
    "extensionAccessLevel" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Controls placement of access level modifiers on extensions vs. their members.\n\nThe behavior of this rule is controlled by `Configuration.extensionAccessControl.placement`:\n\n- `onMembers` (default): Access levels on extensions are moved to individual members.\n- `onExtension`: When all members share the same access level, it is hoisted to the extension.\n\nLint: A lint error is raised when access control placement doesn't match the configuration.\n\nFormat: Access control modifiers are moved to match the configured placement.\n",
      "properties" : {
        "placement" : {
          "default" : "onMembers",
          "description" : "placement Options: onMembers, onExtension.",
          "enum" : [
            "onMembers",
            "onExtension"
          ],
          "type" : "string"
        }
      }
    },
    "fileHeader" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Enforce a consistent file header comment, or remove file headers entirely.\n\nWhen configured with header text, any existing file header comment is replaced with the\nconfigured text. When configured with an empty string, any existing file header is removed.\nFile header comments are line comments (`//`) or block comments (`/* */`) at the start of\nthe file, before any blank line, doc comment, or code. Doc comments (`///`, `/** */`) are\nnot considered file header comments.\n\nThis rule is opt-in and requires configuration via `fileHeader.text` in the configuration file.\n\nLint: A warning is raised when the file header does not match the configured text.\n\nFormat: The file header is replaced with (or cleared to) the configured text.\n [opt-in]",
      "properties" : {
        "text" : {
          "description" : "text",
          "type" : "string"
        }
      }
    },
    "fileScopedDeclarationPrivacy" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Declarations at file scope with effective private access should be consistently declared as\neither `fileprivate` or `private`, determined by configuration.\n\nLint: If a file-scoped declaration has formal access opposite to the desired access level in the\n      formatter's configuration, a lint error is raised.\n\nFormat: File-scoped declarations that have formal access opposite to the desired access level in\n        the formatter's configuration will have their access level changed.\n",
      "properties" : {
        "accessLevel" : {
          "default" : "private",
          "description" : "accessLevel Options: private, fileprivate.",
          "enum" : [
            "private",
            "fileprivate"
          ],
          "type" : "string"
        }
      }
    },
    "forcing" : {
      "additionalProperties" : false,
      "description" : "forcing rule group.",
      "properties" : {
        "noForceCast" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Force casts (`as!`) are forbidden.\n\nA force cast crashes at runtime if the conversion fails. Prefer the conditional cast (`as?`)\ncombined with optional handling (`if let`, `guard let`, nil-coalescing, etc.).\n\nThis rule complements `NoForceTry` and `NoForceUnwrap`.\n\nLint: A warning is raised for each `as!`.\n\nFormat: Not auto-fixed; the safe replacement depends on caller intent.\n [opt-in]"
        },
        "noForceTry" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Force-try (`try!`) is forbidden.\n\nIn test functions, `try!` is auto-fixed to `try` and `throws` is added to the function\nsignature if needed.\n\nIn non-test code, `try!` is diagnosed but not rewritten.\n\nTest functions are:\n- Functions annotated with `@Test` (Swift Testing)\n- Functions named `test*()` with no parameters inside `XCTestCase` subclasses\n\n`try!` inside closures or nested functions is left alone because the enclosing test function's\n`throws` does not propagate into those scopes.\n\nLint: A warning is raised for each `try!`.\n\nFormat: In test functions, `try!` is replaced with `try` and `throws` is added.\n [opt-in]"
        },
        "noForceUnwrap" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Force-unwraps are strongly discouraged and must be documented.\n\nIn test functions, force unwraps are auto-fixed:\n- `foo!` becomes `try XCTUnwrap(foo)` (XCTest) or `try #require(foo)` (Swift Testing)\n- `foo as! Bar` becomes `try XCTUnwrap(foo as? Bar)` or `try #require(foo as? Bar)`\n- `throws` is added to the function signature if needed\n\nIn non-test code, force unwraps are diagnosed but not rewritten.\n\nTest functions are:\n- Functions annotated with `@Test` (Swift Testing)\n- Functions named `test*()` with no parameters inside `XCTestCase` subclasses\n\nForce unwraps in closures, nested functions, and string interpolation are left alone because\n`try` cannot propagate out of those scopes.\n\nLint: A warning is raised for each force unwrap.\n\nFormat: In test functions, force unwraps are replaced with XCTUnwrap/#require.\n [opt-in]"
        }
      },
      "type" : "object"
    },
    "formatTypePrefix" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Use correct formatting for `TODO:`, `MARK:`, and `FIXME:` comments.\n\nThese special comment tags must be uppercase, followed by a colon and a space. `MARK:` comments\nwith a dash separator must use `// MARK: - text` format. Standalone `/// MARK:` doc comments are\nconverted to `// MARK:` since MARK is not a documentation concept.\n\nLint: If a special comment tag is not correctly formatted, a lint warning is raised.\n\nFormat: The comment is reformatted to use the correct style.\n"
    },
    "generics" : {
      "additionalProperties" : false,
      "description" : "generics rule group.",
      "properties" : {
        "opaqueGenericParameters" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Use opaque generic parameters (`some Protocol`) instead of named generic parameters\nwith constraints (`<T: Protocol>`) where equivalent.\n\nThis rule applies to `func`, `init`, and `subscript` declarations. A generic type parameter\nis eligible for conversion when it appears exactly once in the parameter list and is not\nreferenced in the return type, function body, attributes, typed throws, or other generic\nconstraints.\n\nLint: A lint warning is raised when a generic parameter can be replaced with an opaque parameter.\n\nFormat: The generic parameter is replaced with `some Protocol` in the parameter type.\n [opt-in]"
        },
        "preferAngleBracketExtensions" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Use angle brackets (`extension Array<Foo>`) for generic type extensions instead of\ntype constraints (`extension Array where Element == Foo`).\n\nSwift 5.7+ supports angle bracket syntax in extension declarations. When a `where`\nclause constrains all generic parameters of a known type to concrete types,\nthe angle bracket form is more concise.\n\nKnown types: `Array`, `Set`, `Optional`, `Dictionary`, `Collection`, `Sequence`.\n\nLint: An extension with a `where` clause that can be replaced by angle brackets raises a warning.\n\nFormat: The `where` clause constraints are moved into angle bracket syntax on the\nextended type.\n"
        },
        "simplifyGenericConstraints" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Use inline generic constraints (`<T: Foo>`) instead of where clauses\n(`<T> where T: Foo`) for simple protocol conformance constraints.\n\nWhen a generic parameter has a simple conformance constraint in the `where` clause,\nit can be moved inline into the generic parameter list for conciseness.\n\nSame-type constraints (`T == Foo`), associated type constraints (`T.Element: Foo`),\nand parameters that already have an inline constraint are not modified.\n\nLint: A `where` clause with a simple conformance constraint that could be inlined raises a warning.\n\nFormat: The conformance constraint is moved from the `where` clause to the generic parameter.\n"
        }
      },
      "type" : "object"
    },
    "groupNumericLiterals" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Numeric literals should be grouped with `_`s to delimit common separators.\n\nSpecifically, decimal numeric literals should be grouped every 3 numbers, hexadecimal every 4,\nand binary every 8.\n\nLint: If a numeric literal is too long and should be grouped, a lint error is raised.\n\nFormat: All numeric literals that should be grouped will have `_`s inserted where appropriate.\n\nTODO: Minimum numeric literal length bounds and numeric groupings have been selected arbitrarily;\nthese could be reevaluated.\nTODO: Handle floating point literals.\n"
    },
    "hoist" : {
      "additionalProperties" : false,
      "description" : "hoist rule group.",
      "properties" : {
        "caseLet" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Enforce consistent placement of `let`/`var` in case patterns.\n\nControlled by `Configuration.patternLet.placement`:\n\n- `eachBinding` (default): Each variable has its own `let`/`var`:\n  `case .foo(let x, let y)`.\n- `outerPattern`: The `let`/`var` is hoisted to the pattern level:\n  `case let .foo(x, y)`.\n\nLint: Using the non-preferred placement yields a lint error.\n\nFormat: The `let`/`var` is repositioned to match the configured placement.\n",
          "properties" : {
            "placement" : {
              "default" : "eachBinding",
              "description" : "placement Options: eachBinding, outerPattern.",
              "enum" : [
                "eachBinding",
                "outerPattern"
              ],
              "type" : "string"
            }
          }
        },
        "indirectEnum" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "If all cases of an enum are `indirect`, the entire enum should be marked `indirect`.\n\nLint: If every case of an enum is `indirect`, but the enum itself is not, a lint error is\n      raised.\n\nFormat: Enums where all cases are `indirect` will be rewritten such that the enum is marked\n        `indirect`, and each case is not.\n"
        },
        "nestedAwait" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Move inline `await` keyword(s) to the start of the expression.\n\nWhen `await` appears inside function call arguments, it can be hoisted to wrap the\nentire call expression. This is clearer and avoids redundant `await` keywords when\nmultiple arguments are async.\n\nFor example, `foo(await bar(), await baz())` should be `await foo(bar(), baz())`.\n\nThis rule does not flag `await` inside closures (which have their own async context)\nor when the call is already wrapped in `await`.\n\nLint: Using `await` inside a function call argument raises a warning.\n\nFormat: `await` is removed from arguments and added to wrap the call expression.\n"
        },
        "nestedTry" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Move inline `try` keyword(s) to the start of the expression.\n\nWhen `try` appears inside function call arguments, it can be hoisted to wrap the\nentire call expression. This is clearer and avoids redundant `try` keywords when\nmultiple arguments throw.\n\nFor example, `foo(try bar(), try baz())` should be `try foo(bar(), baz())`.\n\nThis rule does not flag `try` inside closures (which have their own throwing context)\nor when the call is already wrapped in `try`. Only plain `try` is hoisted (not\n`try?` or `try!`).\n\nLint: Using `try` inside a function call argument raises a warning.\n\nFormat: `try` is removed from arguments and added to wrap the call expression.\n"
        }
      },
      "type" : "object"
    },
    "identicalOperands" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Comparing two identical operands is almost always a copy-paste bug.\n\nCatches expressions like `x == x`, `foo.bar < foo.bar`, and `$0 != $0`.\nCompares operands by their non-trivia token text so internal whitespace\nand formatting differences are ignored.\n\nLint: When both operands of a comparison operator are textually identical\n(ignoring whitespace), a warning is raised.\n [opt-in]",
      "unevaluatedProperties" : false
    },
    "identifiersMayOnlyUseASCII" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "All identifiers must be ASCII.\n\nLint: If an identifier contains non-ASCII characters, a lint error is raised.\n",
      "unevaluatedProperties" : false
    },
    "idioms" : {
      "additionalProperties" : false,
      "description" : "idioms rule group.",
      "properties" : {
        "avoidNoneName" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Avoid naming enum cases or static members `none`.\n\nA `case none` or `static let none` (or `static var`/`class var`) can be confused with\n`Optional<T>.none`. Especially when the enclosing type itself becomes optional, the compiler\nwill silently prefer `Optional.none`, leading to subtle bugs.\n\nLint: A warning is raised for any `case none` (without associated values), or any `static`/\n`class` property named `none`.\n\nFormat: Not auto-fixed; renaming requires understanding the call sites.\n [opt-in]"
        },
        "noAssignmentInExpressions" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Assignment expressions must be their own statements.\n\nAssignment should not be used in an expression context that expects a `Void` value. For example,\nassigning a variable within a `return` statement exiting a `Void` function is prohibited.\n\nLint: If an assignment expression is found in a position other than a standalone statement, a\n      lint finding is emitted.\n\nFormat: A `return` statement containing an assignment expression is expanded into two separate\n        statements.\n",
          "properties" : {
            "allowedFunctions" : {
              "description" : "allowedFunctions",
              "items" : {
                "type" : "string"
              },
              "type" : "array"
            }
          }
        },
        "noExplicitOwnership" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove explicit `borrowing` and `consuming` ownership modifiers.\n\nOwnership modifiers are an advanced feature that most code does not need. When present\non function declarations (e.g. `consuming func move()`) or parameter types\n(e.g. `func foo(_ bar: consuming Bar)`), they are removed.\n\nLint: If an explicit `borrowing` or `consuming` modifier is found, a lint warning is raised.\n\nFormat: The ownership modifier is removed.\n [opt-in]"
        },
        "noRetroactiveConformances" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "`@retroactive` conformances are forbidden.\n\nLint: Using `@retroactive` results in a lint error.\n",
          "unevaluatedProperties" : false
        },
        "noVoidTernary" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Don't use a ternary expression to call void-returning functions.\n\n`condition ? doA() : doB()` reads as if it produces a value, but when both branches return\n`Void` it's effectively a hidden if/else with strictly worse readability. Use a proper\n`if`/`else` statement instead.\n\nLint: A warning is raised when a ternary appears as a statement and both branches are call\nexpressions.\n\nFormat: Not auto-fixed; the rewrite would change formatting beyond the scope of this rule.\n [opt-in]"
        },
        "preferCompoundAssignment" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer compound assignment operators (`+=`, `-=`, `*=`, `/=`) over the long form.\n\n`x = x + y` is exactly equivalent to `x += y` for the supported operators (`+`, `-`, `*`, `/`).\nThe compound form is shorter and avoids repeating the LHS, which makes refactors safer when the\nreceiver is renamed.\n\nThe rule fires only when the LHS expression text matches the RHS's first operand exactly. It\ndoes not fire on `x = a + x` or `x = a + b` patterns.\n\nLint: A warning is raised for `x = x + y` etc.\n\nFormat: The expression is rewritten to `x += y`.\n"
        },
        "preferCountWhere" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer `count(where:)` over `filter(_:).count`.\n\nThe `count(where:)` method (Swift 6.0+) is more expressive and avoids allocating an\nintermediate array just to count its elements.\n\nLint: Using `.filter { ... }.count` raises a warning suggesting `count(where:)`.\n\nFormat: `.filter { ... }.count` is replaced with `.count(where: { ... })`.\n"
        },
        "preferDotZero" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer `.zero` over explicit zero-valued initializers.\n\n`CGPoint(x: 0, y: 0)`, `CGSize(width: 0, height: 0)`, `CGRect(x: 0, y: 0, width: 0, height: 0)`\nand similar are equivalent to the platform-provided `.zero` constant. The shorthand reads\nbetter and avoids subtle inconsistencies (e.g. `0.0` vs `0` literal kinds).\n\nRecognised types: `CGPoint`, `CGSize`, `CGRect`, `CGVector`, `UIEdgeInsets`, `NSEdgeInsets`,\n`NSPoint`, `NSSize`, `NSRect`.\n\nLint: A warning is raised on a fully-zero initializer.\n\nFormat: The call is replaced with `<Type>.zero`.\n"
        },
        "preferFileID" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Enforce consistent use of `#file` or `#fileID`.\n\nIn Swift 6+, `#file` and `#fileID` have identical behavior (both produce `Module/File.swift`).\nThis rule standardizes usage to `#fileID` by default. `#filePath` is unaffected.\n\nLint: Using the non-preferred file macro yields a lint warning.\n\nFormat: The macro is replaced with the preferred spelling.\n [opt-in]"
        },
        "preferIsDisjoint" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer `Set.isDisjoint(with:)` over `Set.intersection(_:).isEmpty`.\n\n`isDisjoint(with:)` expresses intent more directly and can short-circuit on the first shared\nelement, whereas `intersection(_:)` always builds the full intersection set.\n\nLint: A warning is raised on `someSet.intersection(other).isEmpty`.\n\nFormat: Not auto-fixed; the receiver may not be a `Set`, so the rewrite is unsafe in general.\n [opt-in]"
        },
        "preferIsEmpty" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer `isEmpty` over comparing `count` against zero.\n\nChecking `count == 0` or `count != 0` (or `count > 0`) is less expressive and potentially less\nefficient than using `isEmpty`. Collections conforming to `Collection` guarantee O(1) `isEmpty`\nbut `count` may be O(n) for some types (e.g. lazy sequences conforming to `Collection`).\n\nWhen the receiver is optional (`foo?.count == 0`), the replacement uses explicit boolean\ncomparison (`foo?.isEmpty == true`) to preserve semantics.\n\nThis rule is opt-in because not every type with a `count` property also provides `isEmpty`.\n\nLint: Using `.count == 0`, `.count != 0`, or `.count > 0` raises a warning.\n\nFormat: The comparison is replaced with `.isEmpty` or `!.isEmpty`.\n [opt-in]"
        },
        "preferKeyPath" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Convert trivial `map { $0.foo }` closures to keyPath-based syntax.\n\nWhen a closure's only expression is a property access on `$0`, the closure can be\nreplaced with a keyPath expression: `map(\\.foo)`. This is more concise and expressive.\n\nApplies to `map`, `flatMap`, `compactMap`, `allSatisfy`, `filter`, and `contains(where:)`.\n\nOnly fires for simple property chains (not method calls, subscripts, or complex expressions).\n\nLint: A trivial `{ $0.property }` closure raises a warning.\n\nFormat: The closure is replaced with a keyPath expression.\n [opt-in]"
        },
        "preferSelfType" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer `Self` over `type(of: self)`.\n\nInside a class/struct/enum/actor, `Self` refers to the current type and is fully equivalent to\n`type(of: self)` for any non-polymorphic dispatch. The shorthand is more concise and avoids\nthe runtime call.\n\nThis rule does not fire at the top level of a file (where `self` does not refer to an enclosing\ntype) or for non-`self` arguments (`type(of: param)` is preserved).\n\nLint: A warning is raised for `type(of: self)` (also `Swift.type(of: self)`) inside a type.\n\nFormat: The call is replaced with `Self`.\n"
        },
        "preferStaticOverClassFunc" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer `static` over `class` for type members of `final` classes.\n\nIn a `final` class, `class func` and `class var` are equivalent to `static func` and\n`static var` since the class cannot be subclassed. Using `static` makes the intent clearer.\n\nMembers carrying `override` are skipped: the parent's signature uses `class` so the override\nchain remains open; switching to `static` would close that chain even though this class is\nfinal, and may break the override under generic specialization.\n\nLint: If a `class` modifier is found on a non-override member of a `final` class, a warning is raised.\n\nFormat: The `class` modifier is replaced with `static`.\n [opt-in]"
        },
        "preferToggle" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer `someBool.toggle()` over `someBool = !someBool`.\n\n`Bool.toggle()` (Swift 4.2+) is more concise and clearly communicates the intent. The two forms\nare equivalent semantically; `toggle()` does not introduce any new evaluation hazards.\n\nLint: A warning is raised for `x = !x` patterns where the LHS and the negated RHS reference\nthe exact same expression text.\n\nFormat: The expression is rewritten to `x.toggle()`.\n"
        },
        "replaceForEachWithForLoop" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Replace `forEach` with `for-in` loop unless its argument is a function reference.\n\nLint:  invalid use of `forEach` yield will yield a lint error.\n",
          "unevaluatedProperties" : false
        },
        "requireFatalErrorMessage" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "`fatalError` calls should include a descriptive message.\n\nA bare `fatalError()` (or `fatalError(\"\")`) gives no context when the program crashes. Including\na message makes it far easier to diagnose the problem from the stack trace alone.\n\nLint: A warning is raised for `fatalError()` and `fatalError(\"\")`.\n\nFormat: Not auto-fixed; the message must be supplied by the author.\n [opt-in]"
        },
        "retainNotificationObserver" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "`NotificationCenter.addObserver(forName:object:queue:using:)` returns an\nopaque token that must be retained to later remove the observer.\nDiscarding the return value leaks the observer.\n\nLint: When a call to `addObserver(forName:object:queue:...)` is used as a\nstatement (not stored, returned, or passed to another call), a warning is\nraised.\n [opt-in]",
          "unevaluatedProperties" : false
        }
      },
      "type" : "object"
    },
    "imports" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Imports must be lexicographically ordered and (optionally) logically grouped at the top of each source file.\nThe order of the import groups is 1) regular imports, 2) declaration imports, 3) @\\_implementationOnly\nimports, and 4) @testable imports. These groups are separated by a single blank line. Blank lines in\nbetween the import declarations are removed.\n\nLogical grouping is enabled by default but can be disabled via the `sortImports.shouldGroupImports`\nconfiguration option to limit this rule to lexicographic ordering.\n\nBy default, imports within conditional compilation blocks (`#if`, `#elseif`, `#else`) are not ordered.\nThis behavior can be controlled via the `sortImports.includeConditionalImports` configuration option.\n\nLint: If an import appears anywhere other than the beginning of the file it resides in,\n      not lexicographically ordered, or (optionally) not in the appropriate import group, a lint error is\n      raised.\n\nFormat: Imports will be reordered and (optionally) grouped at the top of the file.\n",
      "properties" : {
        "sortOrder" : {
          "default" : "alphabetical",
          "description" : "sortOrder Options: alphabetical, length.",
          "enum" : [
            "alphabetical",
            "length"
          ],
          "type" : "string"
        }
      }
    },
    "indentation" : {
      "additionalProperties" : false,
      "description" : "indentation rule group.",
      "properties" : {
        "blankLines" : {
          "description" : "Add indentation whitespace to blank lines.",
          "type" : "boolean"
        },
        "conditionalCompilationBlocks" : {
          "description" : "Indent #if/#elseif/#else blocks.",
          "type" : "boolean"
        },
        "switchCases" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Enforce switch case label indentation style.\n\nTwo styles are supported via `SwitchCaseIndentationConfiguration.Style`:\n- `flush`: `case` labels align with the `switch` keyword (default).\n- `indented`: `case` labels are indented one level from `switch`.\n\nLint: Raised when a `case` or `default` label doesn't match the configured style.\n\nFormat: Case labels, bodies, and the closing brace are reindented to match.\n [opt-in]",
          "properties" : {
            "style" : {
              "default" : "flush",
              "description" : "style Options: flush, indented.",
              "enum" : [
                "flush",
                "indented"
              ],
              "type" : "string"
            }
          }
        },
        "tabWidth" : {
          "description" : "Tab width in spaces for indentation conversion.",
          "type" : "integer"
        },
        "unit" : {
          "default" : {
            "spaces" : 2
          },
          "description" : "Indentation unit: exactly one of spaces or tabs.",
          "oneOf" : [
            {
              "additionalProperties" : false,
              "description" : "Indent with spaces.",
              "properties" : {
                "spaces" : {
                  "default" : 2,
                  "description" : "Number of spaces per indent level.",
                  "minimum" : 1,
                  "type" : "integer"
                }
              },
              "required" : [
                "spaces"
              ],
              "type" : "object"
            },
            {
              "additionalProperties" : false,
              "description" : "Indent with tabs.",
              "properties" : {
                "tabs" : {
                  "default" : 1,
                  "description" : "Number of tabs per indent level.",
                  "minimum" : 1,
                  "type" : "integer"
                }
              },
              "required" : [
                "tabs"
              ],
              "type" : "object"
            }
          ]
        }
      },
      "type" : "object"
    },
    "indirectEnum" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "If all cases of an enum are `indirect`, the entire enum should be marked `indirect`.\n\nLint: If every case of an enum is `indirect`, but the enum itself is not, a lint error is\n      raised.\n\nFormat: Enums where all cases are `indirect` will be rewritten such that the enum is marked\n        `indirect`, and each case is not.\n"
    },
    "initCoderUnavailable" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Add `@available(*, unavailable)` to `required init(coder:)` that only calls `fatalError`.\n\nWhen a `UIView` or `UIViewController` subclass provides a `required init(coder:)` that\nimmediately calls `fatalError`, it should be marked `@available(*, unavailable)` so the\ncompiler prevents it from being called.\n\nLint: A `required init(coder:)` stub without `@available(*, unavailable)` yields a warning.\n\nFormat: The `@available(*, unavailable)` attribute is added.\n [opt-in]"
    },
    "invisibleCharacters" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Zero-width and other invisible Unicode characters in string literals are\nalmost always typos or paste artifacts. They're impossible to see in source\nand cause string equality, lookup, and URL parsing to silently fail.\n\nThe default character set is U+200B (zero-width space), U+200C (zero-width\nnon-joiner), and U+FEFF (BOM). Configure additional code points via\n`invisibleCharacters.additionalCodePoints` (an array of hex strings, e.g.\n`[\"00AD\", \"200D\"]`).\n\nLint: When a string literal segment contains any of the configured\ninvisible code points, an error is raised at the offending character.\n",
      "properties" : {
        "additionalCodePoints" : {
          "description" : "additionalCodePoints",
          "items" : {
            "type" : "string"
          },
          "type" : "array"
        }
      },
      "unevaluatedProperties" : false
    },
    "leadingDotOperators" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Move leading delimiters to the end of the previous line.\n\nWhen a line starts with a comma or colon, the delimiter should instead be placed at the end\nof the previous line. This keeps the delimiter associated with the preceding expression rather\nthan the following one.\n\nLint: A finding is emitted when a delimiter starts a line.\n\nFormat: The delimiter is moved to the end of the previous line.\n"
    },
    "lineBreaks" : {
      "additionalProperties" : false,
      "description" : "lineBreaks rule group.",
      "properties" : {
        "alignWrappedConditions" : {
          "description" : "Align wrapped conditions to the column after the keyword (if/guard/while).",
          "type" : "boolean"
        },
        "aroundMultilineExpressionChainComponents" : {
          "description" : "Break around multiline dot-chained components.",
          "type" : "boolean"
        },
        "beforeEachArgument" : {
          "description" : "Break before each argument when wrapping.",
          "type" : "boolean"
        },
        "beforeEachGenericRequirement" : {
          "description" : "Break before each generic requirement when wrapping.",
          "type" : "boolean"
        },
        "beforeGuardConditions" : {
          "description" : "Break before guard conditions. When true, all conditions start on a new line below guard. When false, the first condition stays on the same line as guard.",
          "type" : "boolean"
        },
        "betweenDeclarationAttributes" : {
          "description" : "Break between adjacent attributes.",
          "type" : "boolean"
        },
        "elseCatchOnNewLine" : {
          "description" : "Break before else/catch after closing brace.",
          "type" : "boolean"
        },
        "ensureLineBreakAtEOF" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Ensure the file ends with exactly one newline.\n\nMany Unix tools expect files to end with a newline. Missing trailing newlines cause\n`diff` noise and `cat` concatenation issues. Extra trailing newlines waste space.\n\nLint: If the file does not end with exactly one newline, a lint warning is raised.\n\nFormat: A trailing newline is added if missing, or extra newlines are removed.\n [opt-in]"
        },
        "lineLength" : {
          "description" : "Maximum line length before wrapping.",
          "type" : "integer"
        },
        "modifiersOnSameLine" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Ensure all modifiers are on the same line as the declaration keyword.\n\nModifiers (not attributes) that appear on separate lines from the declaration keyword\nare joined onto the same line. Attributes may remain on their own lines.\n\nLint: If any modifier is on a different line than the declaration keyword, a lint warning\nis raised.\n\nFormat: Newlines between modifiers and the declaration keyword are replaced with spaces.\n"
        },
        "respectExisting" : {
          "description" : "Preserve discretionary line breaks.",
          "type" : "boolean"
        },
        "wrapTernary" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Wrap each branch of a ternary expression onto its own line when the expression\nwould exceed the configured line length.\n\nThe pretty printer no longer makes wrapping decisions for ternaries — instead, this\nrule inserts discretionary newlines into the leading trivia of `?` and `:` whenever\nthe ternary's last column would exceed `LineLength`. The pretty printer respects\nthose newlines (see `RespectsExistingLineBreaks`) and applies a continuation indent\nto each wrapped branch, producing:\n\n```swift\npendingLeadingTrivia = trailingNonSpace.isEmpty\n  ? token.leadingTrivia\n  : token.leadingTrivia + trailingNonSpace\n```\n\nIf either operator already has a leading newline, the rule normalizes the other to\nmatch so the ternary always has both branches on their own lines once it wraps.\n"
        }
      },
      "type" : "object"
    },
    "literals" : {
      "additionalProperties" : false,
      "description" : "literals rule group.",
      "properties" : {
        "duplicateDictionaryKeys" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Dictionary literals with duplicate keys silently overwrite earlier values.\n\nThe Swift compiler accepts duplicate static keys but the resulting dictionary\nonly retains the *last* value for each key — almost always a copy-paste bug.\n\nOnly static keys are checked: literals, identifiers, and member access\nexpressions. Dynamic keys like `UUID()` or `#line` can legitimately produce\ndistinct values at runtime and are skipped.\n\nLint: When a static key appears more than once in the same dictionary\nliteral, every occurrence after the first is flagged.\n",
          "unevaluatedProperties" : false
        },
        "groupNumericLiterals" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Numeric literals should be grouped with `_`s to delimit common separators.\n\nSpecifically, decimal numeric literals should be grouped every 3 numbers, hexadecimal every 4,\nand binary every 8.\n\nLint: If a numeric literal is too long and should be grouped, a lint error is raised.\n\nFormat: All numeric literals that should be grouped will have `_`s inserted where appropriate.\n\nTODO: Minimum numeric literal length bounds and numeric groupings have been selected arbitrarily;\nthese could be reevaluated.\nTODO: Handle floating point literals.\n"
        },
        "invisibleCharacters" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Zero-width and other invisible Unicode characters in string literals are\nalmost always typos or paste artifacts. They're impossible to see in source\nand cause string equality, lookup, and URL parsing to silently fail.\n\nThe default character set is U+200B (zero-width space), U+200C (zero-width\nnon-joiner), and U+FEFF (BOM). Configure additional code points via\n`invisibleCharacters.additionalCodePoints` (an array of hex strings, e.g.\n`[\"00AD\", \"200D\"]`).\n\nLint: When a string literal segment contains any of the configured\ninvisible code points, an error is raised at the offending character.\n",
          "properties" : {
            "additionalCodePoints" : {
              "description" : "additionalCodePoints",
              "items" : {
                "type" : "string"
              },
              "type" : "array"
            }
          },
          "unevaluatedProperties" : false
        },
        "multiElementCollectionTrailingCommas" : {
          "description" : "Trailing commas in multi-element collection literals.",
          "type" : "boolean"
        },
        "multilineTrailingCommaBehavior" : {
          "default" : "keptAsWritten",
          "description" : "Trailing comma handling in multiline lists. Options: alwaysUsed, neverUsed, keptAsWritten.",
          "enum" : [
            "alwaysUsed",
            "neverUsed",
            "keptAsWritten"
          ],
          "type" : "string"
        },
        "noLiteralProtocolInit" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Initializers declared in `ExpressibleBy*` literal protocols are intended\nfor the compiler. Calling them directly (`Set(arrayLiteral: 1, 2)`) is\nalmost certainly a mistake — the literal form (`[1, 2]`) is shorter,\nfaster, and more idiomatic.\n\nLint: When a known standard-library or Foundation type is initialized via\na compiler-protocol label like `arrayLiteral`/`dictionaryLiteral`/\n`stringLiteral`, a warning is raised.\n",
          "unevaluatedProperties" : false
        },
        "noPlaygroundLiterals" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "The playground literals (`#colorLiteral`, `#fileLiteral`, and `#imageLiteral`) are forbidden.\n\nLint: Using a playground literal will yield a lint error with a suggestion of an API to replace\nit.\n",
          "unevaluatedProperties" : false
        },
        "reflowMultilineStringLiterals" : {
          "default" : "never",
          "description" : "Multiline string literal reflow mode. Options: never, onlyLinesOverLength, always.",
          "enum" : [
            "never",
            "onlyLinesOverLength",
            "always"
          ],
          "type" : "string"
        },
        "urlMacro" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Replace force-unwrapped `URL(string:)` initializers with a configured URL macro.\n\nWhen configured with a macro name like `#URL` and module like `URLFoundation`, this rule\nconverts `URL(string: \"https://example.com\")!` to `#URL(\"https://example.com\")` and adds\nthe module import if not already present.\n\nOnly simple string literals are converted — string interpolations, concatenations, and\nnon-literal expressions are left alone. The `URL(string:relativeTo:)` and\n`URL(fileURLWithPath:)` initializers are not affected.\n\nThis rule is opt-in and requires configuration via `urlMacro.macroName` and\n`urlMacro.moduleName` in the configuration file.\n\nLint: A warning is raised for each `URL(string: \"...\")!` that can be converted.\n\nFormat: The force-unwrapped URL initializer is replaced with the configured macro.\n [opt-in]",
          "properties" : {
            "macroName" : {
              "description" : "macroName",
              "type" : "string"
            },
            "moduleName" : {
              "description" : "moduleName",
              "type" : "string"
            }
          }
        },
        "useShortArrayLiteral" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Never use `[<Type>]()` syntax. In call sites that should be replaced with `[]`,\nfor initializations use explicit type combined with empty array literal `let _: [<Type>] = []`\nStatic properties of a type that return that type should not include a reference to their type.\n\nLint:  Non-literal empty array initialization will yield a lint error.\nFormat: All invalid use sites would be related with empty literal (with or without explicit type annotation).\n [opt-in]"
        }
      },
      "type" : "object"
    },
    "modifierOrder" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Enforce consistent ordering for declaration modifiers.\n\nModifiers should appear in a canonical order: access control, then `override`, then\n`class`/`static`, then other modifiers. For example, `public static func` not\n`static public func`.\n\nLint: If modifiers are out of order, a lint warning is raised.\n\nFormat: The modifiers are reordered to match the canonical order.\n"
    },
    "modifiersOnSameLine" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Ensure all modifiers are on the same line as the declaration keyword.\n\nModifiers (not attributes) that appear on separate lines from the declaration keyword\nare joined onto the same line. Attributes may remain on their own lines.\n\nLint: If any modifier is on a different line than the declaration keyword, a lint warning\nis raised.\n\nFormat: Newlines between modifiers and the declaration keyword are replaced with spaces.\n"
    },
    "multilineFunctionChains" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Chained function calls are wrapped consistently: if any dot in the chain\nis on a different line, all dots are placed on separate lines.\n\nLint: A multiline chain where some dots share a line raises a warning.\n\nFormat: Dots that share a line with a closing scope or another dot are\n        moved to their own line.\n [opt-in]"
    },
    "multilineStatementBraces" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Opening braces of multiline statements are wrapped to their own line.\n\nWhen a statement signature (conditions, parameters, etc.) spans multiple\nlines, the opening `{` is moved to its own line, aligned with the\nstatement keyword.\n\nLint: A `{` on the same line as a multiline statement signature raises a\n      warning.\n\nFormat: The `{` is moved to a new line aligned with the closing `}`.\n [opt-in]"
    },
    "mutableCapture" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Capturing a `var` by name in a closure captures its current value, not the\nvariable. Subsequent mutations through the original binding are invisible\nto the closure, which is almost always surprising.\n\nThis rule is purely syntactic: it pre-scans the source file for `var`\ndeclarations (excluding `lazy var` and IUOs) and flags closure captures\nwhose name matches any such declaration. Captures with an explicit\ninitializer (`[x = self.x]`) and `weak`/`unowned` captures are not flagged.\n\nLint: When a closure captures a name that matches a `var` declaration in\nthe same file, a warning is raised.\n",
      "unevaluatedProperties" : false
    },
    "namedClosureParams" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Use named arguments in multi-line closures.\n\nInside a single-line closure, `$0`/`$1` is concise and idiomatic. Inside a multi-line closure\nthe anonymous form forces readers to track which argument is which by counting; an explicit\n`arg in` parameter list reads more clearly.\n\nLint: A warning is raised for each `$0`/`$1`/... reference inside a multi-line closure.\n\nFormat: Not auto-fixed; the rule cannot pick a meaningful parameter name.\n [opt-in]"
    },
    "naming" : {
      "additionalProperties" : false,
      "description" : "naming rule group.",
      "properties" : {
        "camelCaseIdentifiers" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "All values should be written in lower camel-case (`lowerCamelCase`).\nUnderscores (except at the beginning of an identifier) are disallowed.\n\nThis rule does not apply to test code, defined as code which:\n  * Contains the line `import XCTest`\n  * The function is marked with `@Test` attribute\n\nLint: If an identifier contains underscores or begins with a capital letter, a lint error is\n      raised.\n",
          "unevaluatedProperties" : false
        },
        "capitalizeTypeNames" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "`struct`, `class`, `enum` and `protocol` declarations should have a capitalized name.\n\nLint:  Types with un-capitalized names will yield a lint error.\n",
          "unevaluatedProperties" : false
        },
        "identifiersMayOnlyUseASCII" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "All identifiers must be ASCII.\n\nLint: If an identifier contains non-ASCII characters, a lint error is raised.\n",
          "unevaluatedProperties" : false
        },
        "noLeadingUnderscores" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Identifiers in declarations and patterns should not have leading underscores.\n\nThis is intended to avoid certain anti-patterns; `self.member = member` should be preferred to\n`member = _member` and the leading underscore should not be used to signal access level.\n\nThis rule intentionally checks only the parameter variable names of a function declaration, not\nthe parameter labels. It also only checks identifiers at the declaration site, not at usage\nsites.\n\nLint: Declaring an identifier with a leading underscore yields a lint error.\n",
          "unevaluatedProperties" : false
        },
        "uppercaseAcronyms" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Capitalize acronyms when the first character is capitalized.\n\nWhen an identifier contains a titlecased acronym (e.g. `Url`, `Json`, `Id`),\nit should be fully uppercased (e.g. `URL`, `JSON`, `ID`) for consistency with\nSwift naming conventions.\n\nThe list of recognized acronyms is configurable via `Configuration.acronyms`.\n\nLint: An identifier with a titlecased acronym raises a warning.\n\nFormat: The titlecased acronym is replaced with the uppercased form.\n [opt-in]",
          "properties" : {
            "words" : {
              "description" : "words",
              "items" : {
                "type" : "string"
              },
              "type" : "array"
            }
          }
        }
      },
      "type" : "object"
    },
    "nestedAwait" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Move inline `await` keyword(s) to the start of the expression.\n\nWhen `await` appears inside function call arguments, it can be hoisted to wrap the\nentire call expression. This is clearer and avoids redundant `await` keywords when\nmultiple arguments are async.\n\nFor example, `foo(await bar(), await baz())` should be `await foo(bar(), baz())`.\n\nThis rule does not flag `await` inside closures (which have their own async context)\nor when the call is already wrapped in `await`.\n\nLint: Using `await` inside a function call argument raises a warning.\n\nFormat: `await` is removed from arguments and added to wrap the call expression.\n"
    },
    "nestedCallLayout" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Controls the layout of nested function/initializer calls where the sole\nargument to one call is another call.\n\n**Inline mode**: Collapses deeply nested calls into the most compact form\nthat fits the line width, trying each layout in order:\n\n1. Fully inline:\n   ```swift\n   result = ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))\n   ```\n\n2. Outer inline, inner wrapped:\n   ```swift\n   result = ExprSyntax(ForceUnwrapExprSyntax(\n       expression: result,\n       trailingTrivia: trivia\n   ))\n   ```\n\n3. Fully wrapped (outer on new line, inner inline):\n   ```swift\n   result = ExprSyntax(\n       ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia)\n   )\n   ```\n\n4. Fully nested (no change).\n\n**Wrap mode**: Expands any compact form into the fully nested form with each\ncall and its arguments on separate indented lines.\n\nLint: A nested call whose layout doesn't match the mode raises a warning.\n\nFormat: The call tree is reformatted to match the mode.\n [opt-in]",
      "properties" : {
        "mode" : {
          "default" : "inline",
          "description" : "mode Options: inline, wrap.",
          "enum" : [
            "inline",
            "wrap"
          ],
          "type" : "string"
        }
      }
    },
    "nestedTry" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Move inline `try` keyword(s) to the start of the expression.\n\nWhen `try` appears inside function call arguments, it can be hoisted to wrap the\nentire call expression. This is clearer and avoids redundant `try` keywords when\nmultiple arguments throw.\n\nFor example, `foo(try bar(), try baz())` should be `try foo(bar(), baz())`.\n\nThis rule does not flag `try` inside closures (which have their own throwing context)\nor when the call is already wrapped in `try`. Only plain `try` is hoisted (not\n`try?` or `try!`).\n\nLint: Using `try` inside a function call argument raises a warning.\n\nFormat: `try` is removed from arguments and added to wrap the call expression.\n"
    },
    "noAssignmentInExpressions" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Assignment expressions must be their own statements.\n\nAssignment should not be used in an expression context that expects a `Void` value. For example,\nassigning a variable within a `return` statement exiting a `Void` function is prohibited.\n\nLint: If an assignment expression is found in a position other than a standalone statement, a\n      lint finding is emitted.\n\nFormat: A `return` statement containing an assignment expression is expanded into two separate\n        statements.\n",
      "properties" : {
        "allowedFunctions" : {
          "description" : "allowedFunctions",
          "items" : {
            "type" : "string"
          },
          "type" : "array"
        }
      }
    },
    "noBacktickedSelf" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove backticks around `self` in optional unwrap expressions.\n\nSince Swift 4.2, `guard let self = self` is valid without backticks.\nWriting `` guard let `self` = self `` is a holdover from older Swift versions.\n\nLint: If a backticked `self` is found in an optional binding, a finding is raised.\n\nFormat: The backticks are removed.\n"
    },
    "noExplicitOwnership" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove explicit `borrowing` and `consuming` ownership modifiers.\n\nOwnership modifiers are an advanced feature that most code does not need. When present\non function declarations (e.g. `consuming func move()`) or parameter types\n(e.g. `func foo(_ bar: consuming Bar)`), they are removed.\n\nLint: If an explicit `borrowing` or `consuming` modifier is found, a lint warning is raised.\n\nFormat: The ownership modifier is removed.\n [opt-in]"
    },
    "noFallThroughOnlyCases" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Cases that contain only the `fallthrough` statement are forbidden.\n\nLint: Cases containing only the `fallthrough` statement yield a lint error.\n\nFormat: The fall-through `case` is added as a prefix to the next case unless the next case is\n        `default`; in that case, the fallthrough `case` is deleted.\n"
    },
    "noForceCast" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Force casts (`as!`) are forbidden.\n\nA force cast crashes at runtime if the conversion fails. Prefer the conditional cast (`as?`)\ncombined with optional handling (`if let`, `guard let`, nil-coalescing, etc.).\n\nThis rule complements `NoForceTry` and `NoForceUnwrap`.\n\nLint: A warning is raised for each `as!`.\n\nFormat: Not auto-fixed; the safe replacement depends on caller intent.\n [opt-in]"
    },
    "noForceTry" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Force-try (`try!`) is forbidden.\n\nIn test functions, `try!` is auto-fixed to `try` and `throws` is added to the function\nsignature if needed.\n\nIn non-test code, `try!` is diagnosed but not rewritten.\n\nTest functions are:\n- Functions annotated with `@Test` (Swift Testing)\n- Functions named `test*()` with no parameters inside `XCTestCase` subclasses\n\n`try!` inside closures or nested functions is left alone because the enclosing test function's\n`throws` does not propagate into those scopes.\n\nLint: A warning is raised for each `try!`.\n\nFormat: In test functions, `try!` is replaced with `try` and `throws` is added.\n [opt-in]"
    },
    "noForceUnwrap" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Force-unwraps are strongly discouraged and must be documented.\n\nIn test functions, force unwraps are auto-fixed:\n- `foo!` becomes `try XCTUnwrap(foo)` (XCTest) or `try #require(foo)` (Swift Testing)\n- `foo as! Bar` becomes `try XCTUnwrap(foo as? Bar)` or `try #require(foo as? Bar)`\n- `throws` is added to the function signature if needed\n\nIn non-test code, force unwraps are diagnosed but not rewritten.\n\nTest functions are:\n- Functions annotated with `@Test` (Swift Testing)\n- Functions named `test*()` with no parameters inside `XCTestCase` subclasses\n\nForce unwraps in closures, nested functions, and string interpolation are left alone because\n`try` cannot propagate out of those scopes.\n\nLint: A warning is raised for each force unwrap.\n\nFormat: In test functions, force unwraps are replaced with XCTUnwrap/#require.\n [opt-in]"
    },
    "noGuardInTests" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Convert `guard` statements in test functions to `try #require(...)`/`#expect(...)` (Swift\nTesting) or `try XCTUnwrap(...)`/`XCTAssert(...)` (XCTest).\n\nGuard statements in tests obscure the test intent behind control flow. Replacing them with\ndirect assertions or unwraps makes the test linear and the failure message immediate.\n\nThis rule applies to:\n- Functions annotated with `@Test` (Swift Testing)\n- Functions named `test*()` with no parameters inside `XCTestCase` subclasses\n\nGuards inside closures or nested functions are left alone because the enclosing test function's\n`throws` does not propagate into those scopes.\n\nLint: A warning is raised for each `guard` that can be converted.\n\nFormat: The `guard` is replaced with assertion/unwrap statements and `throws` is added to\nthe signature if needed.\n [opt-in]"
    },
    "noImplicitlyUnwrappedOptionals" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Implicitly unwrapped optionals (e.g. `var s: String!`) are forbidden.\n\nCertain properties (e.g. `@IBOutlet`) tied to the UI lifecycle are ignored.\n\nThis rule does not apply to test code, defined as code which:\n  * Contains the line `import XCTest`\n  * The function is marked with `@Test` attribute\n\nTODO: Create exceptions for other UI elements (ex: viewDidLoad)\n\nLint: Declaring a property with an implicitly unwrapped type yields a lint error.\n",
      "unevaluatedProperties" : false
    },
    "noLabelsInCasePatterns" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Redundant labels are forbidden in case patterns.\n\nIn practice, *all* case pattern labels should be redundant.\n\nLint: Using a label in a case statement yields a lint error unless the label does not match the\n      binding identifier.\n\nFormat: Redundant labels in case patterns are removed.\n"
    },
    "noLeadingUnderscores" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Identifiers in declarations and patterns should not have leading underscores.\n\nThis is intended to avoid certain anti-patterns; `self.member = member` should be preferred to\n`member = _member` and the leading underscore should not be used to signal access level.\n\nThis rule intentionally checks only the parameter variable names of a function declaration, not\nthe parameter labels. It also only checks identifiers at the declaration site, not at usage\nsites.\n\nLint: Declaring an identifier with a leading underscore yields a lint error.\n",
      "unevaluatedProperties" : false
    },
    "noLiteralProtocolInit" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Initializers declared in `ExpressibleBy*` literal protocols are intended\nfor the compiler. Calling them directly (`Set(arrayLiteral: 1, 2)`) is\nalmost certainly a mistake — the literal form (`[1, 2]`) is shorter,\nfaster, and more idiomatic.\n\nLint: When a known standard-library or Foundation type is initialized via\na compiler-protocol label like `arrayLiteral`/`dictionaryLiteral`/\n`stringLiteral`, a warning is raised.\n",
      "unevaluatedProperties" : false
    },
    "noParensAroundConditions" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Enforces rules around parentheses in conditions, matched expressions, return statements, and\ninitializer assignments.\n\nParentheses are not used around any condition of an `if`, `guard`, or `while` statement, around\nthe matched expression in a `switch` statement, around `return` values, or around initializer\nvalues in variable/constant declarations.\n\nLint: If a top-most expression in a `switch`, `if`, `guard`, `while`, or `return` statement, or\n      in a variable initializer, is surrounded by parentheses, and it does not include a function\n      call with a trailing closure, a lint error is raised.\n\nFormat: Parentheses around such expressions are removed, if they do not cause a parse ambiguity.\n        Specifically, parentheses are allowed if and only if the expression contains a function\n        call with a trailing closure.\n"
    },
    "noParensInClosureParams" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove parentheses around closure parameter lists when no parameter has a type annotation.\n\n`{ (x, y) in ... }` is equivalent to `{ x, y in ... }` when the parameters are untyped —\nthe parens add visual noise. Typed parameter lists (`{ (x: Int) in }`) keep the parens\nbecause shorthand parameters can't carry types.\n\nLint: A finding is raised at the parameter clause.\n\nFormat: The parenthesized parameter list is converted to shorthand (`x, y`).\n"
    },
    "noPlaygroundLiterals" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "The playground literals (`#colorLiteral`, `#fileLiteral`, and `#imageLiteral`) are forbidden.\n\nLint: Using a playground literal will yield a lint error with a suggestion of an API to replace\nit.\n",
      "unevaluatedProperties" : false
    },
    "noRetroactiveConformances" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "`@retroactive` conformances are forbidden.\n\nLint: Using `@retroactive` results in a lint error.\n",
      "unevaluatedProperties" : false
    },
    "noTrailingClosureParens" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Function calls with no arguments and a trailing closure should not have empty parentheses.\n\nLint: If a function call with a trailing closure has an empty argument list with parentheses,\n      a lint error is raised.\n\nFormat: Empty parentheses in function calls with trailing closures will be removed.\n"
    },
    "noTypeRepetitionInStaticProperties" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Static properties of a type that return that type should not include a reference to their type.\n\n\"Reference to their type\" means that the property name includes part, or all, of the type. If\nthe type contains a namespace (i.e. `UIColor`) the namespace is ignored;\n`public class var redColor: UIColor` would trigger this rule.\n\nLint: Static properties of a type that return that type will yield a lint error.\n",
      "unevaluatedProperties" : false
    },
    "noVoidReturnOnFunctionSignature" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Functions that return `()` or `Void` should omit the return signature.\n\nLint: Function declarations that explicitly return `()` or `Void` will yield a lint error.\n\nFormat: Function declarations with explicit returns of `()` or `Void` will have their return\n        signature stripped.\n"
    },
    "noVoidTernary" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Don't use a ternary expression to call void-returning functions.\n\n`condition ? doA() : doB()` reads as if it produces a value, but when both branches return\n`Void` it's effectively a hidden if/else with strictly worse readability. Use a proper\n`if`/`else` statement instead.\n\nLint: A warning is raised when a ternary appears as a statement and both branches are call\nexpressions.\n\nFormat: Not auto-fixed; the rewrite would change formatting beyond the scope of this rule.\n [opt-in]"
    },
    "noYodaConditions" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer the constant value on the right-hand side of comparison expressions.\n\n\"Yoda conditions\" place the constant on the left (`0 == x`), which reads unnaturally.\nThe conventional Swift style places the variable first (`x == 0`).\n\nFor ordered comparisons (`<`, `<=`, `>`, `>=`), the operator is flipped when swapping\nsides so the semantics are preserved.\n\nLint: A comparison with a constant on the left raises a warning.\n\nFormat: The operands are swapped and the operator is flipped if necessary.\n"
    },
    "oneDeclarationPerLine" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Each enum case with associated values or a raw value should appear in its own case declaration,\nand each variable declaration (except tuple destructuring) should declare only one variable.\n\nLint: If a single `case` declaration declares multiple cases where any has associated values or\n      raw values, or if a variable declaration declares multiple variables, a lint error is\n      raised.\n\nFormat: Case declarations with associated values or raw values will be moved to their own case\n        declarations. Variable declarations with multiple bindings will be split into individual\n        declarations.\n"
    },
    "onlyOneTrailingClosureArgument" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Function calls should never mix normal closure arguments and trailing closures.\n\nLint: If a function call with a trailing closure also contains a non-trailing closure argument,\n      a lint error is raised.\n",
      "unevaluatedProperties" : false
    },
    "opaqueGenericParameters" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Use opaque generic parameters (`some Protocol`) instead of named generic parameters\nwith constraints (`<T: Protocol>`) where equivalent.\n\nThis rule applies to `func`, `init`, and `subscript` declarations. A generic type parameter\nis eligible for conversion when it appears exactly once in the parameter list and is not\nreferenced in the return type, function body, attributes, typed throws, or other generic\nconstraints.\n\nLint: A lint warning is raised when a generic parameter can be replaced with an opaque parameter.\n\nFormat: The generic parameter is replaced with `some Protocol` in the parameter type.\n [opt-in]"
    },
    "precedeModifiers" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Place doc comments before any declaration modifiers or attributes.\n\nDoc comments (`///` or `/** */`) should appear before all attributes and access modifiers,\nnot between them.\n\nLint: If a doc comment appears after an attribute or modifier, a lint warning is raised.\n\nFormat: The doc comment is moved before all attributes and modifiers.\n"
    },
    "preferAngleBracketExtensions" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Use angle brackets (`extension Array<Foo>`) for generic type extensions instead of\ntype constraints (`extension Array where Element == Foo`).\n\nSwift 5.7+ supports angle bracket syntax in extension declarations. When a `where`\nclause constrains all generic parameters of a known type to concrete types,\nthe angle bracket form is more concise.\n\nKnown types: `Array`, `Set`, `Optional`, `Dictionary`, `Collection`, `Sequence`.\n\nLint: An extension with a `where` clause that can be replaced by angle brackets raises a warning.\n\nFormat: The `where` clause constraints are moved into angle bracket syntax on the\nextended type.\n"
    },
    "preferAnyObject" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer `AnyObject` over `class` for class-constrained protocols.\n\nThe `class` keyword in protocol inheritance clauses was replaced by `AnyObject` in Swift 4.1.\nUsing `AnyObject` is the modern, preferred spelling.\n\nLint: A protocol inheriting from `class` instead of `AnyObject` raises a warning.\n\nFormat: `class` is replaced with `AnyObject` in the inheritance clause.\n"
    },
    "preferAssertionFailure" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Replace `assert(false, ...)` with `assertionFailure(...)` and\n`precondition(false, ...)` with `preconditionFailure(...)`.\n\nThe `Failure` variants more clearly express intent: the code path should never be reached.\nThey also have `Never` return type, enabling the compiler to prove exhaustiveness.\n\nLint: Using `assert(false, ...)` or `precondition(false, ...)` raises a warning.\n\nFormat: The call is replaced with the corresponding `Failure` variant, removing the\n`false` argument.\n"
    },
    "preferCommaConditions" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer comma over `&&` in `if`, `guard`, and `while` conditions.\n\nSwift condition lists use commas to separate independent boolean conditions,\nwhich short-circuit identically to `&&` but read more naturally and enable\nindividual conditions to use optional binding or pattern matching.\n\nThis rule only fires when `&&` is the top-level operator in a condition element\n(no `||` mixed in at the same precedence level, since that would change semantics).\n\nLint: Using `&&` in a condition list raises a warning.\n\nFormat: `&&` is replaced with commas, splitting the condition into separate\ncondition elements.\n"
    },
    "preferCompoundAssignment" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer compound assignment operators (`+=`, `-=`, `*=`, `/=`) over the long form.\n\n`x = x + y` is exactly equivalent to `x += y` for the supported operators (`+`, `-`, `*`, `/`).\nThe compound form is shorter and avoids repeating the LHS, which makes refactors safer when the\nreceiver is renamed.\n\nThe rule fires only when the LHS expression text matches the RHS's first operand exactly. It\ndoes not fire on `x = a + x` or `x = a + b` patterns.\n\nLint: A warning is raised for `x = x + y` etc.\n\nFormat: The expression is rewritten to `x += y`.\n"
    },
    "preferConditionalExpression" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Use if/switch expressions for conditional property assignment.\n\nWhen a property with a type annotation and no initializer is immediately\nfollowed by an exhaustive `if` or `switch` that assigns the property in\nevery branch, the two statements are merged into a single assignment\nexpression. Nested conditionals are handled recursively.\n\nLint: A property followed by an exhaustive conditional assignment raises\n      a warning.\n\nFormat: The separate statements are merged into a conditional expression\n        assignment.\n [opt-in]"
    },
    "preferCountWhere" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer `count(where:)` over `filter(_:).count`.\n\nThe `count(where:)` method (Swift 6.0+) is more expressive and avoids allocating an\nintermediate array just to count its elements.\n\nLint: Using `.filter { ... }.count` raises a warning suggesting `count(where:)`.\n\nFormat: `.filter { ... }.count` is replaced with `.count(where: { ... })`.\n"
    },
    "preferDotZero" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer `.zero` over explicit zero-valued initializers.\n\n`CGPoint(x: 0, y: 0)`, `CGSize(width: 0, height: 0)`, `CGRect(x: 0, y: 0, width: 0, height: 0)`\nand similar are equivalent to the platform-provided `.zero` constant. The shorthand reads\nbetter and avoids subtle inconsistencies (e.g. `0.0` vs `0` literal kinds).\n\nRecognised types: `CGPoint`, `CGSize`, `CGRect`, `CGVector`, `UIEdgeInsets`, `NSEdgeInsets`,\n`NSPoint`, `NSSize`, `NSRect`.\n\nLint: A warning is raised on a fully-zero initializer.\n\nFormat: The call is replaced with `<Type>.zero`.\n"
    },
    "preferEarlyExits" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Early exits should be used whenever possible.\n\nThis means that `if ... else { return/throw/break/continue }` constructs should be replaced by\n`guard ... else { return/throw/break/continue }` constructs in order to keep indentation levels\nlow. Specifically, code of the following form:\n\n```swift\nif condition {\n  trueBlock\n} else {\n  falseBlock\n  return/throw/break/continue\n}\n```\n\nwill be transformed into:\n\n```swift\nguard condition else {\n  falseBlock\n  return/throw/break/continue\n}\ntrueBlock\n```\n\nLint: `if ... else { return/throw/break/continue }` constructs will yield a lint error.\n\nFormat: `if ... else { return/throw/break/continue }` constructs will be replaced with\n        equivalent `guard ... else { return/throw/break/continue }` constructs.\n [opt-in]"
    },
    "preferEnvironmentEntry" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Use `@Entry` macro for `EnvironmentValues` instead of manual `EnvironmentKey` conformance.\n\nRecognizes `EnvironmentKey`-conforming structs/enums paired with `EnvironmentValues` extension\nproperties and replaces them with `@Entry var` declarations.\n\nLint: A lint warning is raised when an `EnvironmentKey` property can be replaced with `@Entry`.\n\nFormat: The `EnvironmentKey` type is removed and the property is replaced with `@Entry var`.\n [opt-in]"
    },
    "preferExplicitFalse" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer `== false` over `!` prefix negation.\n\nThe `!` prefix operator can be easy to miss, especially in complex conditions.\nUsing `== false` makes the negation explicit and more readable.\n\nLint: Using `!` prefix negation raises a warning.\n\nFormat: `!expression` is replaced with `expression == false`.\n [opt-in]"
    },
    "preferFileID" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Enforce consistent use of `#file` or `#fileID`.\n\nIn Swift 6+, `#file` and `#fileID` have identical behavior (both produce `Module/File.swift`).\nThis rule standardizes usage to `#fileID` by default. `#filePath` is unaffected.\n\nLint: Using the non-preferred file macro yields a lint warning.\n\nFormat: The macro is replaced with the preferred spelling.\n [opt-in]"
    },
    "preferFinalClasses" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer `final class` unless a class is designed for subclassing.\n\nClasses should be `final` by default to communicate that they are not designed to be\nsubclassed. Classes are left non-final if they are `open`, have \"Base\" in the name,\nhave a comment mentioning \"base\" or \"subclass\", or are subclassed within the same file.\n\nWhen a class is made `final`, any `open` members are converted to `public` since\n`final` classes cannot have `open` members.\n\nLint: A non-final, non-open class declaration raises a warning.\n\nFormat: The `final` modifier is added and `open` members are converted to `public`.\n [opt-in]"
    },
    "preferIfElseChain" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Consecutive single-return `if` statements followed by a final `return` should\nbe expressed as a chained `if/else` expression.\n\nWhen a sequence of `if` statements each contain only a `return` and are\nfollowed by a trailing `return`, the chain is converted into a single\n`if/else if/.../else` expression (two or more `if` branches required).\n\n```swift\n// Before\nif case .spaces = $0 { return true }\nif case .tabs = $0 { return true }\nreturn false\n\n// After\nif case .spaces = $0 {\n    true\n} else if case .tabs = $0 {\n    true\n} else {\n    false\n}\n```\n\nLint: A chain of early-return `if` statements raises a warning.\n\nFormat: The chain is replaced with an `if/else` expression.\n"
    },
    "preferIsDisjoint" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer `Set.isDisjoint(with:)` over `Set.intersection(_:).isEmpty`.\n\n`isDisjoint(with:)` expresses intent more directly and can short-circuit on the first shared\nelement, whereas `intersection(_:)` always builds the full intersection set.\n\nLint: A warning is raised on `someSet.intersection(other).isEmpty`.\n\nFormat: Not auto-fixed; the receiver may not be a `Set`, so the rewrite is unsafe in general.\n [opt-in]"
    },
    "preferIsEmpty" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer `isEmpty` over comparing `count` against zero.\n\nChecking `count == 0` or `count != 0` (or `count > 0`) is less expressive and potentially less\nefficient than using `isEmpty`. Collections conforming to `Collection` guarantee O(1) `isEmpty`\nbut `count` may be O(n) for some types (e.g. lazy sequences conforming to `Collection`).\n\nWhen the receiver is optional (`foo?.count == 0`), the replacement uses explicit boolean\ncomparison (`foo?.isEmpty == true`) to preserve semantics.\n\nThis rule is opt-in because not every type with a `count` property also provides `isEmpty`.\n\nLint: Using `.count == 0`, `.count != 0`, or `.count > 0` raises a warning.\n\nFormat: The comparison is replaced with `.isEmpty` or `!.isEmpty`.\n [opt-in]"
    },
    "preferKeyPath" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Convert trivial `map { $0.foo }` closures to keyPath-based syntax.\n\nWhen a closure's only expression is a property access on `$0`, the closure can be\nreplaced with a keyPath expression: `map(\\.foo)`. This is more concise and expressive.\n\nApplies to `map`, `flatMap`, `compactMap`, `allSatisfy`, `filter`, and `contains(where:)`.\n\nOnly fires for simple property chains (not method calls, subscripts, or complex expressions).\n\nLint: A trivial `{ $0.property }` closure raises a warning.\n\nFormat: The closure is replaced with a keyPath expression.\n [opt-in]"
    },
    "preferMainAttribute" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Replace `@UIApplicationMain` and `@NSApplicationMain` with `@main`.\n\nThese attributes were deprecated in favor of `@main` (SE-0383, Swift 5.3+).\n\nLint: Using `@UIApplicationMain` or `@NSApplicationMain` raises a warning.\n\nFormat: The attribute is replaced with `@main`.\n"
    },
    "preferSelfType" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer `Self` over `type(of: self)`.\n\nInside a class/struct/enum/actor, `Self` refers to the current type and is fully equivalent to\n`type(of: self)` for any non-polymorphic dispatch. The shorthand is more concise and avoids\nthe runtime call.\n\nThis rule does not fire at the top level of a file (where `self` does not refer to an enclosing\ntype) or for non-`self` arguments (`type(of: param)` is preserved).\n\nLint: A warning is raised for `type(of: self)` (also `Swift.type(of: self)`) inside a type.\n\nFormat: The call is replaced with `Self`.\n"
    },
    "preferShorthandTypeNames" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Shorthand type forms must be used wherever possible.\n\nLint: Using a non-shorthand form (e.g. `Array<Element>`) yields a lint error unless the long\n      form is necessary (e.g. `Array<Element>.Index` cannot be shortened today.)\n\nFormat: Where possible, shorthand types replace long form types; e.g. `Array<Element>` is\n        converted to `[Element]`.\n"
    },
    "preferSingleLinePropertyGetter" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Read-only computed properties must use implicit `get` blocks.\n\nLint: Read-only computed properties with explicit `get` blocks yield a lint error.\n\nFormat: Explicit `get` blocks are rendered implicit by removing the `get`.\n"
    },
    "preferStaticOverClassFunc" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer `static` over `class` for type members of `final` classes.\n\nIn a `final` class, `class func` and `class var` are equivalent to `static func` and\n`static var` since the class cannot be subclassed. Using `static` makes the intent clearer.\n\nMembers carrying `override` are skipped: the parent's signature uses `class` so the override\nchain remains open; switching to `static` would close that chain even though this class is\nfinal, and may break the override under generic specialization.\n\nLint: If a `class` modifier is found on a non-override member of a `final` class, a warning is raised.\n\nFormat: The `class` modifier is replaced with `static`.\n [opt-in]"
    },
    "preferSwiftTesting" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Convert XCTest suites to Swift Testing.\n\nReplaces `import XCTest` with `import Testing` + `import Foundation`, removes `XCTestCase`\nconformance, converts `setUp`/`tearDown` to `init`/`deinit`, adds `@Test` to test methods,\nand converts XCT assertions to `#expect`/`#require`.\n\nBails out entirely if the file contains unsupported XCTest functionality (expectations,\nperformance tests, unknown overrides, async/throws tearDown, XCTestCase extensions).\n\nLint: A warning is raised for each XCTest pattern that can be converted.\n\nFormat: The XCTest patterns are replaced with Swift Testing equivalents.\n [opt-in]"
    },
    "preferSynthesizedInitializer" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "When possible, the synthesized `struct` initializer should be used.\n\nThis means the creation of a (non-public) memberwise initializer with the same structure as the\nsynthesized initializer is forbidden.\n\nLint: (Non-public) memberwise initializers with the same structure as the synthesized\n      initializer will yield a lint error.\n",
      "unevaluatedProperties" : false
    },
    "preferTernary" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Use ternary conditional expressions for simple if-else returns or assignments.\n\nWhen an `if`-`else` has exactly two branches, each containing a single\n`return` statement or a single assignment to the same variable, and the\ncondition is a simple expression (no else-if chains), the construct is\ncollapsed into a ternary conditional expression.\n\n```swift\n// Before\nif condition {\n    return trueValue\n} else {\n    return falseValue\n}\n// After\nreturn condition ? trueValue : falseValue\n\n// Before\nif condition {\n    result = trueValue\n} else {\n    result = falseValue\n}\n// After\nresult = condition ? trueValue : falseValue\n```\n\nLint: A simple if-else with single returns or same-variable assignments\n      in both branches raises a warning.\n\nFormat: The if-else is replaced with a ternary expression.\n [opt-in]"
    },
    "preferToggle" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer `someBool.toggle()` over `someBool = !someBool`.\n\n`Bool.toggle()` (Swift 4.2+) is more concise and clearly communicates the intent. The two forms\nare equivalent semantically; `toggle()` does not introduce any new evaluation hazards.\n\nLint: A warning is raised for `x = !x` patterns where the LHS and the negated RHS reference\nthe exact same expression text.\n\nFormat: The expression is rewritten to `x.toggle()`.\n"
    },
    "preferTrailingClosures" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Use trailing closure syntax where applicable.\n\nWhen the last argument(s) to a function call are closure expressions, convert\nthem to trailing closure syntax. For a single trailing closure, the closure must\nbe unlabeled unless the function is in the \"always trailing\" list (e.g. `async`,\n`sync`, `autoreleasepool`). For multiple trailing closures, the first must be\nunlabeled and the rest must be labeled.\n\nLint: When closure arguments could use trailing closure syntax.\n\nFormat: The closure arguments are moved to trailing closure position.\n"
    },
    "preferUnavailable" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer `#unavailable(...)` over `#available(...) {} else { ... }`.\n\nInverting an availability check via an empty `if`-body and a non-empty `else`-body is harder to\nread than the direct `#unavailable` form (Swift 5.6+). This rule rewrites the simple shape; it\ndoes not touch chains where the `else` body has its own availability check (rewriting those is\nnot a simple inversion).\n\nLint: A warning is raised on `if #available(iOS X, *) {} else { body }`.\n\nFormat: The `if` is rewritten to `if #unavailable(iOS X, *) { body }`.\n"
    },
    "preferVoidReturn" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Return `Void`, not `()`, in signatures.\n\nNote that this rule does *not* apply to function declaration signatures in order to avoid\nconflicting with `NoVoidReturnOnFunctionSignature`.\n\nLint: Returning `()` in a signature yields a lint error.\n\nFormat: `-> ()` is replaced with `-> Void`\n"
    },
    "preferWhereClausesInForLoops" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "`for` loops that consist of a single `if` statement must use `where` clauses instead.\n\nLint: `for` loops that consist of a single `if` statement yield a lint error.\n\nFormat: `for` loops that consist of a single `if` statement have the conditional of that\n        statement factored out to a `where` clause.\n [opt-in]"
    },
    "privateStateVariables" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Add `private` to `@State` properties without explicit access control.\n\nSwiftUI `@State` and `@StateObject` properties should be `private` because they are\nowned by the view and should not be set from outside. If no access control modifier is\npresent, `private` is added. Existing access modifiers (including `private(set)`) and\n`@Previewable` properties are left unchanged.\n\nLint: A `@State` or `@StateObject` property without access control raises a warning.\n\nFormat: The `private` modifier is added before the binding keyword.\n [opt-in]"
    },
    "redundancies" : {
      "additionalProperties" : false,
      "description" : "redundancies rule group.",
      "properties" : {
        "noLabelsInCasePatterns" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Redundant labels are forbidden in case patterns.\n\nIn practice, *all* case pattern labels should be redundant.\n\nLint: Using a label in a case statement yields a lint error unless the label does not match the\n      binding identifier.\n\nFormat: Redundant labels in case patterns are removed.\n"
        },
        "redundantAccessControl" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Unified rule that removes or replaces redundant access control modifiers.\n\nCombines four checks:\n\n1. **Redundant `internal`** — removes explicit `internal` since it is the default.\n   Does NOT remove `internal(set)`, which is meaningful on properties with a higher\n   getter access level (e.g. `public internal(set) var`).\n\n2. **Redundant `public`** — removes `public` on members inside non-public types\n   where it has no effect. Does NOT flag members of `public` or `package` types.\n\n3. **Redundant extension ACL** — removes access control on extension members that\n   match the extension's own access level.\n\n4. **Redundant `fileprivate`** — converts `fileprivate` to `private` where equivalent.\n   Only applies when the file contains a single logical type with no nested type\n   declarations.\n\nLint: Raises warnings for any of the above redundancies.\n\nFormat: Removes or replaces the redundant modifier.\n [opt-in]"
        },
        "redundantAsync" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove `async` from functions that contain no `await` expressions.\n\nIf a function is marked `async` but its body never uses `await`, the `async` is likely\nunnecessary. Removing it simplifies the API and removes the requirement for callers\nto use `await`.\n\nThis rule is opt-in because some functions are intentionally async for protocol\nconformance or future-proofing even if they don't currently await.\n\nLint: If an `async` function has no `await` in its body, a lint warning is raised.\n\nFormat: The `async` specifier is removed.\n [opt-in]"
        },
        "redundantBackticks" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove unnecessary backticks around identifiers.\n\nBackticks are required when an identifier is a Swift reserved keyword used in a position\nthat expects an identifier. They are redundant when the identifier is:\n- Not a keyword at all (e.g., `` `myFunc` `` → `myFunc`)\n- A keyword used after `.` in member access (e.g., `Foo.`default`` → `Foo.default`)\n- A keyword used as a function argument label (e.g., `func foo(`default`: Int)` → `func foo(default: Int)`)\n\nLint: If unnecessary backticks are found, a finding is raised.\n\nFormat: The backticks are removed.\n"
        },
        "redundantBreak" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove `break` at the end of switch cases.\n\nIn Swift, switch cases do not fall through by default. A trailing `break` at the end of a\ncase body is therefore redundant.\n\nThis rule does NOT remove labeled `break` statements (e.g. `break outerLoop`), which transfer\ncontrol to a specific enclosing statement. It also does not remove `break` when it is the\nsole statement in a case body (since at least one statement is required).\n\nLint: If a redundant `break` is found at the end of a switch case, a lint warning is raised.\n\nFormat: The redundant `break` statement is removed.\n"
        },
        "redundantClosure" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove immediately-invoked closures containing a single expression.\n\nA closure that is immediately called and contains only a single expression or return\nstatement can be replaced with just the expression.\n\nFor example: `let x = { return 42 }()` → `let x = 42`\nAnd: `let x = { someValue }()` → `let x = someValue`\n\nClosures with parameters (`in` keyword), multiple statements, empty bodies,\n`fatalError`/`preconditionFailure` calls, or `throw` are preserved.\n\nLint: If a redundant immediately-invoked closure is found, a lint warning\n      is raised.\n\nFormat: The closure wrapper and invocation are removed, leaving just the\n        expression.\n"
        },
        "redundantEnumerated" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Drop `.enumerated()` from `for` loops where one half of the tuple pattern is unused.\n\n- `for (_, x) in seq.enumerated()` → `for x in seq`\n- `for (i, _) in seq.enumerated()` → `for i in seq.indices`\n\nThe rule only rewrites when the call is exactly `seq.enumerated()` with no further chaining,\nno arguments, and no trailing closure. Closure-based usages (`seq.enumerated().map { ... }`)\nare not handled because $0/$1 reference analysis is intricate; lint a separate rule when\nthat case becomes important.\n\nLint: A finding is raised at `enumerated`.\n\nFormat: `.enumerated()` is removed (or replaced with `.indices`) and the binding pattern\n        is collapsed to a single identifier.\n"
        },
        "redundantEquatable" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove a hand-written `Equatable` implementation when the compiler-synthesized\nconformance would be equivalent.\n\nFor structs conforming to `Equatable` (or `Hashable`), if the `static func ==`\ncompares exactly the same stored instance properties that the compiler would\nsynthesize, the hand-written implementation is redundant and can be removed.\n\nClosures, enums, and extension-based conformances are not handled.\n\nThis rule is opt-in due to the heuristic nature (no type-checking).\n\nLint: A redundant `==` implementation raises a warning.\n\nFormat: The `==` function is removed from the member block.\n [opt-in]"
        },
        "redundantEscaping" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove `@escaping` from closure parameters that demonstrably do not escape.\n\n`@escaping` is required only when a closure parameter outlives the function call. This\nrule uses a flow-insensitive escape check: a closure escapes if it (or a value tainted\nby it) is returned, assigned to a non-local variable, passed to another function, or\nreferenced inside a nested closure.\n\nThe analysis is deliberately conservative — when escape can't be ruled out, the rule\nstays silent. Protocol requirements, autoclosure-only edge cases, and parameters\nreferenced inside nested closures are all assumed to escape.\n\nLint: A finding is raised at the `@escaping` attribute.\n\nFormat: The `@escaping` attribute is removed.\n [opt-in]"
        },
        "redundantFinal" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove redundant `final` from members of `final` classes.\n\nWhen a class is declared `final`, all its members are implicitly final.\nAdding `final` to individual members is redundant.\n\nLint: If a `final` modifier is found on a member of a `final` class, a warning is raised.\n\nFormat: The redundant `final` modifier is removed.\n [opt-in]"
        },
        "redundantInit" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove explicit `.init` when calling a type initializer directly.\n\n`Foo.init(args)` can be written as `Foo(args)` when the type is explicit.\nThe `.init` is only necessary when the type is inferred (e.g. `.init(args)`).\n\nThis rule only fires when `init` is called on a named base expression (not on `.init()`\nshorthand, method chains, or subscripts).\n\nLint: If an explicit `.init` is found on a direct type reference, a lint warning is raised.\n\nFormat: The `.init` member access is removed, leaving the type called directly.\n"
        },
        "redundantLet" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove redundant `let`/`var` from wildcard patterns.\n\nAt statement level, `let _ = expr` can be simplified to `_ = expr` since the `let` keyword\nis unnecessary when the result is discarded.\n\nIn case patterns, `if case .foo(let _)` can be simplified to `if case .foo(_)` since the\n`let` binding of a wildcard is redundant.\n\nThe rule skips result builder contexts (SwiftUI view builders, `#Preview`, etc.) where\n`let _ = expr` is required because `_ = expr` is not valid in a result builder body.\n\nThe rule also skips declarations with attributes (`@MainActor let _ = ...`) since the\nattribute requires a declaration to attach to.\n\nLint: A finding is emitted when a redundant `let` or `var` is found.\n\nFormat: The redundant `let`/`var` keyword is removed.\n"
        },
        "redundantLetError" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove `let error` from `catch` clauses where `error` is implicitly bound.\n\nIn a `catch` clause without a pattern, the caught error is implicitly available as `error`.\nWriting `catch let error` is therefore redundant.\n\nThis rule only fires when the catch item is exactly `let error` (no type cast, no where clause,\nand no other catch items in the same clause).\n\nLint: If `catch let error` is found, a lint warning is raised.\n\nFormat: The redundant `let error` pattern is removed.\n"
        },
        "redundantNilCoalescing" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove nil-coalescing where the right-hand side is `nil`.\n\n`x ?? nil` is identical in value and type to `x` itself.\n\nLint: A finding is raised when `??` has a `nil` literal on the right-hand side.\n\nFormat: The `??` operator and the `nil` right-hand side are removed.\n"
        },
        "redundantNilInit" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove `= nil` from optional `var` declarations where `nil` is the default.\n\nOptional `var` properties and local variables default to `nil` without an explicit initializer.\nWriting `= nil` is redundant.\n\nThis rule only applies to `var` declarations with an explicit optional type annotation\n(e.g. `T?`, `Optional<T>`). It does not apply to `let` declarations, or to `var`\ndeclarations inside protocols (where there is no stored property).\n\nLint: If `= nil` is found on an eligible optional `var`, a lint warning is raised.\n\nFormat: The redundant `= nil` initializer is removed.\n"
        },
        "redundantObjc" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove `@objc` when it is already implied by another attribute.\n\nThe `@objc` attribute is automatically implied by `@IBAction`, `@IBOutlet`, `@IBDesignable`,\n`@IBInspectable`, `@NSManaged`, and `@GKInspectable`. Writing `@objc` alongside any of these\nis redundant.\n\nThis rule does NOT flag `@objc` when it specifies an explicit Objective-C name\n(e.g. `@objc(mySelector:)`), since that provides information beyond just marking the\ndeclaration as ObjC-visible.\n\nLint: If a redundant `@objc` is found, a lint warning is raised.\n\nFormat: The redundant `@objc` attribute is removed.\n"
        },
        "redundantOptionalBinding" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Use shorthand optional binding `if let x` instead of `if let x = x` (SE-0345).\n\nWhen an optional binding's initializer is a bare identifier matching the pattern name,\nthe initializer is redundant and can be removed using Swift 5.7+ shorthand syntax.\n\nThis applies to `if let`, `guard let`, and `while let` bindings.\n\nLint: If a redundant optional binding initializer is found, a lint warning is raised.\n\nFormat: The redundant initializer is removed.\n"
        },
        "redundantOverride" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove `override` declarations whose body only forwards identical arguments to `super`.\n\nAn override that does nothing other than `super.<name>(...)` with the same parameters\n(in order, with matching labels) adds no behavior.\n\nThe rule is conservative:\n- Bails out if the override has any attributes (e.g. `@available`).\n- Bails out if any parameter has a default value (the override may be tightening defaults).\n- Bails out if the call uses a trailing closure or `try!`/`try?` (assumed to change behavior).\n- Skips overrides explicitly required by tests (`tearDown`, `setUp`, etc.) and common\n  UIKit/AppKit lifecycle methods that are typically intentional anchors.\n\nLint: A finding is raised on the `override` keyword.\n\nFormat: The entire `override` declaration is removed, preserving surrounding trivia.\n [opt-in]"
        },
        "redundantPattern" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove redundant pattern matching where all associated values are discarded.\n\nWhen a case pattern matches an enum with associated values but all values are wildcards,\nthe entire argument list is redundant and can be removed.\n\nSimilarly, `let (_, _) = bar` can be simplified to `let _ = bar`.\n\nLint: If a redundant pattern is found, a finding is raised.\n\nFormat: The redundant pattern is removed.\n"
        },
        "redundantProperty" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove a property that is assigned and immediately returned on the next line.\n\nWhen a `let` binding is followed immediately by a `return` of the same identifier,\nthe binding is unnecessary. The expression can be returned directly.\n\nFor example: `let result = expr; return result` → `return expr`.\n\nThis rule only fires when the variable is a simple `let` with one binding, no type\nannotation, and the very next statement is `return <same identifier>`.\n\nLint: If a redundant property-then-return is found, a lint warning is raised.\n\nFormat: The property declaration is removed and its value is inlined into\n        the return statement.\n"
        },
        "redundantRawValues" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove raw values that match the enum case name for `String`-backed enums.\n\nWhen a `String` enum case's raw value is identical to its name (e.g. `case foo = \"foo\"`),\nthe raw value is redundant because Swift automatically assigns the case name as the raw value.\n\nLint: If a redundant raw value is found, a lint warning is raised.\n\nFormat: The redundant raw value initializer is removed.\n"
        },
        "redundantReturn" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Single-expression functions, closures, subscripts can omit `return` statement.\n\nThis includes exhaustive `if`/`switch` expressions where every branch is a single\n`return <expr>` ([SE-0380](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0380-if-switch-expressions.md),\nimplemented in Swift 5.9).\n\nLint: `func <name>() { return ... }` and similar single expression constructs will yield a lint error.\n\nFormat: `func <name>() { return ... }` constructs will be replaced with\n        equivalent `func <name>() { ... }` constructs.\n [opt-in]"
        },
        "redundantSelf" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove explicit `self.` where the compiler allows implicit self.\n\nIn most contexts inside type bodies, `self.` is redundant when accessing members\nbecause Swift resolves bare identifiers to instance members. This rule removes\nthe `self.` prefix when:\n- The access is inside a type member (method, computed property, init, subscript)\n- The member name is not shadowed by a local variable, parameter, or nested function\n- The scope allows implicit self (not a closure in a reference type without capture)\n\nFor closures, implicit self is allowed per SE-0269 (Swift 5.3+) when:\n- The enclosing type is a value type (struct/enum)\n- The closure explicitly captures self: `[self]`, `[unowned self]`\n\nThe `[weak self]` + `guard let self` pattern (SE-0365, Swift 5.8+) is handled\nconservatively: `self.` is kept in weak-self closures.\n\nLint: A lint warning is raised for redundant `self.` usage.\n\nFormat: The `self.` prefix is removed.\n"
        },
        "redundantSendable" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove explicit `Sendable` conformance from non-public structs and enums.\n\nIn Swift 6, the compiler automatically infers `Sendable` for structs and enums whose\nstored properties/associated values are all `Sendable`, as long as the type is not `public`.\nExplicitly declaring `: Sendable` on these types is redundant.\n\nThis rule only flags non-public structs and enums. Classes, actors, and public types\nare not checked because their `Sendable` conformance is either not inferred or must\nbe explicit for ABI stability.\n\nLint: If a redundant `Sendable` conformance is found, a lint warning is raised.\n\nFormat: The redundant `Sendable` conformance is removed from the inheritance clause.\n [opt-in]"
        },
        "redundantSetterACL" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove setter access modifiers (`(set)`) that match the property's effective access level.\n\n`private(set) private var x` is redundant — the property is already entirely `private`,\nso restricting the setter to `private` adds nothing. Likewise `internal(set) var x` inside\nan `internal` (or default-internal) type, or `fileprivate(set) fileprivate var x`.\n\nThe rule fires when:\n1. Another modifier on the same declaration already supplies the matching access level, OR\n2. The `(set)` keyword is `internal` or `fileprivate` and it matches the effective access of\n   the enclosing type (or the file scope, in the `internal` case).\n\nLint: A finding is raised at the redundant `(set)` modifier.\n\nFormat: The redundant `(set)` modifier is removed, transferring its leading trivia to the\n        next modifier or the binding specifier.\n [opt-in]"
        },
        "redundantStaticSelf" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove `Self.` prefix in static context where the type is already inferred.\n\nInside a static method or static computed property, `Self.` is redundant when accessing\nother static members of the same type. For example, inside `static func make()`,\nwriting `Self.defaultValue` can be simplified to just `defaultValue`.\n\nThe rule preserves `Self` when:\n- Used as an initializer: `Self()`, `Self.init()`\n- Inside an instance method, getter, or initializer\n- A parameter or local shadows the static member name\n\nLint: If a redundant `Self.` is found in a static context, a finding is raised.\n\nFormat: The `Self.` prefix is removed.\n [opt-in]"
        },
        "redundantSwiftTestingSuite" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove `@Suite` attributes that have no arguments, since they are inferred by the Swift Testing\nframework.\n\n`@Suite` with no arguments (or empty parentheses) is redundant — Swift Testing automatically\ndiscovers test suites without explicit annotation. Only `@Suite` with arguments like\n`@Suite(.serialized)` or `@Suite(\"Display Name\")` should be kept.\n\nLint: A warning is raised when `@Suite` or `@Suite()` is used without arguments.\n\nFormat: The redundant `@Suite` attribute is removed.\n [opt-in]"
        },
        "redundantThrows" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove `throws` from functions that contain no `throw` or `try` expressions.\n\nIf a function is marked `throws` but its body never uses `throw` or `try`, the `throws`\nis likely unnecessary.\n\nThis rule is opt-in because some functions are intentionally throwing for protocol\nconformance or future-proofing even if they don't currently throw.\n\nLint: If a `throws` function has no `throw` or `try` in its body, a lint warning is raised.\n\nFormat: The `throws` clause is removed.\n [opt-in]"
        },
        "redundantType" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove redundant type annotations when the type is obvious from the initializer.\n\nA type annotation is redundant when it exactly matches what the compiler would infer,\nsuch as `let x: Foo = Foo(...)` or `let x: Bool = true`.\n\nThis rule fires for:\n- Constructor calls matching the annotation: `let x: Foo = Foo(...)` → `let x = Foo(...)`\n- Generic constructors: `let x: Foo<Int> = Foo<Int>(...)` → `let x = Foo<Int>(...)`\n- Array/Dictionary constructors: `var x: [String] = [String]()` → `var x = [String]()`\n- Boolean literals: `let x: Bool = true` → `let x = true`\n- String literals: `let x: String = \"hello\"` → `let x = \"hello\"`\n- if/switch expressions where all branches match: `let x: Foo = if c { Foo() } else { Foo() }`\n\nIt does NOT fire for:\n- Numeric literals (which could be Int, Double, Float, etc.)\n- Collection literals (which could be Array, Set, etc.)\n- `Void` types (removing the annotation is unhelpful)\n\nLint: If a redundant type annotation is found, a lint warning is raised.\n\nFormat: The redundant type annotation is removed.\n"
        },
        "redundantTypedThrows" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Simplify redundant typed throws annotations.\n\n`throws(any Error)` is equivalent to plain `throws` and should be simplified.\n`throws(Never)` means the function cannot throw and the throws clause should be removed.\n\nLint: If a redundant typed throws is found, a lint warning is raised.\n\nFormat: `throws(any Error)` is replaced with `throws`. `throws(Never)` is removed.\n"
        },
        "redundantViewBuilder" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove `@ViewBuilder` when the body is a single expression.\n\n`@ViewBuilder` is unnecessary on computed properties and functions that return a single\nview expression, since Swift can infer the return type without the result builder.\n\nThis rule flags `@ViewBuilder` on:\n- Computed properties with a single-expression getter\n- Functions with a single-expression body\n\nIt does NOT flag `@ViewBuilder` on:\n- Closures (parameters)\n- Bodies with multiple statements, `if/else`, `switch`, or `ForEach`\n- Protocol requirements\n\nLint: If a redundant `@ViewBuilder` is found, a lint warning is raised.\n\nFormat: The redundant `@ViewBuilder` attribute is removed.\n [opt-in]"
        },
        "semicolons" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Semicolons should not be present in Swift code.\n\nLint: If a semicolon appears anywhere, a lint error is raised.\n\nFormat: All semicolons will be replaced with line breaks.\n"
        },
        "unusedControlFlowLabel" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "A label on a loop or switch (`outer: while …`, `label: switch …`) is only\nuseful if it's referenced by an inner `break label`/`continue label`.\nAn unreferenced label is dead syntax — usually a leftover from refactoring.\n\nLint: When a `LabeledStmt` carries a label that no nested `break` or\n`continue` uses, a warning is raised on the label.\n",
          "unevaluatedProperties" : false
        },
        "useImplicitInit" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer implicit member syntax when the type is known from context.\n\nWhen a return type, type annotation, or parameter type makes the expected type clear,\nexplicit type references in constructor calls and static member accesses are redundant.\n\n```swift\n// Before\nstatic var defaultValue: Bar { Bar(x: 1) }\nfunc make() -> Config { Config(debug: true) }\nfunc run(mode: Mode = Mode.fast) {}\n\n// After\nstatic var defaultValue: Bar { .init(x: 1) }\nfunc make() -> Config { .init(debug: true) }\nfunc run(mode: Mode = .fast) {}\n```\n\nLint: A lint warning is raised when an explicit type can be replaced with implicit member syntax.\n\nFormat: The explicit type is replaced with a leading dot.\n"
        }
      },
      "type" : "object"
    },
    "redundantAccessControl" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Unified rule that removes or replaces redundant access control modifiers.\n\nCombines four checks:\n\n1. **Redundant `internal`** — removes explicit `internal` since it is the default.\n   Does NOT remove `internal(set)`, which is meaningful on properties with a higher\n   getter access level (e.g. `public internal(set) var`).\n\n2. **Redundant `public`** — removes `public` on members inside non-public types\n   where it has no effect. Does NOT flag members of `public` or `package` types.\n\n3. **Redundant extension ACL** — removes access control on extension members that\n   match the extension's own access level.\n\n4. **Redundant `fileprivate`** — converts `fileprivate` to `private` where equivalent.\n   Only applies when the file contains a single logical type with no nested type\n   declarations.\n\nLint: Raises warnings for any of the above redundancies.\n\nFormat: Removes or replaces the redundant modifier.\n [opt-in]"
    },
    "redundantAsync" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `async` from functions that contain no `await` expressions.\n\nIf a function is marked `async` but its body never uses `await`, the `async` is likely\nunnecessary. Removing it simplifies the API and removes the requirement for callers\nto use `await`.\n\nThis rule is opt-in because some functions are intentionally async for protocol\nconformance or future-proofing even if they don't currently await.\n\nLint: If an `async` function has no `await` in its body, a lint warning is raised.\n\nFormat: The `async` specifier is removed.\n [opt-in]"
    },
    "redundantBackticks" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove unnecessary backticks around identifiers.\n\nBackticks are required when an identifier is a Swift reserved keyword used in a position\nthat expects an identifier. They are redundant when the identifier is:\n- Not a keyword at all (e.g., `` `myFunc` `` → `myFunc`)\n- A keyword used after `.` in member access (e.g., `Foo.`default`` → `Foo.default`)\n- A keyword used as a function argument label (e.g., `func foo(`default`: Int)` → `func foo(default: Int)`)\n\nLint: If unnecessary backticks are found, a finding is raised.\n\nFormat: The backticks are removed.\n"
    },
    "redundantBreak" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `break` at the end of switch cases.\n\nIn Swift, switch cases do not fall through by default. A trailing `break` at the end of a\ncase body is therefore redundant.\n\nThis rule does NOT remove labeled `break` statements (e.g. `break outerLoop`), which transfer\ncontrol to a specific enclosing statement. It also does not remove `break` when it is the\nsole statement in a case body (since at least one statement is required).\n\nLint: If a redundant `break` is found at the end of a switch case, a lint warning is raised.\n\nFormat: The redundant `break` statement is removed.\n"
    },
    "redundantClosure" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove immediately-invoked closures containing a single expression.\n\nA closure that is immediately called and contains only a single expression or return\nstatement can be replaced with just the expression.\n\nFor example: `let x = { return 42 }()` → `let x = 42`\nAnd: `let x = { someValue }()` → `let x = someValue`\n\nClosures with parameters (`in` keyword), multiple statements, empty bodies,\n`fatalError`/`preconditionFailure` calls, or `throw` are preserved.\n\nLint: If a redundant immediately-invoked closure is found, a lint warning\n      is raised.\n\nFormat: The closure wrapper and invocation are removed, leaving just the\n        expression.\n"
    },
    "redundantEnumerated" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Drop `.enumerated()` from `for` loops where one half of the tuple pattern is unused.\n\n- `for (_, x) in seq.enumerated()` → `for x in seq`\n- `for (i, _) in seq.enumerated()` → `for i in seq.indices`\n\nThe rule only rewrites when the call is exactly `seq.enumerated()` with no further chaining,\nno arguments, and no trailing closure. Closure-based usages (`seq.enumerated().map { ... }`)\nare not handled because $0/$1 reference analysis is intricate; lint a separate rule when\nthat case becomes important.\n\nLint: A finding is raised at `enumerated`.\n\nFormat: `.enumerated()` is removed (or replaced with `.indices`) and the binding pattern\n        is collapsed to a single identifier.\n"
    },
    "redundantEquatable" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove a hand-written `Equatable` implementation when the compiler-synthesized\nconformance would be equivalent.\n\nFor structs conforming to `Equatable` (or `Hashable`), if the `static func ==`\ncompares exactly the same stored instance properties that the compiler would\nsynthesize, the hand-written implementation is redundant and can be removed.\n\nClosures, enums, and extension-based conformances are not handled.\n\nThis rule is opt-in due to the heuristic nature (no type-checking).\n\nLint: A redundant `==` implementation raises a warning.\n\nFormat: The `==` function is removed from the member block.\n [opt-in]"
    },
    "redundantEscaping" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `@escaping` from closure parameters that demonstrably do not escape.\n\n`@escaping` is required only when a closure parameter outlives the function call. This\nrule uses a flow-insensitive escape check: a closure escapes if it (or a value tainted\nby it) is returned, assigned to a non-local variable, passed to another function, or\nreferenced inside a nested closure.\n\nThe analysis is deliberately conservative — when escape can't be ruled out, the rule\nstays silent. Protocol requirements, autoclosure-only edge cases, and parameters\nreferenced inside nested closures are all assumed to escape.\n\nLint: A finding is raised at the `@escaping` attribute.\n\nFormat: The `@escaping` attribute is removed.\n [opt-in]"
    },
    "redundantFinal" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove redundant `final` from members of `final` classes.\n\nWhen a class is declared `final`, all its members are implicitly final.\nAdding `final` to individual members is redundant.\n\nLint: If a `final` modifier is found on a member of a `final` class, a warning is raised.\n\nFormat: The redundant `final` modifier is removed.\n [opt-in]"
    },
    "redundantInit" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove explicit `.init` when calling a type initializer directly.\n\n`Foo.init(args)` can be written as `Foo(args)` when the type is explicit.\nThe `.init` is only necessary when the type is inferred (e.g. `.init(args)`).\n\nThis rule only fires when `init` is called on a named base expression (not on `.init()`\nshorthand, method chains, or subscripts).\n\nLint: If an explicit `.init` is found on a direct type reference, a lint warning is raised.\n\nFormat: The `.init` member access is removed, leaving the type called directly.\n"
    },
    "redundantLet" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove redundant `let`/`var` from wildcard patterns.\n\nAt statement level, `let _ = expr` can be simplified to `_ = expr` since the `let` keyword\nis unnecessary when the result is discarded.\n\nIn case patterns, `if case .foo(let _)` can be simplified to `if case .foo(_)` since the\n`let` binding of a wildcard is redundant.\n\nThe rule skips result builder contexts (SwiftUI view builders, `#Preview`, etc.) where\n`let _ = expr` is required because `_ = expr` is not valid in a result builder body.\n\nThe rule also skips declarations with attributes (`@MainActor let _ = ...`) since the\nattribute requires a declaration to attach to.\n\nLint: A finding is emitted when a redundant `let` or `var` is found.\n\nFormat: The redundant `let`/`var` keyword is removed.\n"
    },
    "redundantLetError" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `let error` from `catch` clauses where `error` is implicitly bound.\n\nIn a `catch` clause without a pattern, the caught error is implicitly available as `error`.\nWriting `catch let error` is therefore redundant.\n\nThis rule only fires when the catch item is exactly `let error` (no type cast, no where clause,\nand no other catch items in the same clause).\n\nLint: If `catch let error` is found, a lint warning is raised.\n\nFormat: The redundant `let error` pattern is removed.\n"
    },
    "redundantNilCoalescing" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove nil-coalescing where the right-hand side is `nil`.\n\n`x ?? nil` is identical in value and type to `x` itself.\n\nLint: A finding is raised when `??` has a `nil` literal on the right-hand side.\n\nFormat: The `??` operator and the `nil` right-hand side are removed.\n"
    },
    "redundantNilInit" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `= nil` from optional `var` declarations where `nil` is the default.\n\nOptional `var` properties and local variables default to `nil` without an explicit initializer.\nWriting `= nil` is redundant.\n\nThis rule only applies to `var` declarations with an explicit optional type annotation\n(e.g. `T?`, `Optional<T>`). It does not apply to `let` declarations, or to `var`\ndeclarations inside protocols (where there is no stored property).\n\nLint: If `= nil` is found on an eligible optional `var`, a lint warning is raised.\n\nFormat: The redundant `= nil` initializer is removed.\n"
    },
    "redundantObjc" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `@objc` when it is already implied by another attribute.\n\nThe `@objc` attribute is automatically implied by `@IBAction`, `@IBOutlet`, `@IBDesignable`,\n`@IBInspectable`, `@NSManaged`, and `@GKInspectable`. Writing `@objc` alongside any of these\nis redundant.\n\nThis rule does NOT flag `@objc` when it specifies an explicit Objective-C name\n(e.g. `@objc(mySelector:)`), since that provides information beyond just marking the\ndeclaration as ObjC-visible.\n\nLint: If a redundant `@objc` is found, a lint warning is raised.\n\nFormat: The redundant `@objc` attribute is removed.\n"
    },
    "redundantOptionalBinding" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Use shorthand optional binding `if let x` instead of `if let x = x` (SE-0345).\n\nWhen an optional binding's initializer is a bare identifier matching the pattern name,\nthe initializer is redundant and can be removed using Swift 5.7+ shorthand syntax.\n\nThis applies to `if let`, `guard let`, and `while let` bindings.\n\nLint: If a redundant optional binding initializer is found, a lint warning is raised.\n\nFormat: The redundant initializer is removed.\n"
    },
    "redundantOverride" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `override` declarations whose body only forwards identical arguments to `super`.\n\nAn override that does nothing other than `super.<name>(...)` with the same parameters\n(in order, with matching labels) adds no behavior.\n\nThe rule is conservative:\n- Bails out if the override has any attributes (e.g. `@available`).\n- Bails out if any parameter has a default value (the override may be tightening defaults).\n- Bails out if the call uses a trailing closure or `try!`/`try?` (assumed to change behavior).\n- Skips overrides explicitly required by tests (`tearDown`, `setUp`, etc.) and common\n  UIKit/AppKit lifecycle methods that are typically intentional anchors.\n\nLint: A finding is raised on the `override` keyword.\n\nFormat: The entire `override` declaration is removed, preserving surrounding trivia.\n [opt-in]"
    },
    "redundantPattern" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove redundant pattern matching where all associated values are discarded.\n\nWhen a case pattern matches an enum with associated values but all values are wildcards,\nthe entire argument list is redundant and can be removed.\n\nSimilarly, `let (_, _) = bar` can be simplified to `let _ = bar`.\n\nLint: If a redundant pattern is found, a finding is raised.\n\nFormat: The redundant pattern is removed.\n"
    },
    "redundantProperty" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove a property that is assigned and immediately returned on the next line.\n\nWhen a `let` binding is followed immediately by a `return` of the same identifier,\nthe binding is unnecessary. The expression can be returned directly.\n\nFor example: `let result = expr; return result` → `return expr`.\n\nThis rule only fires when the variable is a simple `let` with one binding, no type\nannotation, and the very next statement is `return <same identifier>`.\n\nLint: If a redundant property-then-return is found, a lint warning is raised.\n\nFormat: The property declaration is removed and its value is inlined into\n        the return statement.\n"
    },
    "redundantRawValues" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove raw values that match the enum case name for `String`-backed enums.\n\nWhen a `String` enum case's raw value is identical to its name (e.g. `case foo = \"foo\"`),\nthe raw value is redundant because Swift automatically assigns the case name as the raw value.\n\nLint: If a redundant raw value is found, a lint warning is raised.\n\nFormat: The redundant raw value initializer is removed.\n"
    },
    "redundantReturn" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Single-expression functions, closures, subscripts can omit `return` statement.\n\nThis includes exhaustive `if`/`switch` expressions where every branch is a single\n`return <expr>` ([SE-0380](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0380-if-switch-expressions.md),\nimplemented in Swift 5.9).\n\nLint: `func <name>() { return ... }` and similar single expression constructs will yield a lint error.\n\nFormat: `func <name>() { return ... }` constructs will be replaced with\n        equivalent `func <name>() { ... }` constructs.\n [opt-in]"
    },
    "redundantSelf" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove explicit `self.` where the compiler allows implicit self.\n\nIn most contexts inside type bodies, `self.` is redundant when accessing members\nbecause Swift resolves bare identifiers to instance members. This rule removes\nthe `self.` prefix when:\n- The access is inside a type member (method, computed property, init, subscript)\n- The member name is not shadowed by a local variable, parameter, or nested function\n- The scope allows implicit self (not a closure in a reference type without capture)\n\nFor closures, implicit self is allowed per SE-0269 (Swift 5.3+) when:\n- The enclosing type is a value type (struct/enum)\n- The closure explicitly captures self: `[self]`, `[unowned self]`\n\nThe `[weak self]` + `guard let self` pattern (SE-0365, Swift 5.8+) is handled\nconservatively: `self.` is kept in weak-self closures.\n\nLint: A lint warning is raised for redundant `self.` usage.\n\nFormat: The `self.` prefix is removed.\n"
    },
    "redundantSendable" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove explicit `Sendable` conformance from non-public structs and enums.\n\nIn Swift 6, the compiler automatically infers `Sendable` for structs and enums whose\nstored properties/associated values are all `Sendable`, as long as the type is not `public`.\nExplicitly declaring `: Sendable` on these types is redundant.\n\nThis rule only flags non-public structs and enums. Classes, actors, and public types\nare not checked because their `Sendable` conformance is either not inferred or must\nbe explicit for ABI stability.\n\nLint: If a redundant `Sendable` conformance is found, a lint warning is raised.\n\nFormat: The redundant `Sendable` conformance is removed from the inheritance clause.\n [opt-in]"
    },
    "redundantSetterACL" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove setter access modifiers (`(set)`) that match the property's effective access level.\n\n`private(set) private var x` is redundant — the property is already entirely `private`,\nso restricting the setter to `private` adds nothing. Likewise `internal(set) var x` inside\nan `internal` (or default-internal) type, or `fileprivate(set) fileprivate var x`.\n\nThe rule fires when:\n1. Another modifier on the same declaration already supplies the matching access level, OR\n2. The `(set)` keyword is `internal` or `fileprivate` and it matches the effective access of\n   the enclosing type (or the file scope, in the `internal` case).\n\nLint: A finding is raised at the redundant `(set)` modifier.\n\nFormat: The redundant `(set)` modifier is removed, transferring its leading trivia to the\n        next modifier or the binding specifier.\n [opt-in]"
    },
    "redundantStaticSelf" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `Self.` prefix in static context where the type is already inferred.\n\nInside a static method or static computed property, `Self.` is redundant when accessing\nother static members of the same type. For example, inside `static func make()`,\nwriting `Self.defaultValue` can be simplified to just `defaultValue`.\n\nThe rule preserves `Self` when:\n- Used as an initializer: `Self()`, `Self.init()`\n- Inside an instance method, getter, or initializer\n- A parameter or local shadows the static member name\n\nLint: If a redundant `Self.` is found in a static context, a finding is raised.\n\nFormat: The `Self.` prefix is removed.\n [opt-in]"
    },
    "redundantSwiftTestingSuite" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `@Suite` attributes that have no arguments, since they are inferred by the Swift Testing\nframework.\n\n`@Suite` with no arguments (or empty parentheses) is redundant — Swift Testing automatically\ndiscovers test suites without explicit annotation. Only `@Suite` with arguments like\n`@Suite(.serialized)` or `@Suite(\"Display Name\")` should be kept.\n\nLint: A warning is raised when `@Suite` or `@Suite()` is used without arguments.\n\nFormat: The redundant `@Suite` attribute is removed.\n [opt-in]"
    },
    "redundantThrows" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `throws` from functions that contain no `throw` or `try` expressions.\n\nIf a function is marked `throws` but its body never uses `throw` or `try`, the `throws`\nis likely unnecessary.\n\nThis rule is opt-in because some functions are intentionally throwing for protocol\nconformance or future-proofing even if they don't currently throw.\n\nLint: If a `throws` function has no `throw` or `try` in its body, a lint warning is raised.\n\nFormat: The `throws` clause is removed.\n [opt-in]"
    },
    "redundantType" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove redundant type annotations when the type is obvious from the initializer.\n\nA type annotation is redundant when it exactly matches what the compiler would infer,\nsuch as `let x: Foo = Foo(...)` or `let x: Bool = true`.\n\nThis rule fires for:\n- Constructor calls matching the annotation: `let x: Foo = Foo(...)` → `let x = Foo(...)`\n- Generic constructors: `let x: Foo<Int> = Foo<Int>(...)` → `let x = Foo<Int>(...)`\n- Array/Dictionary constructors: `var x: [String] = [String]()` → `var x = [String]()`\n- Boolean literals: `let x: Bool = true` → `let x = true`\n- String literals: `let x: String = \"hello\"` → `let x = \"hello\"`\n- if/switch expressions where all branches match: `let x: Foo = if c { Foo() } else { Foo() }`\n\nIt does NOT fire for:\n- Numeric literals (which could be Int, Double, Float, etc.)\n- Collection literals (which could be Array, Set, etc.)\n- `Void` types (removing the annotation is unhelpful)\n\nLint: If a redundant type annotation is found, a lint warning is raised.\n\nFormat: The redundant type annotation is removed.\n"
    },
    "redundantTypedThrows" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Simplify redundant typed throws annotations.\n\n`throws(any Error)` is equivalent to plain `throws` and should be simplified.\n`throws(Never)` means the function cannot throw and the throws clause should be removed.\n\nLint: If a redundant typed throws is found, a lint warning is raised.\n\nFormat: `throws(any Error)` is replaced with `throws`. `throws(Never)` is removed.\n"
    },
    "redundantViewBuilder" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `@ViewBuilder` when the body is a single expression.\n\n`@ViewBuilder` is unnecessary on computed properties and functions that return a single\nview expression, since Swift can infer the return type without the result builder.\n\nThis rule flags `@ViewBuilder` on:\n- Computed properties with a single-expression getter\n- Functions with a single-expression body\n\nIt does NOT flag `@ViewBuilder` on:\n- Closures (parameters)\n- Bodies with multiple statements, `if/else`, `switch`, or `ForEach`\n- Protocol requirements\n\nLint: If a redundant `@ViewBuilder` is found, a lint warning is raised.\n\nFormat: The redundant `@ViewBuilder` attribute is removed.\n [opt-in]"
    },
    "replaceForEachWithForLoop" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Replace `forEach` with `for-in` loop unless its argument is a function reference.\n\nLint:  invalid use of `forEach` yield will yield a lint error.\n",
      "unevaluatedProperties" : false
    },
    "requireFatalErrorMessage" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "`fatalError` calls should include a descriptive message.\n\nA bare `fatalError()` (or `fatalError(\"\")`) gives no context when the program crashes. Including\na message makes it far easier to diagnose the problem from the stack trace alone.\n\nLint: A warning is raised for `fatalError()` and `fatalError(\"\")`.\n\nFormat: Not auto-fixed; the message must be supplied by the author.\n [opt-in]"
    },
    "requireSummary" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "All documentation comments must begin with a one-line summary of the declaration.\n\nLint: If a comment does not begin with a single-line summary, a lint error is raised.\n [opt-in]",
      "unevaluatedProperties" : false
    },
    "requireSuperCall" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Some `override`d methods on Apple frameworks rely on the parent class\nrunning its own implementation. Forgetting to call `super` is a common\nsource of subtle bugs (memory warnings ignored, view lifecycle skipped,\ntest setup not run).\n\nThe rule is opt-in. Configure the list of method names via\n`requireSuperCall.methodNames`. Defaults cover common UIKit/AppKit/XCTest\nmethods. Names use SwiftLint's resolved-name format: `viewDidLoad()`,\n`viewWillAppear(_:)`, `setEditing(_:animated:)`.\n\nLint: When an `override` of a configured method either omits the\n`super.<name>(...)` call or calls it more than once, a warning is raised.\n",
      "properties" : {
        "defaultMethodNames" : {
          "description" : "defaultMethodNames",
          "items" : {
            "type" : "string"
          },
          "type" : "array"
        },
        "methodNames" : {
          "description" : "methodNames",
          "items" : {
            "type" : "string"
          },
          "type" : "array"
        }
      },
      "unevaluatedProperties" : false
    },
    "retainNotificationObserver" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "`NotificationCenter.addObserver(forName:object:queue:using:)` returns an\nopaque token that must be retained to later remove the observer.\nDiscarding the return value leaks the observer.\n\nLint: When a call to `addObserver(forName:object:queue:...)` is used as a\nstatement (not stored, returned, or passed to another call), a warning is\nraised.\n [opt-in]",
      "unevaluatedProperties" : false
    },
    "semicolons" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Semicolons should not be present in Swift code.\n\nLint: If a semicolon appears anywhere, a lint error is raised.\n\nFormat: All semicolons will be replaced with line breaks.\n"
    },
    "simplifyGenericConstraints" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Use inline generic constraints (`<T: Foo>`) instead of where clauses\n(`<T> where T: Foo`) for simple protocol conformance constraints.\n\nWhen a generic parameter has a simple conformance constraint in the `where` clause,\nit can be moved inline into the generic parameter list for conciseness.\n\nSame-type constraints (`T == Foo`), associated type constraints (`T.Element: Foo`),\nand parameters that already have an inline constraint are not modified.\n\nLint: A `where` clause with a simple conformance constraint that could be inlined raises a warning.\n\nFormat: The conformance constraint is moved from the `where` clause to the generic parameter.\n"
    },
    "singleLineBodies" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Controls whether single-statement bodies are kept inline or wrapped to\nmultiple lines.\n\n**Wrap mode** (default): Single-line bodies in conditionals, functions,\nloops, and properties are expanded onto multiple lines.\n\n**Inline mode**: Multi-line single-statement bodies are collapsed onto the\nsame line as the declaration, provided the result fits within the configured\nline length.\n\nLint: A body whose formatting doesn't match the mode raises a warning.\n\nFormat: The body is wrapped or inlined to match the mode.\n [opt-in]",
      "properties" : {
        "mode" : {
          "default" : "wrap",
          "description" : "mode Options: wrap, inline.",
          "enum" : [
            "wrap",
            "inline"
          ],
          "type" : "string"
        }
      }
    },
    "singleLineComments" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Single-line comments that exceed the configured line length are wrapped.\n\nLint: A `//` or `///` comment that exceeds the line length raises a\n      warning.\n\nFormat: The comment is word-wrapped, continuing on the next line with the\n        same prefix and indentation.\n [opt-in]"
    },
    "sort" : {
      "additionalProperties" : false,
      "description" : "sort rule group.",
      "properties" : {
        "declarations" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Sort declarations between `// swiftiomatic:sort:begin` and `// swiftiomatic:sort:end` markers.\n\nDeclarations within the marked region are sorted alphabetically by name. Comments and trivia\nassociated with each declaration move with it. The markers themselves are preserved in place.\n\nLint: If declarations in a marked region are not sorted, a lint warning is raised.\n\nFormat: The declarations are reordered alphabetically by name.\n"
        },
        "imports" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Imports must be lexicographically ordered and (optionally) logically grouped at the top of each source file.\nThe order of the import groups is 1) regular imports, 2) declaration imports, 3) @\\_implementationOnly\nimports, and 4) @testable imports. These groups are separated by a single blank line. Blank lines in\nbetween the import declarations are removed.\n\nLogical grouping is enabled by default but can be disabled via the `sortImports.shouldGroupImports`\nconfiguration option to limit this rule to lexicographic ordering.\n\nBy default, imports within conditional compilation blocks (`#if`, `#elseif`, `#else`) are not ordered.\nThis behavior can be controlled via the `sortImports.includeConditionalImports` configuration option.\n\nLint: If an import appears anywhere other than the beginning of the file it resides in,\n      not lexicographically ordered, or (optionally) not in the appropriate import group, a lint error is\n      raised.\n\nFormat: Imports will be reordered and (optionally) grouped at the top of the file.\n",
          "properties" : {
            "sortOrder" : {
              "default" : "alphabetical",
              "description" : "sortOrder Options: alphabetical, length.",
              "enum" : [
                "alphabetical",
                "length"
              ],
              "type" : "string"
            }
          }
        },
        "switchCases" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Sort switch case items alphabetically within each case.\n\nWhen a case matches multiple patterns (e.g. `case .b, .a, .c:`), the patterns are sorted\nlexicographically. Numeric literals are compared by value (including hex, octal, and binary).\nCases with `where` clauses are only sorted if the `where` clause ends up on the last item.\n\nLint: If case items are not sorted, a lint warning is raised.\n\nFormat: The case items are reordered alphabetically.\n [opt-in]"
        },
        "typeAliases" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Sort protocol composition typealiases alphabetically.\n\nWhen a typealias combines multiple protocols with `&` (e.g. `typealias Deps = Foo & Bar & Baz`),\nthe types are sorted lexicographically. Duplicate types are removed. The `any` keyword, if\npresent, is preserved at the beginning.\n\nLint: If the composition types are not sorted, a lint warning is raised.\n\nFormat: The types are reordered alphabetically and duplicates are removed.\n"
        }
      },
      "type" : "object"
    },
    "spaces" : {
      "additionalProperties" : false,
      "description" : "spaces rule group.",
      "properties" : {
        "spacesAroundRangeFormationOperators" : {
          "description" : "Force spaces around ... and ..<.",
          "type" : "boolean"
        },
        "spacesBeforeEndOfLineComments" : {
          "description" : "Spaces before // comments.",
          "type" : "integer"
        }
      },
      "type" : "object"
    },
    "staticStructShouldBeEnum" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Convert types hosting only static members into enums.\n\nAn empty enum is the canonical way to create a namespace in Swift because it cannot\nbe instantiated. Structs and classes that contain only static members serve the same\npurpose but can be accidentally instantiated.\n\nThis rule skips types with inheritance clauses, attributes, generic parameters,\ninitializers, or any instance members.\n\nLint: A struct or final class containing only static members raises a warning.\n\nFormat: The `struct` or `final class` keyword is replaced with `enum`.\n"
    },
    "strongOutlets" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove `weak` from `@IBOutlet` properties.\n\nAs per Apple's recommendation, `@IBOutlet` properties should be strong. The `weak`\nmodifier is preserved for delegate and data source outlets since those are typically\nowned elsewhere.\n\nLint: An `@IBOutlet` property with `weak` raises a warning.\n\nFormat: The `weak` modifier is removed.\n"
    },
    "swiftTestingTestCaseNames" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Remove the `test` prefix from Swift Testing `@Test` function names.\n\nIn Swift Testing, test methods are identified by the `@Test` attribute, not by a naming\nconvention. The `test` prefix is redundant and should be removed for idiomatic Swift Testing.\n\nThe rename is skipped when:\n- The remainder after removing `test` would be empty, start with a digit, or be a Swift keyword\n- The new name would collide with an existing identifier in the same scope\n\nLint: A warning is raised for `@Test` functions with a `test` prefix.\n\nFormat: The `test` prefix is removed and the first letter is lowercased.\n [opt-in]"
    },
    "switchCaseBodies" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Controls whether switch case bodies are wrapped (multiline) or inlined.\n\n**Wrap mode** (default): Each case body appears on its own indented line\nbelow the case label.\n\n```swift\nswitch piece {\ncase .backslashes, .pounds:\n    piece.write(to: &result)\ndefault:\n    break\n}\n```\n\n**Adaptive mode**: Each case is independently inlined if it has a single\nstatement that fits within the configured line length; cases that don't fit\nor have multiple statements remain wrapped.\n\n```swift\nswitch piece {\ncase .backslashes, .pounds: piece.write(to: &result)\ndefault: break\n}\n```\n\nLint: A case body whose formatting doesn't match the mode raises a warning.\n\nFormat: The case body is wrapped or inlined to match the mode.\n [opt-in]",
      "properties" : {
        "mode" : {
          "default" : "wrap",
          "description" : "mode Options: wrap, adaptive.",
          "enum" : [
            "wrap",
            "adaptive"
          ],
          "type" : "string"
        }
      }
    },
    "switchCases" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Enforce switch case label indentation style.\n\nTwo styles are supported via `SwitchCaseIndentationConfiguration.Style`:\n- `flush`: `case` labels align with the `switch` keyword (default).\n- `indented`: `case` labels are indented one level from `switch`.\n\nLint: Raised when a `case` or `default` label doesn't match the configured style.\n\nFormat: Case labels, bodies, and the closing brace are reindented to match.\n [opt-in]",
      "properties" : {
        "style" : {
          "default" : "flush",
          "description" : "style Options: flush, indented.",
          "enum" : [
            "flush",
            "indented"
          ],
          "type" : "string"
        }
      }
    },
    "testSuiteAccessControl" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Test methods should be `internal`; helper properties and functions should be `private`.\n\nIn test suites, test methods don't need explicit access control (internal is the default and\ncorrect level). Non-test helpers should be `private` since they're only used within the suite.\n\nLint: A warning is raised for incorrect access control on test suite members.\n\nFormat: Access control is corrected.\n [opt-in]"
    },
    "testing" : {
      "additionalProperties" : false,
      "description" : "testing rule group.",
      "properties" : {
        "noGuardInTests" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Convert `guard` statements in test functions to `try #require(...)`/`#expect(...)` (Swift\nTesting) or `try XCTUnwrap(...)`/`XCTAssert(...)` (XCTest).\n\nGuard statements in tests obscure the test intent behind control flow. Replacing them with\ndirect assertions or unwraps makes the test linear and the failure message immediate.\n\nThis rule applies to:\n- Functions annotated with `@Test` (Swift Testing)\n- Functions named `test*()` with no parameters inside `XCTestCase` subclasses\n\nGuards inside closures or nested functions are left alone because the enclosing test function's\n`throws` does not propagate into those scopes.\n\nLint: A warning is raised for each `guard` that can be converted.\n\nFormat: The `guard` is replaced with assertion/unwrap statements and `throws` is added to\nthe signature if needed.\n [opt-in]"
        },
        "preferSwiftTesting" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Convert XCTest suites to Swift Testing.\n\nReplaces `import XCTest` with `import Testing` + `import Foundation`, removes `XCTestCase`\nconformance, converts `setUp`/`tearDown` to `init`/`deinit`, adds `@Test` to test methods,\nand converts XCT assertions to `#expect`/`#require`.\n\nBails out entirely if the file contains unsupported XCTest functionality (expectations,\nperformance tests, unknown overrides, async/throws tearDown, XCTestCase extensions).\n\nLint: A warning is raised for each XCTest pattern that can be converted.\n\nFormat: The XCTest patterns are replaced with Swift Testing equivalents.\n [opt-in]"
        },
        "swiftTestingTestCaseNames" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Remove the `test` prefix from Swift Testing `@Test` function names.\n\nIn Swift Testing, test methods are identified by the `@Test` attribute, not by a naming\nconvention. The `test` prefix is redundant and should be removed for idiomatic Swift Testing.\n\nThe rename is skipped when:\n- The remainder after removing `test` would be empty, start with a digit, or be a Swift keyword\n- The new name would collide with an existing identifier in the same scope\n\nLint: A warning is raised for `@Test` functions with a `test` prefix.\n\nFormat: The `test` prefix is removed and the first letter is lowercased.\n [opt-in]"
        },
        "testSuiteAccessControl" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Test methods should be `internal`; helper properties and functions should be `private`.\n\nIn test suites, test methods don't need explicit access control (internal is the default and\ncorrect level). Non-test helpers should be `private` since they're only used within the suite.\n\nLint: A warning is raised for incorrect access control on test suite members.\n\nFormat: Access control is corrected.\n [opt-in]"
        },
        "validateTestCases" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Ensure test methods have the correct `test` prefix or `@Test` attribute.\n\nFor XCTest: functions in `XCTestCase` subclasses that look like tests get a `test` prefix.\nFor Swift Testing: functions in test suite types get a `@Test` attribute.\n\nA \"test suite\" type is one whose name ends with `Tests`, `TestCase`, or `Suite`.\n\nFunctions are skipped if they:\n- Have parameters or a return type\n- Are `override`, `@objc`, `static`, or `private`/`fileprivate`\n- Start with a disabled prefix (`disable_`, `skip_`, `x_`, `_`, etc.)\n- Are referenced elsewhere in the file (XCTest only — they're helpers)\n- Are in a type with a parameterized initializer\n- Are in an `open` base class or one with \"Base\"/\"base\"/\"subclass\" in name/doc comment\n\nLint: A warning is raised for each test method missing the correct prefix or attribute.\n\nFormat: The `test` prefix or `@Test` attribute is added.\n [opt-in]"
        }
      },
      "type" : "object"
    },
    "tripleSlashDocC" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Documentation comments must use the `///` form.\n\nThis is similar to `NoBlockComments` but is meant to prevent documentation block comments.\n\nLint: If a doc block comment appears, a lint error is raised.\n\nFormat: If a doc block comment appears on its own on a line, or if a doc block comment spans\n        multiple lines without appearing on the same line as code, it will be replaced with\n        multiple doc line comments.\n"
    },
    "typeAliases" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Sort protocol composition typealiases alphabetically.\n\nWhen a typealias combines multiple protocols with `&` (e.g. `typealias Deps = Foo & Bar & Baz`),\nthe types are sorted lexicographically. Duplicate types are removed. The `any` keyword, if\npresent, is preserved at the beginning.\n\nLint: If the composition types are not sorted, a lint warning is raised.\n\nFormat: The types are reordered alphabetically and duplicates are removed.\n"
    },
    "types" : {
      "additionalProperties" : false,
      "description" : "types rule group.",
      "properties" : {
        "noTypeRepetitionInStaticProperties" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/lintOnlyBase"
            }
          ],
          "description" : "Static properties of a type that return that type should not include a reference to their type.\n\n\"Reference to their type\" means that the property name includes part, or all, of the type. If\nthe type contains a namespace (i.e. `UIColor`) the namespace is ignored;\n`public class var redColor: UIColor` would trigger this rule.\n\nLint: Static properties of a type that return that type will yield a lint error.\n",
          "unevaluatedProperties" : false
        },
        "noVoidReturnOnFunctionSignature" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Functions that return `()` or `Void` should omit the return signature.\n\nLint: Function declarations that explicitly return `()` or `Void` will yield a lint error.\n\nFormat: Function declarations with explicit returns of `()` or `Void` will have their return\n        signature stripped.\n"
        },
        "preferAnyObject" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Prefer `AnyObject` over `class` for class-constrained protocols.\n\nThe `class` keyword in protocol inheritance clauses was replaced by `AnyObject` in Swift 4.1.\nUsing `AnyObject` is the modern, preferred spelling.\n\nLint: A protocol inheriting from `class` instead of `AnyObject` raises a warning.\n\nFormat: `class` is replaced with `AnyObject` in the inheritance clause.\n"
        },
        "preferShorthandTypeNames" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Shorthand type forms must be used wherever possible.\n\nLint: Using a non-shorthand form (e.g. `Array<Element>`) yields a lint error unless the long\n      form is necessary (e.g. `Array<Element>.Index` cannot be shortened today.)\n\nFormat: Where possible, shorthand types replace long form types; e.g. `Array<Element>` is\n        converted to `[Element]`.\n"
        },
        "preferVoidReturn" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Return `Void`, not `()`, in signatures.\n\nNote that this rule does *not* apply to function declaration signatures in order to avoid\nconflicting with `NoVoidReturnOnFunctionSignature`.\n\nLint: Returning `()` in a signature yields a lint error.\n\nFormat: `-> ()` is replaced with `-> Void`\n"
        }
      },
      "type" : "object"
    },
    "unhandledThrowingTask" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "`Task { try ... }` silently swallows thrown errors when the error type is\ninferred (or written as `_`).\n\nWithout an explicit `Failure` generic argument, a `Task` that throws an\nunhandled error doesn't surface the error anywhere — there is no `throws`\nsignature on the closure call site, and the value/result of the task is\nusually discarded.\n\nSee: https://forums.swift.org/t/task-initializer-with-throwing-closure-swallows-error/56066\n\nLint: When a `Task { ... }` (with implicit or wildcard error type) contains\nan unhandled `throw` or `try`, an error is raised. Tasks whose value or\nresult is consumed (`let t = Task { ... }`, `Task { ... }.value`,\n`return Task { ... }`) are exempt.\n [opt-in]",
      "unevaluatedProperties" : false
    },
    "unusedArguments" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Mark unused function arguments with `_`.\n\nDetects unused parameters in functions, initializers, subscripts, closures,\nand for-loop variables, and replaces them with `_`.\n\nFor named function parameters, the internal name is replaced with `_`\n(e.g., `func foo(bar: Int)` → `func foo(bar _: Int)`). For unnamed\nparameters, the name is removed (`func foo(_ bar: Int)` → `func foo(_: Int)`).\n\nFor operator functions and subscripts, the parameter name is replaced\nwith `_` directly since external labels are unnecessary.\n\nLint: When a parameter or loop variable is unused.\n\nFormat: The unused parameter or variable is replaced with `_`.\n"
    },
    "unusedControlFlowLabel" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "A label on a loop or switch (`outer: while …`, `label: switch …`) is only\nuseful if it's referenced by an inner `break label`/`continue label`.\nAn unreferenced label is dead syntax — usually a leftover from refactoring.\n\nLint: When a `LabeledStmt` carries a label that no nested `break` or\n`continue` uses, a warning is raised on the label.\n",
      "unevaluatedProperties" : false
    },
    "unusedSetterValue" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "A computed-property or subscript setter that never reads its parameter\n(`newValue` by default, or the bound name in `set(custom)`) is almost\nalways wrong — the assignment to the underlying storage uses some other\nexpression, leaving the actual incoming value silently dropped.\n\nException: empty `override` setters, e.g. `override var x: T { get { ... }\nset {} }`, are intentional no-ops to suppress the parent class's setter.\n\nLint: When a `set` accessor's body never references its parameter name,\na warning is raised.\n",
      "unevaluatedProperties" : false
    },
    "uppercaseAcronyms" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Capitalize acronyms when the first character is capitalized.\n\nWhen an identifier contains a titlecased acronym (e.g. `Url`, `Json`, `Id`),\nit should be fully uppercased (e.g. `URL`, `JSON`, `ID`) for consistency with\nSwift naming conventions.\n\nThe list of recognized acronyms is configurable via `Configuration.acronyms`.\n\nLint: An identifier with a titlecased acronym raises a warning.\n\nFormat: The titlecased acronym is replaced with the uppercased form.\n [opt-in]",
      "properties" : {
        "words" : {
          "description" : "words",
          "items" : {
            "type" : "string"
          },
          "type" : "array"
        }
      }
    },
    "urlMacro" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Replace force-unwrapped `URL(string:)` initializers with a configured URL macro.\n\nWhen configured with a macro name like `#URL` and module like `URLFoundation`, this rule\nconverts `URL(string: \"https://example.com\")!` to `#URL(\"https://example.com\")` and adds\nthe module import if not already present.\n\nOnly simple string literals are converted — string interpolations, concatenations, and\nnon-literal expressions are left alone. The `URL(string:relativeTo:)` and\n`URL(fileURLWithPath:)` initializers are not affected.\n\nThis rule is opt-in and requires configuration via `urlMacro.macroName` and\n`urlMacro.moduleName` in the configuration file.\n\nLint: A warning is raised for each `URL(string: \"...\")!` that can be converted.\n\nFormat: The force-unwrapped URL initializer is replaced with the configured macro.\n [opt-in]",
      "properties" : {
        "macroName" : {
          "description" : "macroName",
          "type" : "string"
        },
        "moduleName" : {
          "description" : "moduleName",
          "type" : "string"
        }
      }
    },
    "useImplicitInit" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Prefer implicit member syntax when the type is known from context.\n\nWhen a return type, type annotation, or parameter type makes the expected type clear,\nexplicit type references in constructor calls and static member accesses are redundant.\n\n```swift\n// Before\nstatic var defaultValue: Bar { Bar(x: 1) }\nfunc make() -> Config { Config(debug: true) }\nfunc run(mode: Mode = Mode.fast) {}\n\n// After\nstatic var defaultValue: Bar { .init(x: 1) }\nfunc make() -> Config { .init(debug: true) }\nfunc run(mode: Mode = .fast) {}\n```\n\nLint: A lint warning is raised when an explicit type can be replaced with implicit member syntax.\n\nFormat: The explicit type is replaced with a leading dot.\n"
    },
    "useShortArrayLiteral" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Never use `[<Type>]()` syntax. In call sites that should be replaced with `[]`,\nfor initializations use explicit type combined with empty array literal `let _: [<Type>] = []`\nStatic properties of a type that return that type should not include a reference to their type.\n\nLint:  Non-literal empty array initialization will yield a lint error.\nFormat: All invalid use sites would be related with empty literal (with or without explicit type annotation).\n [opt-in]"
    },
    "validateTestCases" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Ensure test methods have the correct `test` prefix or `@Test` attribute.\n\nFor XCTest: functions in `XCTestCase` subclasses that look like tests get a `test` prefix.\nFor Swift Testing: functions in test suite types get a `@Test` attribute.\n\nA \"test suite\" type is one whose name ends with `Tests`, `TestCase`, or `Suite`.\n\nFunctions are skipped if they:\n- Have parameters or a return type\n- Are `override`, `@objc`, `static`, or `private`/`fileprivate`\n- Start with a disabled prefix (`disable_`, `skip_`, `x_`, `_`, etc.)\n- Are referenced elsewhere in the file (XCTest only — they're helpers)\n- Are in a type with a parameterized initializer\n- Are in an `open` base class or one with \"Base\"/\"base\"/\"subclass\" in name/doc comment\n\nLint: A warning is raised for each test method missing the correct prefix or attribute.\n\nFormat: The `test` prefix or `@Test` attribute is added.\n [opt-in]"
    },
    "version" : {
      "default" : 6,
      "description" : "Configuration format version.",
      "minimum" : 1,
      "type" : "integer"
    },
    "weakDelegates" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/lintOnlyBase"
        }
      ],
      "description" : "Properties whose name ends in `delegate` should be declared `weak` to avoid retain cycles.\n\nThis rule fires only on class instance properties. Local variables, struct/enum members,\ncomputed properties, protocol requirements, and properties marked with one of the SwiftUI\nadaptor attributes (`@UIApplicationDelegateAdaptor`, `@NSApplicationDelegateAdaptor`,\n`@WKExtensionDelegateAdaptor`) are excluded. Properties already marked `weak` or `unowned`\npass.\n\nLint: A class instance property named `*delegate` without a `weak`/`unowned` modifier yields\na warning.\n",
      "unevaluatedProperties" : false
    },
    "wrap" : {
      "additionalProperties" : false,
      "description" : "wrap rule group.",
      "properties" : {
        "collapseSimpleEnums" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Collapses simple enums with no associated values, no raw values, and no\nmembers other than cases onto a single line.\n\n```swift\n// Before\nprivate enum Kind {\n    case chained\n    case forced\n}\n\n// After\nprivate enum Kind { case chained, forced }\n```\n\nThe rule only applies when the collapsed form fits within the configured\nline length. Enums with associated values, explicit raw value assignments,\nraw-value types (e.g. `: Int`, `: String`), computed properties, methods,\nor any non-case member are left untouched.\n [opt-in]"
        },
        "collapseSimpleIfElse" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Collapses multi-line `if`/`else` (and `else if` chains) onto a single line\nwhen every branch contains exactly one statement and the collapsed form fits\nwithin the configured line length.\n\nComplements `PreferTernary` for cases ternary can't reach: `if let`/`if case`\nconditional bindings, `if #available`, and multi-clause conditions.\n\n```swift\n// Before\nif let defaultValue = last?.defaultValue {\n    defaultValue\n} else {\n    last?.type\n}\n\n// After\nif let defaultValue = last?.defaultValue { defaultValue } else { last?.type }\n```\n\nLint: A multi-line if/else where each branch has a single statement and the\n      collapsed form fits within line length raises a warning.\n\nFormat: The chain is collapsed onto a single line.\n [opt-in]"
        },
        "compoundCaseItems" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Comma-delimited switch case items are wrapped onto separate lines.\n\nSwitch cases with multiple patterns separated by commas are expanded so each\npattern appears on its own line, aligned after `case `.\n\nLint: A switch case with multiple comma-separated items on a single line\n      raises a warning.\n\nFormat: Each item is placed on its own line with alignment indentation.\n [opt-in]"
        },
        "conditionalAssignment" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Multiline conditional assignment expressions are wrapped after the\nassignment operator.\n\nWhen assigning an `if` or `switch` expression that spans multiple lines,\nthe `=` should be on the same line as the property, and a line break\nshould follow `=` before the `if`/`switch` keyword.\n\nLint: A multiline `if`/`switch` expression on the same line as `=` raises\n      a warning.\n\nFormat: A line break is inserted after `=`.\n [opt-in]"
        },
        "keepFunctionOutputTogether" : {
          "description" : "Keep return type with closing parenthesis.",
          "type" : "boolean"
        },
        "multilineFunctionChains" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Chained function calls are wrapped consistently: if any dot in the chain\nis on a different line, all dots are placed on separate lines.\n\nLint: A multiline chain where some dots share a line raises a warning.\n\nFormat: Dots that share a line with a closing scope or another dot are\n        moved to their own line.\n [opt-in]"
        },
        "multilineStatementBraces" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Opening braces of multiline statements are wrapped to their own line.\n\nWhen a statement signature (conditions, parameters, etc.) spans multiple\nlines, the opening `{` is moved to its own line, aligned with the\nstatement keyword.\n\nLint: A `{` on the same line as a multiline statement signature raises a\n      warning.\n\nFormat: The `{` is moved to a new line aligned with the closing `}`.\n [opt-in]"
        },
        "nestedCallLayout" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Controls the layout of nested function/initializer calls where the sole\nargument to one call is another call.\n\n**Inline mode**: Collapses deeply nested calls into the most compact form\nthat fits the line width, trying each layout in order:\n\n1. Fully inline:\n   ```swift\n   result = ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))\n   ```\n\n2. Outer inline, inner wrapped:\n   ```swift\n   result = ExprSyntax(ForceUnwrapExprSyntax(\n       expression: result,\n       trailingTrivia: trivia\n   ))\n   ```\n\n3. Fully wrapped (outer on new line, inner inline):\n   ```swift\n   result = ExprSyntax(\n       ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia)\n   )\n   ```\n\n4. Fully nested (no change).\n\n**Wrap mode**: Expands any compact form into the fully nested form with each\ncall and its arguments on separate indented lines.\n\nLint: A nested call whose layout doesn't match the mode raises a warning.\n\nFormat: The call tree is reformatted to match the mode.\n [opt-in]",
          "properties" : {
            "mode" : {
              "default" : "inline",
              "description" : "mode Options: inline, wrap.",
              "enum" : [
                "inline",
                "wrap"
              ],
              "type" : "string"
            }
          }
        },
        "singleLineBodies" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Controls whether single-statement bodies are kept inline or wrapped to\nmultiple lines.\n\n**Wrap mode** (default): Single-line bodies in conditionals, functions,\nloops, and properties are expanded onto multiple lines.\n\n**Inline mode**: Multi-line single-statement bodies are collapsed onto the\nsame line as the declaration, provided the result fits within the configured\nline length.\n\nLint: A body whose formatting doesn't match the mode raises a warning.\n\nFormat: The body is wrapped or inlined to match the mode.\n [opt-in]",
          "properties" : {
            "mode" : {
              "default" : "wrap",
              "description" : "mode Options: wrap, inline.",
              "enum" : [
                "wrap",
                "inline"
              ],
              "type" : "string"
            }
          }
        },
        "singleLineComments" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Single-line comments that exceed the configured line length are wrapped.\n\nLint: A `//` or `///` comment that exceeds the line length raises a\n      warning.\n\nFormat: The comment is word-wrapped, continuing on the next line with the\n        same prefix and indentation.\n [opt-in]"
        },
        "switchCaseBodies" : {
          "allOf" : [
            {
              "$ref" : "#/$defs/ruleBase"
            }
          ],
          "description" : "Controls whether switch case bodies are wrapped (multiline) or inlined.\n\n**Wrap mode** (default): Each case body appears on its own indented line\nbelow the case label.\n\n```swift\nswitch piece {\ncase .backslashes, .pounds:\n    piece.write(to: &result)\ndefault:\n    break\n}\n```\n\n**Adaptive mode**: Each case is independently inlined if it has a single\nstatement that fits within the configured line length; cases that don't fit\nor have multiple statements remain wrapped.\n\n```swift\nswitch piece {\ncase .backslashes, .pounds: piece.write(to: &result)\ndefault: break\n}\n```\n\nLint: A case body whose formatting doesn't match the mode raises a warning.\n\nFormat: The case body is wrapped or inlined to match the mode.\n [opt-in]",
          "properties" : {
            "mode" : {
              "default" : "wrap",
              "description" : "mode Options: wrap, adaptive.",
              "enum" : [
                "wrap",
                "adaptive"
              ],
              "type" : "string"
            }
          }
        }
      },
      "type" : "object"
    },
    "wrapTernary" : {
      "allOf" : [
        {
          "$ref" : "#/$defs/ruleBase"
        }
      ],
      "description" : "Wrap each branch of a ternary expression onto its own line when the expression\nwould exceed the configured line length.\n\nThe pretty printer no longer makes wrapping decisions for ternaries — instead, this\nrule inserts discretionary newlines into the leading trivia of `?` and `:` whenever\nthe ternary's last column would exceed `LineLength`. The pretty printer respects\nthose newlines (see `RespectsExistingLineBreaks`) and applies a continuation indent\nto each wrapped branch, producing:\n\n```swift\npendingLeadingTrivia = trailingNonSpace.isEmpty\n  ? token.leadingTrivia\n  : token.leadingTrivia + trailingNonSpace\n```\n\nIf either operator already has a leading newline, the rule normalizes the other to\nmatch so the ternary always has both branches on their own lines once it wraps.\n"
    }
  },
  "title" : "Swiftiomatic Configuration",
  "type" : "object"
}

"""##
        guard let data = json.data(using: .utf8) else {
            fatalError("Failed to encode embedded JSON Schema — regenerate with `swift run Generator`")
        }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(JSONValue.self, from: data)
        } catch {
            fatalError("Failed to decode embedded JSON Schema: \(error) — regenerate with `swift run Generator`")
        }
    }()
}
