import Foundation
import Shared
import TypescriptPairQL

struct GetAdminKeychains: TypescriptPair {
  static var auth: ClientAuth = .admin

  typealias Output = [Keychain]

  struct Keychain: TypescriptNestable, PairOutput {
    let id: Api.Keychain.Id
    let name: String
    let description: String?
    let isPublic: Bool
    let authorId: Admin.Id
    let keys: [PQL.Key]
  }
}

// resolver

extension GetAdminKeychains: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let models = try await context.admin.keychains()
    var keychains: [GetAdminKeychains.Keychain] = []
    for model in models {
      keychains.append(try await .init(from: model, in: context))
    }
    return keychains
  }
}

// extensions

extension GetAdminKeychains.Keychain {
  init(from model: Api.Keychain, in context: AdminContext) async throws {
    let keys = try await model.keys()
    id = model.id
    name = model.name
    description = model.description
    isPublic = model.isPublic
    authorId = model.authorId
    self.keys = keys.map { .init(from: $0) }
  }
}
