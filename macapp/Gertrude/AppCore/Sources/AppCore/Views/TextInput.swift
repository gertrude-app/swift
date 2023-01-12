import SwiftUI

struct TextInput: View, ColorSchemeView {
  @Binding var text: String

  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    ZStack(alignment: .trailing) {
      TextField("", text: $text)
        .foregroundColor(.primary)
        .padding(x: 8)
        .frame(height: 26)
        .textFieldStyle(PlainTextFieldStyle())
        .padding(x: 4)
        .background(Color(hex: darkMode ? 0x555555 : 0xFFFFFF))
        .cornerRadius(10)
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(Color(hex: darkMode ? 0x333333 : 0xCCCCCC))
        )
      Group {
        Image(systemName: "xmark.circle")
      }
      .opacity(text.isEmpty ? 0 : 0.65)
      .padding(x: 5, y: 5)
      .onTapGesture {
        text = ""
      }
    }
  }
}

struct TextInput_Previews: PreviewProvider {
  static var previews: some View {
    TextInput(text: .mock("search text"))
      .colorSchemeBg(.light)
      .padding()
      .background(Color(hex: 0xEEEEEE))
      .frame(width: 500, height: 75)
    TextInput(text: .mock("search text"))
      .padding()
      .frame(width: 500, height: 75)
      .colorSchemeBg(.dark)
  }
}
