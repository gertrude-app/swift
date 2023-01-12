import Vapor

extension HTTPHeaders {
  var dashboardUrl: String {
    first(name: .xDashboardUrl) ?? Env.DASHBOARD_URL
  }
}

extension HTTPHeaders.Name {
  static let xAppVersion = HTTPHeaders.Name("X-App-Version")
  static let xDashboardUrl = HTTPHeaders.Name("X-DashboardUrl")
  static let xAdminToken = HTTPHeaders.Name("X-AdminToken")
  static let xUserToken = HTTPHeaders.Name("X-UserToken")
}
