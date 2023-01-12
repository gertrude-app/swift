import AppKit
import Foundation

func copyToClipboard(_ string: String) {
  NSPasteboard.general.clearContents()
  NSPasteboard.general.setString(string, forType: .string)
}
