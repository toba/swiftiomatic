extension SortedImportsRule {
  private static let groupByAttributesOptions = ["grouping": "attributes"]

  static let nonTriggeringExamples = [
    Example(
      """
      import AAA
      import BBB
      import CCC
      import DDD
      """,
    ),
    Example(
      """
      import Alamofire
      import API
      """,
    ),
    Example(
      """
      import labc
      import Ldef
      """,
    ),
    Example(
      """
      // comment
      import AAA
      import BBB
      import CCC
      """,
    ),
    Example(
      """
      @testable import AAA
      import   CCC
      """,
    ),
    Example(
      """
      import AAA
      @testable import   CCC
      """,
    ),
    Example(
      """
      import EEE.A
      import FFF.B
      #if os(Linux)
      import DDD.A
      import EEE.B
      #else
      import CCC
      import DDD.B
      #endif
      import AAA
      import BBB
      """,
    ),
    Example(
      """
      // header

      import DDD
      import SSS

      // some comment
      import FFF // a comment
      """, isExcludedFromDocumentation: true,
    ),
    Example(
      """
      // header

      import DDD
      import FFF

      // some comment
      import AAA // a comment
      import NNN
      """, isExcludedFromDocumentation: true,
    ),
    Example(
      """
      @testable import AAA
        @testable import BBB
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
      @testable import BBB
        import AAA
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
      @_exported import BBB
        @testable import AAA
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
      @_exported @testable import BBB
        import AAA
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
      @_exported @testable import BBB
        public import BBB
        import AAA
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
      public import FFF
      package import EEE
      internal import DDD
      fileprivate import CCC
      private import BBB
      import AAA
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
      @_exported @testable public import BBB
      @_exported @testable private import BBB
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
      @_exported public import BBB
      @_exported @testable import BBB
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
  ].skipMultiByteOffsetTests()

  static let triggeringExamples = [
    Example(
      """
      import AAA
      import ZZZ
      import ↓BBB
      import CCC
      """,
    ),
    Example(
      """
      import DDD
      // comment
      import ↓CCC
      import ↓AAA
      """,
    ),
    Example(
      """
      @testable import CCC
      import   ↓AAA
      """,
    ),
    Example(
      """
      import CCC
      @testable import   ↓AAA
      """,
    ),
    Example(
      """
      import FFF.B
      import ↓EEE.A
      #if os(Linux)
      import DDD.A
      import EEE.B
      #else
      import DDD.B
      import ↓CCC
      #endif
      import AAA
      import BBB
      """,
    ),
    Example(
      """
        @testable import BBB
      @testable import ↓AAA
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
        import AAA
      @testable import ↓BBB
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
        import BBB
      @testable import ↓AAA
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
        @testable import AAA
      @_exported import ↓BBB
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
        import AAA
      @_exported @testable import ↓BBB
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
        import AAA
        public import ↓BBB
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
    Example(
      """
        import AAA
        private import ↓BBB
        fileprivate import ↓CCC
        internal import ↓DDD
        package import ↓EEE
        public import ↓FFF
      """, configuration: groupByAttributesOptions, isExcludedFromDocumentation: true,
    ),
  ]

  static let corrections = [
    Example(
      """
      import AAA
      import ZZZ
      import BBB
      import CCC
      """, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      import AAA
      import BBB
      import CCC
      import ZZZ
      """,
    ),
    Example(
      """
      import BBB // comment
      import AAA
      """, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      import AAA
      import BBB // comment
      """,
    ),
    Example(
      """
      import BBB
      // comment
      import CCC
      import AAA
      """, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      import AAA
      import BBB
      // comment
      import CCC
      """,
    ),
    Example(
      """
      @testable import CCC
      import  AAA
      """, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      import  AAA
      @testable import CCC
      """,
    ),
    Example(
      """
      import CCC
      @testable import  AAA
      """, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      @testable import  AAA
      import CCC
      """,
    ),
    Example(
      """
      import FFF.B
      import EEE.A
      #if os(Linux)
      import DDD.A
      import EEE.B
      #else
      import DDD.B
      import CCC
      #endif
      import AAA
      import BBB
      """, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      import EEE.A
      import FFF.B
      #if os(Linux)
      import DDD.A
      import EEE.B
      #else
      import CCC
      import DDD.B
      #endif
      import AAA
      import BBB
      """,
    ),
    Example(
      """
        // comment

        import BBB
        import AAA
      """,
    ): Example(
      """
        // comment

        import AAA
        import BBB
      """,
    ),
    Example(
      """
      // header

      import DDD
      import SSS

      // some comment
      import FFF // a comment
      """,
    ): Example(
      """
      // header

      import DDD
      import SSS

      // some comment
      import FFF // a comment
      """,
    ),
    Example(
      """
      // header

      // comment
      import BBB
      // another comment
      import AAA
      """,
    ): Example(
      """
      // header

      // another comment
      import AAA
      // comment
      import BBB
      """,
    ),
    Example(
      """
      // header

      import class CCC
      import BBB
      import LLL
      """,
    ): Example(
      """
      // header

      import BBB
      import class CCC
      import LLL
      """,
    ),
    Example(
      """
      // header

      import AAA
      import class CCC2.View
      import CCC1
      """,
    ): Example(
      """
      // header

      import AAA
      import CCC1
      import class CCC2.View
      """,
    ),
    Example(
      """
        @testable import BBB
      @testable import AAA
      """, configuration: groupByAttributesOptions, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      @testable import AAA
        @testable import BBB
      """,
    ),
    Example(
      """
        import AAA
      @testable import BBB
      """, configuration: groupByAttributesOptions, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      @testable import BBB
        import AAA
      """,
    ),
    Example(
      """
        import BBB
      @testable import AAA
      """, configuration: groupByAttributesOptions, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      @testable import AAA
        import BBB
      """,
    ),
    Example(
      """
        @testable import AAA
      @_exported import BBB
      """, configuration: groupByAttributesOptions, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      @_exported import BBB
        @testable import AAA
      """,
    ),
    Example(
      """
        import AAA
      @_exported @testable import BBB
      """, configuration: groupByAttributesOptions, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      @_exported @testable import BBB
        import AAA
      """,
    ),
    Example(
      """
        public import AAA
      @_exported @testable import BBB
      """, configuration: groupByAttributesOptions, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      @_exported @testable import BBB
        public import AAA
      """,
    ),
    Example(
      """
      import AAA
      private import BBB
      fileprivate import CCC
      internal import DDD
      package import EEE
      // A comment that needs to be shifted along with the import
      public import FFF
      """, configuration: groupByAttributesOptions, shouldTestMultiByteOffsets: false,
    ): Example(
      """
      // A comment that needs to be shifted along with the import
      public import FFF
      package import EEE
      internal import DDD
      fileprivate import CCC
      private import BBB
      import AAA
      """,
    ),
  ]
}
