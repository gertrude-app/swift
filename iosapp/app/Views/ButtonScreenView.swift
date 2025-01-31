import SwiftUI

struct ButtonScreenView: View {
  @Environment(\.colorScheme) var cs

  let text: String
  let primaryBtnText: String
  let onPrimaryBtnTap: () -> Void
  let secondaryBtn: (text: String, onTap: () -> Void)?
  let tertiaryBtn: (text: String, onTap: () -> Void)?
  let listItems: [String]?
  let image: String?
  let screenType: ScreenType

  @State var showBg = false
  @State var iconOffset = Vector(0, -20)
  @State var textOffset = Vector(0, 20)
  @State var primaryButtonOffset = Vector(0, 20)
  @State var secondaryButtonOffset = Vector(0, 20)
  @State var tertiaryButtonOffset = Vector(0, 20)

  // for just one button
  init(
    text: String,
    buttonText: String,
    listItems: [String]? = nil,
    image: String? = nil,
    screenType: ScreenType = .info,
    onButtonTap: @escaping () -> Void
  ) {
    self.text = text
    self.primaryBtnText = buttonText
    self.screenType = screenType
    self.listItems = listItems
    self.image = image
    self.onPrimaryBtnTap = onButtonTap
    self.secondaryBtn = nil
    self.tertiaryBtn = nil
  }

  // for two buttons
  init(
    text: String,
    primaryButtonText: String,
    secondaryButtonText: String,
    listItems: [String]? = nil,
    image: String? = nil,
    screenType: ScreenType = .question,
    onPrimaryButtonTap: @escaping () -> Void,
    secondary onSecondaryButtonTap: @escaping () -> Void
  ) {
    self.text = text
    self.primaryBtnText = primaryButtonText
    self.listItems = listItems
    self.image = image
    self.screenType = screenType
    self.onPrimaryBtnTap = onPrimaryButtonTap
    self.secondaryBtn = (text: secondaryButtonText, onTap: onSecondaryButtonTap)
    self.tertiaryBtn = nil
  }

  // for three buttons
  init(
    text: String,
    primaryButtonText: String,
    secondaryButtonText: String,
    tertiaryButtonText: String,
    listItems: [String]? = nil,
    image: String? = nil,
    screenType: ScreenType = .question,
    onPrimaryButtonTap: @escaping () -> Void,
    secondary onSecondaryButtonTap: @escaping () -> Void,
    tertiary onTertiaryButtonTap: @escaping () -> Void
  ) {
    self.text = text
    self.primaryBtnText = primaryButtonText
    self.listItems = listItems
    self.image = image
    self.screenType = screenType
    self.onPrimaryBtnTap = onPrimaryButtonTap
    self.secondaryBtn = (text: secondaryButtonText, onTap: onSecondaryButtonTap)
    self.tertiaryBtn = (text: tertiaryButtonText, onTap: onTertiaryButtonTap)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Image(systemName: self.screenType == .info ? "info.circle" : "questionmark.circle")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
        .swooshIn(tracking: self.$iconOffset, to: .origin, after: .zero, for: .milliseconds(800))
        .frame(maxWidth: .infinity, alignment: .center)

      Spacer()

      if let image = self.image {
        Image(image)
          .frame(maxWidth: .infinity)
          .padding(.bottom, 20)
          .swooshIn(tracking: self.$textOffset, to: .origin, after: .zero, for: .milliseconds(800))
      }

      Text(self.text)
        .font(.system(size: 18, weight: .medium))
        .swooshIn(tracking: self.$textOffset, to: .origin, after: .zero, for: .milliseconds(800))

      if let listItems = self.listItems {
        VStack(alignment: .leading) {
          ForEach(listItems, id: \.self) { item in
            HStack(alignment: .top, spacing: 12) {
              Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .padding(.top, 7)
                .foregroundStyle(Color(cs, light: .violet500, dark: .violet400))
              Text(item)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(cs, light: .violet950, dark: .violet100))
                .opacity(0.8)
              Spacer()
            }
            .padding(.leading, 14)
          }
        }
        .padding(.bottom, 20)
        .swooshIn(tracking: self.$textOffset, to: .origin, after: .zero, for: .milliseconds(800))
      }

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

      if let (tertiaryText, tertiaryOnTap) = self.tertiaryBtn {
        BigButton(tertiaryText, variant: .secondary) {
          self.vanishingAnimations()
          delayed(by: .milliseconds(800)) {
            tertiaryOnTap()
          }
        }
        .swooshIn(
          tracking: self.$tertiaryButtonOffset,
          to: .origin,
          after: .milliseconds(450),
          for: .milliseconds(800)
        )
      }
    }
    .padding(30)
    .padding(.top, 50)
    .background(Gradient(colors: [
      Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
      .clear,
    ]))
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
      self.tertiaryButtonOffset.y = 20
    }

    delayed(by: .milliseconds(100)) {
      withAnimation {
        self.secondaryButtonOffset.y = 20
        self.showBg = false
      }
    }

    delayed(by: .milliseconds(200)) {
      withAnimation {
        self.primaryButtonOffset.y = 20
      }
    }

    delayed(by: .milliseconds(300)) {
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

#Preview("3 buttons") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primaryButtonText: "Do something",
    secondaryButtonText: "Do something else",
    tertiaryButtonText: "Do another thing"
  ) {} secondary: {} tertiary: {}
}

#Preview("list items (1 button)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit:",
    buttonText: "Next",
    listItems: ["Lorem ipsum dolor", "Sit amet consectetur adipiscing elit"]
  ) {}
}

#Preview("list items (2 buttons)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit:",
    primaryButtonText: "Do something",
    secondaryButtonText: "Do something else",
    listItems: [
      "Lorem ipsum dolor",
      "Sit amet consectetur adipiscing elit",
      "Jimmy Carter died recently and there was a national day of morning",
    ]
  ) {} secondary: {}
}

#Preview("list items (3 buttons)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primaryButtonText: "Do something",
    secondaryButtonText: "Do something else",
    tertiaryButtonText: "Do another thing",
    listItems: [
      "Lorem ipsum dolor",
      "Sit amet consectetur adipiscing elit",
      "Jimmy Carter died recently and there was a national day of morning",
    ]
  ) {} secondary: {} tertiary: {}
}

#Preview("with image") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    buttonText: "Next",
    image: "AllowContentFilter"
  ) {}
}
