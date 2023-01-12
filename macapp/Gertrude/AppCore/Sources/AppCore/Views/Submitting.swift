import SwiftUI

struct Submitting: View {
  var text: String

  init(_ text: String = "Submitting...") {
    self.text = text
  }

  var body: some View {
    HStack(spacing: 2) {
      ProgressView()
        .scaleEffect(0.65, anchor: .center)
      Text(text)
        .foregroundColor(.secondary)
        .italic()
    }
    .padding(right: 4)
  }
}

struct Submitting_Previews: PreviewProvider {
  static var previews: some View {
    Submitting().colorSchemeBg(.light)
    Submitting().colorSchemeBg(.dark)
    Submitting("Connecting...").colorSchemeBg(.light)
  }
}
