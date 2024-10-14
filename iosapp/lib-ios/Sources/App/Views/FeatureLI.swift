import SwiftUI

struct FeatureLI: View {
  var title: String
  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: "checkmark")
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.white)
        .frame(width: 16, height: 16)
        .background(.green)
        .cornerRadius(8)
      Text(self.title)
        .font(.system(size: 16, weight: .regular))
        .foregroundColor(.black.opacity(0.7))
      Spacer()
    }
    .padding(.vertical, 8)
    .padding(.trailing, 8)
    .padding(.leading, 16)
    .background(.white)
    .cornerRadius(16)
    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
  }

  init(_ title: String) {
    self.title = title
  }
}
