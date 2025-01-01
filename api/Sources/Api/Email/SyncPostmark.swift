import Dependencies
import Foundation
import Rainbow
import XCore
import XHttp

struct SyncPostmark {
  @Dependency(\.env) var env
  @Dependency(\.logger) var logger

  func syncAll() async {
    for layout in EmailLayout.allCases {
      await self.syncLayout(layout)
    }
    await self.syncTemplate(InitialSignup.self)
    await self.syncTemplate(PasswordReset.self)
    await self.syncTemplate(PasswordResetNoAccount.self)
    await self.syncTemplate(MagicLink.self)
    await self.syncTemplate(MagicLinkNoAccount.self)
    await self.syncTemplate(NotifySuspendFilter.self)
    await self.syncTemplate(NotifyUnlockRequest.self)
    await self.syncTemplate(NotifySecurityEvent.self)
    await self.syncTemplate(ReSignup.self)
    await self.syncTemplate(VerifyNotificationEmail.self)
    await self.syncTemplate(V2_7_0_Announce.self)
    await self.syncTemplate(AccountLifecycle.TrialEndingSoon.self)
    await self.syncTemplate(AccountLifecycle.TrialEndedToOverdue.self)
    await self.syncTemplate(AccountLifecycle.OverdueToUnpaid.self)
    await self.syncTemplate(AccountLifecycle.PaidToOverdue.self)
    await self.syncTemplate(AccountLifecycle.UnpaidToPendingDelete.self)
    await self.syncTemplate(AccountLifecycle.DeleteEmailUnverified.self)
  }

  func syncLayout(_ layout: EmailLayout) async {
    let baseCss = try! String(contentsOfFile: self.layoutsDir + "/base.css")
    let layoutCss = layout == .base ? "" :
      (try? String(contentsOfFile: self.layoutsDir + "/\(layout.slug).css")) ?? ""
    let baseHtml = try! String(contentsOfFile: self.layoutsDir + "/base.html")
      .replacingOccurrences(of: "/* CSS_HERE */", with: baseCss + layoutCss)

    var layoutHtml = baseHtml
    if layout != .base {
      layoutHtml = baseHtml.replacingOccurrences(
        of: "{{{ @content }}}",
        with: try! String(contentsOfFile: self.layoutsDir + "/\(layout.slug).html")
      )
    }

    await self.put(template: EditTemplate.Input(
      Name: layout.name,
      Subject: "",
      HtmlBody: layoutHtml,
      TextBody: "{{{ @content }}}",
      Alias: layout.slug,
      LayoutTemplate: nil
    ))
  }

  func syncTemplate<M: TemplateEmailModel>(_: M.Type) async {
    let templateDir = self.emailsDir + "/Templates/\(M.name)"
    let html = try! String(contentsOfFile: templateDir + "/template.html")
    let text = try! String(contentsOfFile: templateDir + "/template.md")
    await self.put(template: EditTemplate.Input(
      Name: M.displayName,
      Subject: "\(M.subject){{subjref}}",
      HtmlBody: html,
      TextBody: text,
      Alias: M.alias,
      LayoutTemplate: M.layout.slug
    ))
  }

  func put(template: EditTemplate.Input) async {
    let kind = template.Subject.isEmpty ? "layout".yellow : "template".magenta
    do {
      let res = try await HTTP.sendJson(
        body: template,
        to: "https://api.postmarkapp.com/templates/\(template.Alias)",
        method: .put,
        decoding: EditTemplate.Response.self,
        headers: [
          "Accept": "application/json",
          "X-Postmark-Server-Token": self.env.postmark.apiKey,
        ]
      )
      self.logger.info("Synced Postmark \(kind) `\(template.Name)`")
      self.logger.info("  -> \(res.accountUrl(in: self.env))")
    } catch {
      self.logger.error("Error syncing Postmark \(kind) `\(template.Name)`")
      self.logger.error("  -> alias: \(template.Alias)")
      self.logger.error("  -> template: \(template.LayoutTemplate ?? "(nil)")")
      self.logger.error("  -> error: \(error)")
    }
  }

  var emailsDir: String {
    FileManager.default.currentDirectoryPath + "/Sources/Api/Email"
  }

  var layoutsDir: String {
    self.emailsDir + "/Layouts"
  }
}

protocol PmResponse {
  func accountUrl(in env: Env) -> String
}

extension PmResponse {
  func serverUrl(in env: Env) -> String {
    "https://account.postmarkapp.com/servers/\(env.postmark.serverId)"
  }
}

enum EditTemplate {
  struct Input: Encodable {
    let Name: String
    let Subject: String
    let HtmlBody: String
    let TextBody: String
    let Alias: String
    let LayoutTemplate: String?
  }

  struct Response: Decodable, PmResponse {
    let TemplateId: Int
    let Name: String
    let Active: Bool
    let Alias: String?
    let TemplateType: String
    let LayoutTemplate: String?

    func accountUrl(in env: Env) -> String {
      "\(self.serverUrl(in: env))/templates/\(self.TemplateId)/edit"
    }
  }
}
