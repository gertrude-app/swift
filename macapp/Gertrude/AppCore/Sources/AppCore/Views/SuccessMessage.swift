import SwiftUI

struct SuccessMessage: View, ColorSchemeView {
  var msg: String?

  @Environment(\.colorScheme) var colorScheme

  init(_ msg: String? = nil) {
    self.msg = msg
  }

  var body: some View {
    HStack {
      Image(systemName: "checkmark.circle.fill")
        .resizable()
        .frame(width: 15, height: 15)
        .foregroundColor(green)
      Text(msg ?? "Success!")
    }
  }
}

struct SuccessMessage_Previews: PreviewProvider {
  static var previews: some View {
    SuccessMessage("Submitted successfully")
      .adminPreview()
      .colorSchemeBg(.light)
    SuccessMessage("Submitted successfully")
      .adminPreview()
      .colorSchemeBg(.dark)
  }
}
