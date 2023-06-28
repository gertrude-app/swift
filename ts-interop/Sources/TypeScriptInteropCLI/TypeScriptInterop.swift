// produce typescript type (Better than as is)
// generate enum codable conformances (ideally, without needing code to be in compiling state)

@main
public struct TypeScriptInterop {
  public private(set) var text = "Hello, World!"

  public static func main() {
    print(TypeScriptInterop().text)
  }
}
