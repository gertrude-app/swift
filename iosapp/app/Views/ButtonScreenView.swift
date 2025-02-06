import SwiftUI

struct ButtonScreenView: View {
  @Environment(\.colorScheme) var cs

  typealias ButtonConfig = (text: String, type: BigButton.ButtonType, true: Bool)

  let text: String
  let primaryBtn: ButtonConfig?
  let secondaryBtn: ButtonConfig?
  let tertiaryBtn: ButtonConfig?
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
    primary: ButtonConfig? = nil,
    secondary: ButtonConfig? = nil,
    tertiary: ButtonConfig? = nil,
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

        if let (text, type, animate) = self.primaryBtn {
          BigButton(
            text,
            type: self.withOrWithoutVanishingAnimations(type: type, animate: animate),
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

        if let (text, type, animate) = self.secondaryBtn {
          BigButton(
            text,
            type: self.withOrWithoutVanishingAnimations(type: type, animate: animate),
            variant: .secondary
          )
          .swooshIn(
            tracking: self.$secondaryButtonOffset,
            to: .zero,
            after: .milliseconds(300),
            for: .milliseconds(800)
          )
        }

        if let (text, type, animate) = self.tertiaryBtn {
          BigButton(
            text,
            type: self.withOrWithoutVanishingAnimations(type: type, animate: animate),
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
    primary: ("Next", .button {}, true)
  )
}

#Preview("2 buttons") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ("Do something", .button {}, true),
    secondary: ("Do something else", .button {}, true)
  )
}

#Preview("2 buttons (both secondary)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ("Do something", .button {}, true),
    secondary: ("Do something else", .button {}, true),
    primaryLooksLikeSecondary: true
  )
}

#Preview("3 buttons") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit.",
    primary: ("Do something", .button {}, true),
    secondary: ("Do something else", .button {}, true),
    tertiary: ("Do another thing", .button {}, true)
  )
}

#Preview("list items (1 button)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit:",
    primary: ("Do something", .button {}, true),
    listItems: ["Lorem ipsum dolor", "Sit amet consectetur adipiscing elit"]
  )
}

#Preview("list items (2 buttons)") {
  ButtonScreenView(
    text: "Lorem ipsum dolor sit amet consectetur adipiscing elit:",
    primary: ("Do something", .button {}, true),
    secondary: ("Do something else", .button {}, true),
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
    primary: ("Do something", .button {}, true),
    secondary: ("Do something else", .button {}, true),
    tertiary: ("Do another thing", .button {}, true),
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
    primary: ("Do something", .button {}, true),
    image: "AllowContentFilter"
  )
}
