import Dependencies
import Vapor
import XPostmark
import XSendGrid

public extension DependencyValues {
  var sendgrid: SendGrid.Client {
    get { self[SendGrid.Client.self] }
    set { self[SendGrid.Client.self] = newValue }
  }
}

extension SendGrid.Client: DependencyKey {
  public static var liveValue: SendGrid.Client {
    let env = Env.fromProcess(mode: try? Vapor.Environment.detect())
    let liveSendGrid = SendGrid.Client.live(apiKey: env.sendgridApiKey)
    return .init(send: { message in
      if !isCypressTestAddress(message.firstRecipient.email) {
        try await liveSendGrid.send(message)
      } else {
        with(dependency: \.logger)
          .info("skipping SendGrid.Client.send for cypress test")
      }
    })
  }
}

public extension DependencyValues {
  var postmark: XPostmark.Client {
    get { self[XPostmark.Client.self] }
    set { self[XPostmark.Client.self] = newValue }
  }
}

extension XPostmark.Client: DependencyKey {
  public static var liveValue: XPostmark.Client {
    @Dependency(\.logger) var logger
    let env = Env.fromProcess(mode: try? Vapor.Environment.detect())
    let liveSendGrid = SendGrid.Client.live(apiKey: env.sendgridApiKey)
    let livePostmark = XPostmark.Client.live(apiKey: env.postmarkApiKey)
    if env.mode != .prod {
      return .init(
        sendEmail: { email in
          logger.info("non-prod XPostmark.Client.send, delegating to sendgrid")
          do {
            try await liveSendGrid.send(.init(postmark: email))
            return .success(())
          } catch {
            logger.error("failed to send email: \(error)")
            return .failure(.init(statusCode: -5, errorCode: -5, message: "\(error)"))
          }
        },
        sendTemplateEmail: { email in
          await livePostmark.sendTemplateEmail(email)
        },
        sendTemplateEmailBatch: { emails in
          await livePostmark.sendTemplateEmailBatch(emails)
        }
      )
    } else {
      return .init(
        sendEmail: { email in
          if isCypressTestAddress(email.to) {
            logger.info("skipping XPostmark.Client.send for cypress test")
            return .success(())
          } else if isProdSmokeTestAddress(email.to) || isJaredTestAddress(email.to) {
            logger.info("delegating XPostmark.Client.send to SendGrid.Client.send for test")
            do {
              try await liveSendGrid.send(.init(postmark: email))
              return .success(())
            } catch {
              logger.error("failed to send test email: \(error)")
              return .failure(.init(statusCode: -6, errorCode: -6, message: "\(error)"))
            }
          } else {
            return await livePostmark.sendEmail(email)
          }
        },
        sendTemplateEmail: { email in
          await livePostmark.sendTemplateEmail(email)
        },
        sendTemplateEmailBatch: { emails in
          await livePostmark.sendTemplateEmailBatch(emails)
        }
      )
    }
  }
}

#if DEBUG
  extension SendGrid.Client: TestDependencyKey {
    public static var testValue: SendGrid.Client {
      .init(send: { _ in
        unimplemented("SendGrid.Client.send()", placeholder: ())
      })
    }
  }
#endif

public extension SendGrid.Email {
  init(postmark: XPostmark.Email) {
    self.init(
      to: .init(email: postmark.to),
      from: .init(email: postmark.from),
      subject: postmark.subject,
      html: postmark.body
    )
  }
}

func isCypressTestAddress(_ email: String) -> Bool {
  email.starts(with: "e2e-user-") && email.contains("@gertrude.app")
}

func isProdSmokeTestAddress(_ email: String) -> Bool {
  email.contains(".smoke-test-") && email.contains("@inbox.testmail.app")
}

func isJaredTestAddress(_ email: String) -> Bool {
  email.starts(with: "jared+") && email.hasSuffix("@netrivet.com")
}

func isTestAddress(_ email: String) -> Bool {
  isCypressTestAddress(email) || isProdSmokeTestAddress(email)
}
