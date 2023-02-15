import SwiftUI

struct TextItemView: View {
  var text: String
  var onClick: () -> Void
  var enabled: Bool
  var image: String?

  @State private var hovered = false

  var body: some View {
    HStack {
      if #available(macOS 11, *) {
        if let image = image {
          Image(systemName: image)
            .resizable()
            .scaledToFit()
            .frame(width: 14, height: 14)
            .opacity(enabled ? 1 : 0.5)
        }
      } else {
        EmptyView()
      }
      Text("\(text)...").foregroundColor(enabled ? .primary : .secondary)
      Spacer()
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 4)
    .background(Color(hex: 0x999999, alpha: hovered && enabled ? 1 : 0))
    .cornerRadius(4)
    .onHover { over in
      hovered = over
    }
    .onTapGesture {
      if enabled {
        hovered = false
        onClick()
      }
    }
  }
}
