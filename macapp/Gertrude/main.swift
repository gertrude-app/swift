import AppCore
import AppKit

let application = NSApplication.shared
let delegate = App()
application.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
