import ArgumentParser

@main struct Gertie: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    subcommands: [Codegen.self]
  )
}
