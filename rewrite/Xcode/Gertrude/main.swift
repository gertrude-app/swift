import AppKit

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
