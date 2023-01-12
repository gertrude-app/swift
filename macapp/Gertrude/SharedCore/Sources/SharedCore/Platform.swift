import AppKit

public enum PlatformDataFormat {
  case data
  case string
}

public func platformData(_ key: String, format: PlatformDataFormat) -> String? {
  let service = IOServiceGetMatchingService(
    kIOMasterPortDefault,
    IOServiceMatching("IOPlatformExpertDevice")
  )
  defer { IOObjectRetain(service) }

  let typeRef = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)
  switch format {
  case .data:
    return (typeRef?.takeRetainedValue() as? Data)
      .flatMap { String(data: $0, encoding: .utf8) }
  case .string:
    return typeRef?.takeRetainedValue() as? String
  }
}
