struct LegacyConstructorConfiguration: RuleConfiguration {
    let id = "legacy_constructor"
    let name = "Legacy Constructor"
    let summary = "Swift constructors are preferred over legacy convenience functions"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("CGPoint(x: 10, y: 10)"),
              Example("CGPoint(x: xValue, y: yValue)"),
              Example("CGSize(width: 10, height: 10)"),
              Example("CGSize(width: aWidth, height: aHeight)"),
              Example("CGRect(x: 0, y: 0, width: 10, height: 10)"),
              Example("CGRect(x: xVal, y: yVal, width: aWidth, height: aHeight)"),
              Example("CGVector(dx: 10, dy: 10)"),
              Example("CGVector(dx: deltaX, dy: deltaY)"),
              Example("NSPoint(x: 10, y: 10)"),
              Example("NSPoint(x: xValue, y: yValue)"),
              Example("NSSize(width: 10, height: 10)"),
              Example("NSSize(width: aWidth, height: aHeight)"),
              Example("NSRect(x: 0, y: 0, width: 10, height: 10)"),
              Example("NSRect(x: xVal, y: yVal, width: aWidth, height: aHeight)"),
              Example("NSRange(location: 10, length: 1)"),
              Example("NSRange(location: loc, length: len)"),
              Example("UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)"),
              Example("UIEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)"),
              Example("NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)"),
              Example("NSEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)"),
              Example("UIOffset(horizontal: 0, vertical: 10)"),
              Example("UIOffset(horizontal: horizontal, vertical: vertical)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓CGPointMake(10, 10)"),
              Example("↓CGPointMake(xVal, yVal)"),
              Example("↓CGPointMake(calculateX(), 10)"),
              Example("↓CGSizeMake(10, 10)"),
              Example("↓CGSizeMake(aWidth, aHeight)"),
              Example("↓CGRectMake(0, 0, 10, 10)"),
              Example("↓CGRectMake(xVal, yVal, width, height)"),
              Example("↓CGVectorMake(10, 10)"),
              Example("↓CGVectorMake(deltaX, deltaY)"),
              Example("↓NSMakePoint(10, 10)"),
              Example("↓NSMakePoint(xVal, yVal)"),
              Example("↓NSMakeSize(10, 10)"),
              Example("↓NSMakeSize(aWidth, aHeight)"),
              Example("↓NSMakeRect(0, 0, 10, 10)"),
              Example("↓NSMakeRect(xVal, yVal, width, height)"),
              Example("↓NSMakeRange(10, 1)"),
              Example("↓NSMakeRange(loc, len)"),
              Example("↓UIEdgeInsetsMake(0, 0, 10, 10)"),
              Example("↓UIEdgeInsetsMake(top, left, bottom, right)"),
              Example("↓NSEdgeInsetsMake(0, 0, 10, 10)"),
              Example("↓NSEdgeInsetsMake(top, left, bottom, right)"),
              Example("↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)"),
              Example("↓UIOffsetMake(0, 10)"),
              Example("↓UIOffsetMake(horizontal, vertical)"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("↓CGPointMake(10,  10)"): Example("CGPoint(x: 10,  y: 10)"),
              Example("↓CGPointMake(xPos,  yPos)"): Example("CGPoint(x: xPos,  y: yPos)"),
              Example("↓CGSizeMake(10, 10)"): Example("CGSize(width: 10, height: 10)"),
              Example("↓CGSizeMake( aWidth, aHeight )"): Example(
                "CGSize( width: aWidth, height: aHeight )",
              ),
              Example("↓CGRectMake(0, 0, 10, 10)"): Example(
                "CGRect(x: 0, y: 0, width: 10, height: 10)",
              ),
              Example("↓CGRectMake(xPos, yPos , width, height)"):
                Example("CGRect(x: xPos, y: yPos , width: width, height: height)"),
              Example("↓CGVectorMake(10, 10)"): Example("CGVector(dx: 10, dy: 10)"),
              Example("↓CGVectorMake(deltaX, deltaY)"): Example("CGVector(dx: deltaX, dy: deltaY)"),
              Example("↓NSMakePoint(10,  10   )"): Example("NSPoint(x: 10,  y: 10   )"),
              Example("↓NSMakePoint(xPos,  yPos   )"): Example("NSPoint(x: xPos,  y: yPos   )"),
              Example("↓NSMakeSize(10, 10)"): Example("NSSize(width: 10, height: 10)"),
              Example("↓NSMakeSize( aWidth, aHeight )"): Example(
                "NSSize( width: aWidth, height: aHeight )",
              ),
              Example("↓NSMakeRect(0, 0, 10, 10)"): Example(
                "NSRect(x: 0, y: 0, width: 10, height: 10)",
              ),
              Example("↓NSMakeRect(xPos, yPos , width, height)"):
                Example("NSRect(x: xPos, y: yPos , width: width, height: height)"),
              Example("↓NSMakeRange(10, 1)"): Example("NSRange(location: 10, length: 1)"),
              Example("↓NSMakeRange(loc, len)"): Example("NSRange(location: loc, length: len)"),
              Example("↓CGVectorMake(10, 10)\n↓NSMakeRange(10, 1)"):
                Example("CGVector(dx: 10, dy: 10)\nNSRange(location: 10, length: 1)"),
              Example("↓CGVectorMake(dx, dy)\n↓NSMakeRange(loc, len)"):
                Example("CGVector(dx: dx, dy: dy)\nNSRange(location: loc, length: len)"),
              Example("↓UIEdgeInsetsMake(0, 0, 10, 10)"):
                Example("UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)"),
              Example("↓UIEdgeInsetsMake(top, left, bottom, right)"):
                Example("UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)"),
              Example("↓NSEdgeInsetsMake(0, 0, 10, 10)"):
                Example("NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)"),
              Example("↓NSEdgeInsetsMake(top, left, bottom, right)"):
                Example("NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)"),
              Example("↓NSMakeRange(0, attributedString.length)"):
                Example("NSRange(location: 0, length: attributedString.length)"),
              Example("↓CGPointMake(calculateX(), 10)"): Example("CGPoint(x: calculateX(), y: 10)"),
              Example("↓UIOffsetMake(0, 10)"): Example("UIOffset(horizontal: 0, vertical: 10)"),
              Example("↓UIOffsetMake(horizontal, vertical)"):
                Example("UIOffset(horizontal: horizontal, vertical: vertical)"),
            ]
    }
}
