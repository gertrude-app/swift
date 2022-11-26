precedencegroup ForwardApplication {
  associativity: left
}

infix operator |>: ForwardApplication

public func |> <A, B>(_ a: A, _ f: @escaping (A) -> B) -> B {
  f(a)
}
