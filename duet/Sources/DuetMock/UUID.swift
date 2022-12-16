import Duet

public func mockUUIDs() -> (UUID, UUID) {
  let uuids = (UUID(), UUID())
  var array = [uuids.0, uuids.1]

  UUID.new = {
    guard !array.isEmpty else { return UUID() }
    return array.removeFirst()
  }

  return uuids
}
