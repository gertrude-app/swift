import Foundation

struct InitialSignup: TemplateEmailModel {
  static var subject: String { "Action Required: Confirm your email" }
  static var layout: EmailLayout { .topLogo }
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
  static var layout: EmailLayout { .topLogo }
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
  var isFallback: Bool
  var templateModel: [String: String] { [
    "url": self.url,
    "userName": self.userName,
    "fallbackNotice": self.isFallback ? EMAIL_NOTIFICATION_FALLBACK : "",
  ] }
}

struct NotifyUnlockRequest: TemplateEmailModel {
  static var subject: String { "[Gertrude App] {{subject}}" }
  var subject: String
  var url: String
  var userName: String
  var unlockRequests: String
  var isFallback: Bool
  var templateModel: [String: String] { [
    "subject": self.subject,
    "url": self.url,
    "userName": self.userName,
    "unlockRequests": self.unlockRequests,
    "fallbackNotice": self.isFallback ? EMAIL_NOTIFICATION_FALLBACK : "",
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
  static var layout: EmailLayout { .topLogo }
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

let EMAIL_NOTIFICATION_FALLBACK = """
<br /><br /><br />
<p>
  👋 <b>Psst!</b> We're sending this notification <b>as an email</b> to your primary
  account address because you currently <b>don’t have any notifications set up.</b> If
  you’d rather receive events like these delivered as <b>text</b> or
  <b>Slack</b> messages, or to a different email address, you can configure all of that in
  the <a href="https://parents.gertrude.app/settings">Settings</a> screen.
</p>
"""
