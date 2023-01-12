import Foundation

extension Array where Element: Identifiable {

  @dynamicMemberLookup
  struct Indexed<T>: Identifiable where T: Identifiable {
    let id: T.ID
    let index: Int
    let indexed: T

    subscript<U>(dynamicMember keyPath: KeyPath<T, U>) -> U {
      indexed[keyPath: keyPath]
    }
  }

  var indexed: [Indexed<Element>] {
    enumerated().map { index, element in
      Indexed(id: element.id, index: index, indexed: element)
    }
  }
}
