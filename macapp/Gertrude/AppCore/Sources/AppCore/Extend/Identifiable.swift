import Foundation

@dynamicMemberLookup
struct Identified<ID: Hashable, T>: Identifiable {
  var id: ID
  var identified: T

  subscript<U>(dynamicMember keyPath: KeyPath<T, U>) -> U {
    identified[keyPath: keyPath]
  }
}

extension Identified: Encodable where T: Encodable, ID: Encodable {}
extension Identified: Decodable where T: Decodable, ID: Decodable {}
extension Identified: Equatable where T: Equatable {}
extension Identified: Hashable where T: Hashable {}
