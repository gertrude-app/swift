import Foundation

struct Device {
  static let shared = Device()

  var hostname: String? {
    Host.current().localizedName
  }

  var username: String {
    NSUserName()
  }

  var fullUsername: String {
    NSFullUserName()
  }

  var numericUserId: uid_t {
    getuid()
  }

  var serialNumber: String? {
    let platformExpert = IOServiceGetMatchingService(
      kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice")
    )

    guard platformExpert > 0 else {
      return nil
    }

    guard
      let serialNumber =
      (IORegistryEntryCreateCFProperty(
        platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0
      ).takeUnretainedValue() as? String)
    else {
      return nil
    }

    IOObjectRelease(platformExpert)
    return serialNumber
  }
}

// https://di-api.reincubate.com/v1/apple-serials/C07D92QVPJJ9/
