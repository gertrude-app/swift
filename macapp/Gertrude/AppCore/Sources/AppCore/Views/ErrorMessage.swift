import SwiftUI

struct ErrorMessage: View, ColorSchemeView {
  var msg: String

  @Environment(\.colorScheme) var colorScheme

  init(_ msg: String) {
    self.msg = msg
  }

  var body: some View {
    VStack {
      HStack {
        Image(systemName: "xmark.octagon.fill")
          .resizable()
          .frame(width: 15, height: 15)
          .foregroundColor(red)
        Text("Sorry, an error occurred.")
      }
      Text(msg)
        .foregroundColor(red)
        .bold()
        .padding(top: 10, right: 30, bottom: 0, left: 30)
    }
  }
}

struct ErrorMessage_Previews: PreviewProvider {
  static var previews: some View {
    ErrorMessage(
      "It looks like the Gertrude API is having problems. Try again in a few minutes, or contact support for more help."
    )
    .adminPreview()
    .colorSchemeBg(.light)
    ErrorMessage("Failed to fetch")
      .adminPreview()
      .colorSchemeBg(.dark)
    ErrorMessage("Failed to fetch")
      .adminPreview()
      .colorSchemeBg(.light)
  }
}
