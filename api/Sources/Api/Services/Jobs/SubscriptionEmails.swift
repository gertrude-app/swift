import XPostmark

enum SubscriptionEmails {
  static func email(_ event: SubscriptionEmail, to address: EmailAddress) -> XPostmark.Email {
    switch event {
    case .trialEndingSoon:
      return self.trialEndingSoon(address.rawValue)
    case .trialEndedToOverdue:
      return self.trialEndedToOverdue(address.rawValue)
    case .overdueToUnpaid:
      return self.overdueToUnpaid(address.rawValue)
    case .paidToOverdue:
      return self.paidToOverdue(address.rawValue)
    case .unpaidToPendingDelete:
      return self.unpaidToPendingDelete(address.rawValue)
    case .deleteEmailUnverified:
      return self.deleteEmailUnverified(address.rawValue)
    }
  }

  private static func trialEndingSoon(_ address: String) -> XPostmark.Email {
    .init(
      to: address,
      from: "Gertrude App <noreply@gertrude.app>",
      replyTo: "jared@netrivet.com",
      subject: "[action required] Gertrude trial ending soon".withEmailSubjectDisambiguator,
      html: """
      <p>Hi there! 👋</p>

      <p>
        This is Jared from Gertrude, writing to let you know that your 60 day free
        trial is <em>ending in 7 days.</em> If you'd like to continue using Gertrude, please
        login to the <a href="https://parents.gertrude.app/settings">parents website</a>
        and click the <b>Start subscription</b> button.
      </p>

      <p>
        If you're having any kind of trouble with Gertrude, or have any questions
        at all, please don't hesitate to reach out. If you reply to this email, it will
        come straight to me.
      </p>

      <p>- Jared</p>
      """
    )
  }

  private static func trialEndedToOverdue(_ address: String) -> XPostmark.Email {
    .init(
      to: address,
      from: "Gertrude App <noreply@gertrude.app>",
      replyTo: "jared@netrivet.com",
      subject: "[action required] Gertrude trial ended".withEmailSubjectDisambiguator,
      html: """
      <p>Gertrude parent account holder,</p>

      <p>
        This is Jared from Gertrude, writing to let you know that your 60 day free
        trial <em>has ended.</em> If you'd like to continue using Gertrude, please
        login to the <a href="https://parents.gertrude.app/settings">parents website</a>
        and click the <b>Start subscription</b> button.
      </p>

      <p>
        If you don't setup up payment <em>within 2 weeks,</em> any Gertrude Mac apps connected
        to your account will <b>lose some functionality.</b> They will continue blocking
        the internet according to the rules already in place, but no rules can be created
        or edited after that point, all screenshots and keylogging will cease, and the app will
        no longer be able to issue or respond to unlock requests or filter suspension requests.
        Basically, we turn off all of the features that actively cost us money, until your
        subscription is paid.
      </p>

      <p>
        If you're having any kind of trouble with Gertrude, or have any questions
        at all, please don't hesitate to reach out. If you reply to this email, it will
        come straight to me.
      </p>

      <p>- Jared</p>
      """
    )
  }

  private static func overdueToUnpaid(_ address: String) -> XPostmark.Email {
    .init(
      to: address,
      from: "Gertrude App <noreply@gertrude.app>",
      replyTo: "jared@netrivet.com",
      subject: "[action required] Gertrude account disabled".withEmailSubjectDisambiguator,
      html: """
      <p>Gertrude parent account holder,</p>

      <p>
        This is Jared from Gertrude, writing to let you know that because your Gertrude
        trial period ended, and we did not receive any payment within 2 weeks, your
        account has been disabled. If you'd like to continue using Gertrude, please
        login to the <a href="https://parents.gertrude.app/settings">parents website</a>
        and click the <b>Start/Manage subscription</b> button.
      </p>

      <p>
        Any Gertrude Mac apps connected to your account have <b>lost some functionality.</b>
        They will continue blocking the internet according to the rules already in place,
        but no rules can be created or edited after that point, all screenshots and
        keylogging have ceased, and the app will no longer be able to issue or respond to
        unlock requests or filter suspension requests. Basically, we disable all of the
        features that actively cost us money, until your subscription is paid.
      </p>

      <p>
        If you have any questions at all, please don't hesitate to reach out. If you reply
        to this email, it will come straight to me.
      </p>

      <p>- Jared</p>
      """
    )
  }

