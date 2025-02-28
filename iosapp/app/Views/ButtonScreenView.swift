import SwiftUI

struct ButtonScreenView: View {
  @Environment(\.colorScheme) var cs

  struct Config {
    var text: String
    var type: BigButton.ButtonType
    var animate: Bool

    init(text: String, type: BigButton.ButtonType, animate: Bool = true) {
      self.text = text
      self.type = type
      self.animate = animate
    }

    init(_ text: String, animate: Bool = true, _ action: @escaping () -> Void) {
      self.init(text: text, type: .button(action), animate: animate)
    }
  }

  let text: String
  let primaryBtn: Config?
  let secondaryBtn: Config?
  let tertiaryBtn: Config?
  let primaryLooksLikeSecondary: Bool
  let listItems: [String]?
  let image: String?
  let screenType: ScreenType

  @State private var showBg = false
  @State private var iconOffset = Vector(x: 0, y: -20)
  @State private var textOffset = Vector(x: 0, y: 20)
  @State private var primaryButtonOffset = Vector(x: 0, y: 20)
  @State private var secondaryButtonOffset = Vector(x: 0, y: 20)
  @State private var tertiaryButtonOffset = Vector(x: 0, y: 20)

  var icon: String {
    switch self.screenType {
    case .info: return "info.circle"
    case .question: return "questionmark.circle"
    case .error: return "exclamationmark.circle"
    }
  }

  init(
    text: String,
    primary: Config? = nil,
    secondary: Config? = nil,
    tertiary: Config? = nil,
    listItems: [String]? = nil,
    image: String? = nil,
    screenType: ScreenType = .info,
    primaryLooksLikeSecondary: Bool = false
  ) {
    self.text = text
    self.screenType = screenType
    self.listItems = listItems
    self.image = image
    self.primaryBtn = primary
    self.secondaryBtn = secondary
    self.tertiaryBtn = tertiary
    self.primaryLooksLikeSecondary = primaryLooksLikeSecondary
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(Gradient(colors: [
          Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
          .clear,
        ]))
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.7)) {
            self.showBg = true
          }
        }

      VStack(alignment: .leading, spacing: 16) {
        Image(systemName: self.icon)
          .font(.system(size: 40, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .swooshIn(tracking: self.$iconOffset, to: .zero, after: .zero, for: .milliseconds(800))
          .frame(maxWidth: .infinity, alignment: .center)

        Spacer()

        if let image = self.image {
          Image(image)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
            .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))
        }

        Text(self.text)
          .font(.system(size: 18, weight: .medium))
          .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))

        if let listItems = self.listItems {
          VStack(alignment: .leading) {
            ForEach(listItems, id: \.self) { item in
              HStack(alignment: .top, spacing: 12) {
                Image(systemName: "circle.fill")
                  .font(.system(size: 6))
                  .padding(.top, 7)
                  .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
                Text(item)
                  .font(.system(size: 16, weight: .medium))
                  .foregroundStyle(Color(self.cs, light: .violet950, dark: .violet100))
                  .opacity(0.8)
                Spacer()
              }
              .padding(.leading, 14)
            }
          }
          .padding(.bottom, 20)
          .swooshIn(tracking: self.$textOffset, to: .zero, after: .zero, for: .milliseconds(800))
        }

        if let config = self.primaryBtn {
          BigButton(
            config.text,
            type: self.withOrWithoutVanishingAnimations(type: config.type, animate: config.animate),
            variant: self.primaryLooksLikeSecondary ? .secondary : .primary
          )
          .swooshIn(
            tracking: self.$primaryButtonOffset,
            to: .zero,
            after: .milliseconds(150),
            for: .milliseconds(800)
          )
          .padding(.top, 12)
        }

        if let config = self.secondaryBtn {
          BigButton(
            config.text,
            type: self.withOrWithoutVanishingAnimations(type: config.type, animate: config.animate),
            variant: .secondary
          )
          .swooshIn(
            tracking: self.$secondaryButtonOffset,
            to: .zero,
            after: .milliseconds(300),
            for: .milliseconds(800)
          )
        }

        if let config = self.tertiaryBtn {
          BigButton(
            config.text,
            type: self.withOrWithoutVanishingAnimations(type: config.type, animate: config.animate),
            variant: .secondary
          )
          .swooshIn(
            tracking: self.$tertiaryButtonOffset,
            to: .zero,
            after: .milliseconds(450),
            for: .milliseconds(800)
          )
        }
      }
      .frame(maxWidth: 500)
      .padding(30)
      .padding(.top, 50)
    }
  }

  func withOrWithoutVanishingAnimations(type: BigButton.ButtonType, animate: Bool) -> BigButton
    .ButtonType {
    switch type {
    case .link(let url):
      .link(url)
    case .share(let string):
      .share(string)
    case .button(let onTap):
      .button {
        if animate {
          self.vanishingAnimations()
          delayed(by: .milliseconds(800)) {
            onTap()
          }
        } else {
          onTap()
        }
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
    case error
  }
}

#Preview("No button") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    screenType: .error
  )
}

#Preview("1 button") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Next", type: .button {}, animate: true)
  )
}

#Preview("2 buttons") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true)
  )
}

#Preview("2 buttons (both secondary)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true),
    primaryLooksLikeSecondary: true
  )
}

#Preview("3 buttons") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true),
    tertiary: ButtonScreenView.Config(text: "Do another thing", type: .button {}, animate: true)
  )
}

#Preview("list items (1 button)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit:",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    listItems: ["Lorem ipsum dolor", "Sit amet consectetur adipiscing elit"]
  )
}

#Preview("list items (2 buttons)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit:",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true),
    listItems: [
      "Lorem ipsum dolor",
      "Sit amet consectetur adipiscing elit",
      "Jimmy Carter died recently and there was a national day of morning",
    ]
  )
}

#Preview("list items (3 buttons)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    secondary: ButtonScreenView.Config(text: "Do something else", type: .button {}, animate: true),
    tertiary: ButtonScreenView.Config(text: "Do another thing", type: .button {}, animate: true),
    listItems: [
      "Lorem ipsum dolor",
      "Sit amet consectetur adipiscing elit",
      "Jimmy Carter died recently and there was a national day of morning",
    ]
  )
}

#Preview("with image") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ButtonScreenView.Config(text: "Do something", type: .button {}, animate: true),
    image: "AllowContentFilter"
  )
}
