import Dependencies
import Foundation
import Rainbow
import XCore
import XHttp

#if DEBUG
  struct SyncPostmark {
    @Dependency(\.env) var env
    @Dependency(\.logger) var logger

    func syncAll() async {
      for layout in EmailLayout.allCases {
        await self.syncLayout(layout)
      }
      // await self.syncTemplate(InitialSignup.self)
      // await self.syncTemplate(PasswordReset.self)
      // await self.syncTemplate(PasswordResetNoAccount.self)
      // await self.syncTemplate(MagicLink.self)
      // await self.syncTemplate(MagicLinkNoAccount.self)
      // await self.syncTemplate(NotifySuspendFilter.self)
      // await self.syncTemplate(NotifyUnlockRequest.self)
      // await self.syncTemplate(NotifySecurityEvent.self)
      // await self.syncTemplate(ReSignup.self)
      // await self.syncTemplate(VerifyNotificationEmail.self)
      await self.syncTemplate(V2_7_0_Announce.self)
      // await self.syncTemplate(AccountLifecycle.TrialEndingSoon.self)
      // await self.syncTemplate(AccountLifecycle.TrialEndedToOverdue.self)
      // await self.syncTemplate(AccountLifecycle.OverdueToUnpaid.self)
      // await self.syncTemplate(AccountLifecycle.PaidToOverdue.self)
      // await self.syncTemplate(AccountLifecycle.UnpaidToPendingDelete.self)
      // await self.syncTemplate(AccountLifecycle.DeleteEmailUnverified.self)
    }

    func syncLayout(_ layout: EmailLayout) async {
      await self.put(template: layout.pmTemplateInput())
    }

    func syncTemplate<T: TemplateEmailModel>(_: T.Type) async {
      await self.put(template: T.pmTemplateInput())
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
  }

  extension TemplateEmailModel {
    static func pmTemplateInput() -> EditTemplate.Input {
      let templateDir = FileManager.default
        .currentDirectoryPath + "/Sources/Api/Email/Templates/\(Self.name)"
      let html = try! String(contentsOfFile: templateDir + "/template.html", encoding: .utf8)
      let text = try! String(contentsOfFile: templateDir + "/template.md", encoding: .utf8)
      return EditTemplate.Input(
        Name: Self.displayName,
        Subject: "\(Self.subject){{subjref}}",
        HtmlBody: html,
        TextBody: text,
        Alias: Self.alias,
        LayoutTemplate: Self.layout.slug
      )
    }
  }

  extension EmailLayout {
    func pmTemplateInput() -> EditTemplate.Input {
      let layoutsDir = FileManager.default.currentDirectoryPath + "/Sources/Api/Email/Layouts"
      let baseCss = try! String(contentsOfFile: layoutsDir + "/base.css", encoding: .utf8)
      let layoutCss = self == .base ? "" :
        (try? String(contentsOfFile: layoutsDir + "/\(self.slug).css", encoding: .utf8)) ?? ""
      let baseHtml = try! String(contentsOfFile: layoutsDir + "/base.html", encoding: .utf8)
        .replacingOccurrences(of: "/* CSS_HERE */", with: baseCss + layoutCss)

      var layoutHtml = baseHtml
      if self != .base {
        layoutHtml = baseHtml.replacingOccurrences(
          of: "{{{ @content }}}",
          with: try! String(contentsOfFile: layoutsDir + "/\(self.slug).html", encoding: .utf8)
        )
      }

      return EditTemplate.Input(
        Name: self.name,
        Subject: "",
        HtmlBody: layoutHtml,
        TextBody: "{{{ @content }}}",
        Alias: self.slug,
        LayoutTemplate: nil
      )
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
#endif