  private static func paidToOverdue(_ address: String) -> XPostmark.Email {
    .init(
      to: address,
      from: "Gertrude App <noreply@gertrude.app>",
      replyTo: "jared@netrivet.com",
      subject: "[action required] Gertrude payment failed".withEmailSubjectDisambiguator,
      html: """
      <p>Gertrude parent account holder,</p>

      <p>
        This is Jared from Gertrude, writing to let you know that we did not receive
        payment for your Gertrude account this month, and it is now considered <b>overdue.</b>
        This can happen for a number of reasons, but the most common is that your credit
        card expired, or your bank declined the charge for some reason. To resolve the issue
        and guarantee uninterrupted protection of your children, please login to the
        <a href="https://parents.gertrude.app/settings">parents website</a> and click the
        <b>Manage subscription</b> button, then resolve the payment issue from there.
      </p>

      <p>
        If we don't receive a payment <em>within 2 weeks,</em> any Gertrude Mac apps connected
        to your account will <b>lose some functionality.</b> They will continue blocking
        the internet according to the rules already in place, but no rules can be created
        or edited after that point, all screenshots and keylogging will cease, and the app will
        no longer be able to issue or respond to unlock requests or filter suspension requests.
        Basically, we turn off all of the features that actively cost us money, until your
        subscription is paid.
      </p>

      <p>
        If you're having any kind of trouble with Gertrude, or have any questions
        at all, please don't hesitate to reach out. If you reply to this email, it will
        come straight to me.
      </p>

      <p>- Jared</p>
      """
    )
  }

  private static func unpaidToPendingDelete(_ address: String) -> XPostmark.Email {
    .init(
      to: address,
      from: "Gertrude App <noreply@gertrude.app>",
      replyTo: "jared@netrivet.com",
      subject: "[action required] Gertrude account will be deleted".withEmailSubjectDisambiguator,
      html: """
      <p>Gertrude parent account holder,</p>

      <p>
        This is Jared from Gertrude, writing to let you know that because your account
        has been in an unpaid status for 1 year, we have scheduled to delete it in 30 days.
        If you'd like to resume using Gertrude, you may login to the
        <a href="https://parents.gertrude.app/settings">parents website</a> and click the
        <b>Start/Manage subscription</b> button in order to setup a payment, at which point your
        account will be restored and you may use Gertrude to protect your children again.
      </p>

      <p>
        If you have any questions at all, please don't hesitate to reach out.
        If you reply to this email, it will come straight to me.
      </p>

      <p>- Jared</p>
      """
    )
  }

  private static func deleteEmailUnverified(_ address: String) -> XPostmark.Email {
    .init(
      to: address,
      from: "Gertrude App <noreply@gertrude.app>",
      replyTo: "jared@netrivet.com",
      subject: "Gertrude unverified account deleted".withEmailSubjectDisambiguator,
      html: """
      <p>Hi there! 👋</p>

      <p>
        This is Jared from Gertrude, writing to let you know that your <b>account has
        been deleted,</b> because you signed up for a free trial, but <em>never verified your
        email address.</em>
      </p>

      <p>
        If you still want to use Gertrude, no problem, just sign up again at
        <a href="https://parents.gertrude.app/signup">using this link</a>, and if you
        have trouble finding the verification email, be sure to check your <b>spam folder.</b>
      </p>

      <p>
        If you have any questions at all, please don't hesitate to reach out.
        If you reply to this email, it will come straight to me.
      </p>

      <p>- Jared</p>
      """
    )
  }
}
