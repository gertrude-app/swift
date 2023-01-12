import Foundation

public func isDev() -> Bool {
  !SharedConstants.PAIRQL_ENDPOINT.absoluteString.contains("api.gertrude")
}

public func isTestMachine() -> Bool {
  platformData(kIOPlatformSerialNumberKey, format: .string) ==
    "C07D92QVPJJ9"
}
