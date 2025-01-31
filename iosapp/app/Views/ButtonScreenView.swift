import SwiftUI

struct ButtonScreenView: View {
  let text: String
  let primaryBtnText: String
  let onPrimaryBtnTap: () -> Void
  let secondaryBtn: (text: String, onTap: () -> Void)?
  let screenType: ScreenType

  // for just one button
  init(
    text: String,
    buttonText: String,
    screenType: ScreenType = .info,
    onButtonTap: @escaping () -> Void
  ) {
    self.text = text
    self.primaryBtnText = buttonText
    self.screenType = screenType
    self.onPrimaryBtnTap = onButtonTap
    self.secondaryBtn = nil
  }

  // for two buttons
  init(
    text: String,
    primaryButtonText: String,
    secondaryButtonText: String,
    screenType: ScreenType = .question,
    onPrimaryButtonTap: @escaping () -> Void,
    secondary onSecondaryButtonTap: @escaping () -> Void
  ) {
    self.text = text
    self.primaryBtnText = primaryButtonText
    self.screenType = screenType
    self.onPrimaryBtnTap = onPrimaryButtonTap
    self.secondaryBtn = (text: secondaryButtonText, onTap: onSecondaryButtonTap)
  }

  @State var showBg = false
  @State var iconOffset = Vector(0, -20)
  @State var textOffset = Vector(0, 20)
  @State var primaryButtonOffset = Vector(0, 20)
  @State var secondaryButtonOffset = Vector(0, 20)

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: self.screenType == .info ? "info.circle" : "questionmark.circle")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(Color.violet500)
        .swooshIn(tracking: self.$iconOffset, to: .origin, after: .zero, for: .milliseconds(800))

      Spacer()

      Text(self.text)
        .font(.system(size: 18, weight: .medium))
        .multilineTextAlignment(.center)
        .swooshIn(tracking: self.$textOffset, to: .origin, after: .zero, for: .milliseconds(800))

      BigButton(self.primaryBtnText, variant: .primary) {
        self.vanishingAnimations()
        delayed(by: .milliseconds(800)) {
          self.onPrimaryBtnTap()
        }
      }
      .swooshIn(
        tracking: self.$primaryButtonOffset,
        to: .origin,
        after: .milliseconds(150),
        for: .milliseconds(800)
      )
      .padding(.top, 12)

      if let (secondaryText, secondaryOnTap) = self.secondaryBtn {
        BigButton(secondaryText, variant: .secondary) {
          self.vanishingAnimations()
          delayed(by: .milliseconds(800)) {
            secondaryOnTap()
          }
        }
        .swooshIn(
          tracking: self.$secondaryButtonOffset,
          to: .origin,
          after: .milliseconds(300),
          for: .milliseconds(800)
        )
      }
    }
    .padding(30)
    .padding(.top, 50)
    .background(Gradient(colors: [.violet200, .white]))
    .opacity(self.showBg ? 1 : 0)
    .onAppear {
      withAnimation(.smooth(duration: 0.7)) {
        self.showBg = true
      }
    }
  }

  func vanishingAnimations() {
    withAnimation {
      self.iconOffset.y = -20
      self.secondaryButtonOffset.y = 20
    }

    delayed(by: .milliseconds(100)) {
      withAnimation {
        self.primaryButtonOffset.y = 20
        self.showBg = false
      }
    }

    delayed(by: .milliseconds(200)) {
      withAnimation {
        self.textOffset.y = 20
      }
    }
  }

  enum ScreenType {
    case info
    case question
  }
}

#Preview("1 button") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    buttonText: "Next"
  ) {}
}

#Preview("2 buttons") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primaryButtonText: "Do something",
    secondaryButtonText: "Do something else"
  ) {} secondary: {}
}
