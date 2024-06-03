import Foundation

public final class AppDescriptorFactory: AppDescribing {
  public private(set) var appIdManifest: AppIdManifest
  private var cache: [String: AppDescriptor] = [:]

  public init(appIdManifest: AppIdManifest = .init()) {
    self.appIdManifest = appIdManifest
  }

  public func appCache(get: String) -> AppDescriptor? {
    self.cache[get]
  }

  public func appCache(insert descriptor: AppDescriptor, for bundleId: String) {
    self.cache[bundleId] = descriptor
  }
}
