import SecurityFoundation
import SharedCore

struct Auth {
  static func challengeAdmin(completionHandler: @escaping (Bool) -> Void) {
    DispatchQueue.main.async {
      self.isUserAdmin(completionHandler)
    }
  }

  private static func isUserAdmin(_ completionHandler: @escaping (Bool) -> Void) {
    if isDev() {
      completionHandler(true)
      return
    }

    guard
      let authorization = SFAuthorization.authorization() as? SFAuthorization,
      let right = NSString(string: kAuthorizationRuleAuthenticateAsAdmin).utf8String
    else {
      log(.error("failed to set up admin auth challenge", nil))
      completionHandler(false)
      return
    }

    // maybe this will fix the admin challenge issue?
    // or, could try setting .extendRights AND .partialRights
    // @see https://developer.apple.com/documentation/security/authorizationflags/1394760-partialrights
    defer { authorization.invalidateCredentials() }

    do {
      try authorization.obtain(
        withRight: right,
        flags: [.extendRights, .interactionAllowed, .destroyRights]
      )
    } catch {
      completionHandler(false)
      return
    }

    completionHandler(true)
  }
}
