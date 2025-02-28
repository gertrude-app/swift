import SwiftUI

struct BigButton: View {
  @Environment(\.colorScheme) var cs

  var text: String
  var type: ButtonType
  var variant: Variant
  var icon: String?
  var disabled: Bool

  var label: some View {
    HStack {
      Spacer()
      Text(self.text)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(
          self.variant == .primary
            ? Color(self.cs, light: .white, dark: .white)
            : Color(self.cs, light: .violet500, dark: .violet400)
        )
      if let icon = self.icon {
        Image(systemName: icon)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(
            self.variant == .primary
              ? Color(self.cs, light: .white, dark: .white)
              : Color(self.cs, light: .violet500, dark: .violet400)
          )
      }
      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .background(
      self.variant == .primary
        ? Color(
          self.cs,
          light: .violet500,
          dark:
            .violet600.opacity(0.9)
        )
        : Color(
          self.cs,
          light: .violet500.opacity(0.1),
          dark:
            .violet500.opacity(0.15)
        )
    )
    .cornerRadius(16)
    .opacity(self.disabled ? 0.5 : 1)
  }

  var body: some View {
    switch self.type {
    case .button(let onTap):
      Button {
        if !self.disabled {
          onTap()
        }
      } label: {
        self.label
      }
    case .link(let url):
      Link(destination: url) {
        self.label
      }
    case .share(let text):
      ShareLink(item: text) {
        self.label
      }
    }
  }

  init(
    _ text: String,
    type: ButtonType,
    variant: Variant,
    icon: String? = nil,
    disabled: Bool = false
  ) {
    self.text = text
    self.type = type
    self.variant = variant
    self.icon = icon
    self.disabled = disabled
  }

  enum Variant {
    case primary
    case secondary
  }

  enum ButtonType {
    case button(() -> Void)
    case link(URL)
    case share(String)
  }
}

#Preview(".button") {
  VStack(spacing: 20) {
    BigButton("Click me", type: .button {}, variant: .primary)
    BigButton("Click me", type: .button {}, variant: .secondary)
    BigButton("Click me", type: .button {}, variant: .primary, icon: "plus")
    BigButton("Click me", type: .button {}, variant: .secondary, icon: "plus")
  }
  .padding(20)
}

#Preview(".button (disabled)") {
  VStack(spacing: 20) {
    BigButton("Click me", type: .button {}, variant: .primary, disabled: true)
    BigButton("Click me", type: .button {}, variant: .secondary, disabled: true)
    BigButton("Click me", type: .button {}, variant: .primary, icon: "plus", disabled: true)
    BigButton("Click me", type: .button {}, variant: .secondary, icon: "plus", disabled: true)
  }
  .padding(20)
}

#Preview(".link") {
  VStack(spacing: 20) {
    BigButton("Click me", type: .link(URL(string: "https://gertrude.app")!), variant: .primary)
    BigButton("Click me", type: .link(URL(string: "https://gertrude.app")!), variant: .secondary)
    BigButton(
      "Click me",
      type: .link(URL(string: "https://gertrude.app")!),
      variant: .primary,
      icon: "plus"
    )
    BigButton(
      "Click me",
      type: .link(URL(string: "https://gertrude.app")!),
      variant: .secondary,
      icon: "plus"
    )
  }
  .padding(20)
}

#Preview(".share") {
  VStack(spacing: 20) {
    BigButton("Click me", type: .share("Foo"), variant: .primary)
    BigButton("Click me", type: .share("Foo"), variant: .secondary)
    BigButton("Click me", type: .share("Foo"), variant: .primary, icon: "plus")
    BigButton("Click me", type: .share("Foo"), variant: .secondary, icon: "plus")
  }
  .padding(20)
}
