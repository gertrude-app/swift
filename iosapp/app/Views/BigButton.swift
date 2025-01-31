import SwiftUI

struct BigButton: View {
  @Environment(\.colorScheme) var cs
  
  var text: String
  var icon: String?
  var variant: Variant
  var onTap: () -> Void
  
  var body: some View {
    Button {
      self.onTap()
    } label: {
      HStack {
        Spacer()
        Text(self.text)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(self.variant == .primary ? Color(cs, light: .white, dark: .white) : Color(cs, light: .violet500, dark: .violet400))
        if self.icon != nil {
          Image(systemName: self.icon!)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(self.variant == .primary ? Color(cs, light: .white, dark: .white) : Color(cs, light: .violet500, dark: .violet400))
        }
        Spacer()
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 14)
      .background(self.variant == .primary ? Color(cs, light: .violet500, dark: .violet500) : Color(cs, light: .violet500.opacity(0.1), dark: .violet500.opacity(0.15)))
      .cornerRadius(16)
    }
  }
  
  init(_ text: String, variant: Variant, icon: String? = nil, onTap: @escaping () -> Void) {
    self.text = text
    self.variant = variant
    self.icon = icon
    self.onTap = onTap
  }
  
  enum Variant {
    case primary
    case secondary
  }
}

#Preview {
  VStack(spacing: 20) {
    BigButton("Click me", variant: .primary) {}
    BigButton("Click me", variant: .secondary) {}
    BigButton("Click me", variant: .primary, icon: "plus") {}
    BigButton("Click me", variant: .secondary, icon: "plus") {}
  }
  .padding(20)
}
