import ClientInterfaces
import Dependencies
import SecurityFoundation

public struct SecurityClient: Sendable {
  var didAuthenticateAsAdmin: @Sendable () async -> Bool
}

extension SecurityClient: DependencyKey {
  #if DEBUG
    public static let liveValue = Self(
      didAuthenticateAsAdmin: { true }
    )
  #else
    public static var liveValue = Self(didAuthenticateAsAdmin: {
      guard let authorization = SFAuthorization.authorization() as? SFAuthorization,
            let right = NSString(string: kAuthorizationRuleAuthenticateAsAdmin).utf8String else {
        unexpectedError(id: "43f78286")
        return false
      }

      defer { authorization.invalidateCredentials() }
      return await withCheckedContinuation { continuation in
        do {
          try authorization.obtain(
            withRight: right,
            flags: [.extendRights, .interactionAllowed, .destroyRights]
          )
          continuation.resume(returning: true)
        } catch {
          continuation.resume(returning: false)
        }
      }
    })
  #endif
}

extension SecurityClient: TestDependencyKey {
  public static let testValue = Self(
    didAuthenticateAsAdmin: unimplemented("SecurityClient.didAuthenticateAsAdmin")
  )
  public static let mock = Self(
    didAuthenticateAsAdmin: { false }
  )
}

public extension DependencyValues {
  var security: SecurityClient {
    get { self[SecurityClient.self] }
    set { self[SecurityClient.self] = newValue }
  }
}
