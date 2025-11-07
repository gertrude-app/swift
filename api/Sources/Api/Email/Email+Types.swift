import Foundation

enum TemplateEmail {
  case initialSignup(to: String, model: InitialSignup)
  case passwordReset(to: String, model: PasswordReset)
  case passwordResetNoAccount(to: String, model: PasswordResetNoAccount)
  case magicLink(to: String, model: MagicLink)
  case magicLinkNoAccount(to: String, model: MagicLinkNoAccount)
  case notifySuspendFilter(to: String, model: NotifySuspendFilter)
  case notifyUnlockRequest(to: String, model: NotifyUnlockRequest)
  case notifySecurityEvent(to: String, model: NotifySecurityEvent)
  case verifyNotificationEmail(to: String, model: VerifyNotificationEmail)
  case reSignup(to: String, model: ReSignup)
  case v2_7_0_Announce(to: [String], model: V2_7_0_Announce, dryRun: Bool)
  case trialEndingSoon(to: String, model: AccountLifecycle.TrialEndingSoon)
  case trialEndedToOverdue(to: String, model: AccountLifecycle.TrialEndedToOverdue)
  case overdueToUnpaid(to: String, model: AccountLifecycle.OverdueToUnpaid)
  case paidToOverdue(to: String, model: AccountLifecycle.PaidToOverdue)
  case unpaidToPendingDelete(to: String, model: AccountLifecycle.UnpaidToPendingDelete)
  case deleteEmailUnverified(to: String, model: AccountLifecycle.DeleteEmailUnverified)
}

enum EmailLayout: String, CaseIterable {
  case base
  case topLogo
}

protocol TemplateEmailModel: Sendable {
  var templateModel: [String: String] { get }
  static var name: String { get }
  static var subject: String { get }
  static var layout: EmailLayout { get }
  static var displayName: String { get }
}

extension TemplateEmailModel {
  var templateModel: [String: String] { [:] }
  var templateAlias: String { Self.alias }
  static var layout: EmailLayout { .base }
  static var name: String { "\(Self.self)" }
  static var alias: String { name.snakeCased.replacing("_", with: "-") }
  static var displayName: String { name.replacing("_", with: " ") }
}

extension EmailLayout {
  var slug: String {
    self.rawValue.snakeCased.replacing("_", with: "-")
  }

  var name: String {
    self.rawValue.snakeCased.replacing("_", with: " ").capitalized
  }

  init?(slug: String) {
    self.init(
      rawValue: slug.split(separator: "-")
        .enumerated()
        .map { i, s in i != 0 ? s.capitalized : String(s) }
        .joined(),
    )
  }
}

extension TemplateEmail {
  var model: any TemplateEmailModel {
    switch self {
    case .initialSignup(_, let model): model
    case .reSignup(_, let model): model
    case .v2_7_0_Announce(_, let model, _): model
    case .trialEndingSoon(_, let model): model
    case .trialEndedToOverdue(_, let model): model
    case .overdueToUnpaid(_, let model): model
    case .paidToOverdue(_, let model): model
    case .unpaidToPendingDelete(_, let model): model
    case .deleteEmailUnverified(_, let model): model
    case .passwordReset(_, let model): model
    case .passwordResetNoAccount(_, let model): model
    case .magicLink(_, let model): model
    case .magicLinkNoAccount(_, let model): model
    case .notifySuspendFilter(_, let model): model
    case .notifyUnlockRequest(_, let model): model
    case .notifySecurityEvent(_, let model): model
    case .verifyNotificationEmail(_, let model): model
    }
  }
}
