import SwiftUI

// remove this and replace call sites with just `Text(...)`
// when you drop support for Big Sur
func Markdown(_ markdown: String) -> Text {
  if #available(macOS 12.0, *) {
    return Text(LocalizedStringKey(markdown))
  }

  var accum = Text("")
  var current = ""
  var index = markdown.startIndex
  var inItalic = false
  var inBold = false
  var inMono = false

  repeat {
    let char = markdown[index]
    switch char {
    case "_":
      if inItalic {
        accum = accum + Text(current).italic()
      } else {
        accum = accum + Text(current)
      }
      current = ""
      inItalic = !inItalic
    case "*":
      index = markdown.index(after: index)
      if inBold {
        accum = accum + Text(current).bold()
      } else {
        accum = accum + Text(current)
      }
      current = ""
      inBold = !inBold
    case "`":
      if inMono {
        accum = accum + Text(current).font(.system(.body, design: .monospaced))
      } else {
        accum = accum + Text(current)
      }
      current = ""
      inMono = !inMono
    default:
      current.append(char)
    }
    index = markdown.index(after: index)
  } while index < markdown.endIndex

  return accum + Text(current)
}
