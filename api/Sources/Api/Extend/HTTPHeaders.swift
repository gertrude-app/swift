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
  static let xUserToken = HTTPHeaders.Name("X-UserToken")
}
