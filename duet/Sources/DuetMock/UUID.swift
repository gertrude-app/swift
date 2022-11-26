import Duet

public func mockUUIDs() -> (String, String, String, String) {
  let uuids = (
    UUID().lowercased,
    UUID().lowercased,
    UUID().lowercased,
    UUID().lowercased
  )

  var array = [uuids.0, uuids.1, uuids.2, uuids.3]

  UUID.new = { guard !array.isEmpty else { return UUID() }
    return UUID(uuidString: array.removeFirst())!
  }

  return uuids
}
