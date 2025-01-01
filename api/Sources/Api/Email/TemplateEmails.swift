import Foundation

struct InitialSignup: TemplateEmailModel {
  static var subject: String { "Action Required: Confirm your email" }
  var dashboardUrl: String
  var token: UUID
  var templateModel: [String: String] { [
    "dashboardUrl": self.dashboardUrl,
    "token": self.token.lowercased,
  ] }
}

struct PasswordReset: TemplateEmailModel {
  static var subject: String { "Gertrude app password reset" }
  var dashboardUrl: String
  var token: UUID
  var templateModel: [String: String] { [
    "dashboardUrl": self.dashboardUrl,
    "token": self.token.lowercased,
  ] }
}

struct PasswordResetNoAccount: TemplateEmailModel {
  static var subject: String { "Gertrude App password reset" }
}

struct MagicLink: TemplateEmailModel {
  static var subject: String { "Gertrude App magic link" }
  var url: String
  var templateModel: [String: String] { ["url": self.url] }
}

struct MagicLinkNoAccount: TemplateEmailModel {
  static var subject: String { "Gertrude App magic link" }
}

struct NotifySuspendFilter: TemplateEmailModel {
  static var subject: String { "[Gertrude App] New suspend filter request from {{userName}}" }
  var url: String
  var userName: String
  var templateModel: [String: String] { ["url": self.url, "userName": self.userName] }
}

struct NotifyUnlockRequest: TemplateEmailModel {
  static var subject: String { "[Gertrude App] {{subject}}" }
  var subject: String
  var url: String
  var userName: String
  var unlockRequests: String
  var templateModel: [String: String] { [
    "subject": self.subject,
    "url": self.url,
    "userName": self.userName,
    "unlockRequests": self.unlockRequests,
  ] }
}

struct NotifySecurityEvent: TemplateEmailModel {
  static var subject: String { "[Gertrude App] Security event for child: {{userName}}" }
  var userName: String
  var description: String
  var explanation: String
  var templateModel: [String: String] { [
    "userName": self.userName,
    "description": self.description,
    "explanation": self.explanation,
  ] }
}

struct ReSignup: TemplateEmailModel {
  static var subject: String { "Gertrude Signup Request" }
  var dashboardUrl: String
  var templateModel: [String: String] { ["dashboardUrl": self.dashboardUrl] }
}

struct VerifyNotificationEmail: TemplateEmailModel {
  static var subject: String { "Gertrude app verification code" }
  var code: Int
  var templateModel: [String: String] { ["code": "\(self.code)"] }
}

struct V2_7_0_Announce: TemplateEmailModel {
  static var layout: EmailLayout { .newVersionAnnouncement }
  static var displayName: String { "v2.7.0 Announcement" }
  static var subject: String { "Gertrude v2.7.0 is here!" }
}

enum AccountLifecycle {
  struct TrialEndingSoon: TemplateEmailModel {
    static var subject: String { "[action required] Gertrude trial ending soon" }
  }

  struct TrialEndedToOverdue: TemplateEmailModel {
    static var subject: String { "[action required] Gertrude trial ended" }
  }

  struct OverdueToUnpaid: TemplateEmailModel {
    static var subject: String { "[action required] Gertrude account disabled" }
  }

  struct PaidToOverdue: TemplateEmailModel {
    static var subject: String { "[action required] Gertrude payment failed" }
  }

  struct UnpaidToPendingDelete: TemplateEmailModel {
    static var subject: String { "[action required] Gertrude account will be deleted" }
  }

  struct DeleteEmailUnverified: TemplateEmailModel {
    static var subject: String { "Gertrude unverified account deleted" }
  }
}
