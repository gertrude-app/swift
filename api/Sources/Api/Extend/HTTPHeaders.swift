import Dependencies
import Vapor

extension HTTPHeaders {
  var dashboardUrl: String {
    @Dependency(\.env) var env
    return first(name: .xDashboardUrl) ?? env.dashboardUrl
  }
}

extension HTTPHeaders.Name {
  static let xAppVersion = HTTPHeaders.Name("X-App-Version")
  static let xDashboardUrl = HTTPHeaders.Name("X-DashboardUrl")
  static let xAdminToken = HTTPHeaders.Name("X-AdminToken")
  static let xSuperAdminToken = HTTPHeaders.Name("X-SuperAdminToken")
  // actual header not renamed, pending careful long-term deprecation
  static let xMacAppToken = HTTPHeaders.Name("X-UserToken")
}
