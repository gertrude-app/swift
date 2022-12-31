import Duet

final class WaitlistedAdmin: Codable {
  var id: Id
  var email: EmailAddress
  var signupToken: SignupToken?
  var createdAt = Date()
  var updatedAt = Date()

  init(id: Id = .init(), email: EmailAddress, signupToken: SignupToken? = nil) {
    self.id = id
    self.email = email
    self.signupToken = signupToken
  }
}

// extensions

extension WaitlistedAdmin {
  typealias SignupToken = Tagged<WaitlistedAdmin, UUID>
}
