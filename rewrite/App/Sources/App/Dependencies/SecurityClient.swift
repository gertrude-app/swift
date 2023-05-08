import Dependencies
import SecurityFoundation

public struct SecurityClient: Sendable {
  var didAuthenticateAsAdmin: @Sendable () async -> Bool
}

extension SecurityClient: DependencyKey {
  public static var liveValue = Self(didAuthenticateAsAdmin: {
    guard let authorization = SFAuthorization.authorization() as? SFAuthorization,
          let right = NSString(string: kAuthorizationRuleAuthenticateAsAdmin).utf8String else {
      // TODO: log unreachable
      return false
    }

    // TODO: I could time this to test for the weird, pre-authed state
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
}

extension SecurityClient: TestDependencyKey {
  public static let testValue = Self(
    didAuthenticateAsAdmin: { false }
  )
}

public extension DependencyValues {
  var security: SecurityClient {
    get { self[SecurityClient.self] }
    set { self[SecurityClient.self] = newValue }
  }
}
