import SwiftUI

struct AdminWindowSubScreen<Content>: View where Content: View {
  var section: AdminScreenSection
  @ViewBuilder var content: () -> Content

  var imageDims: (width: CGFloat, height: CGFloat) {
    switch section {
    case .healthCheck:
      return (width: 19, height: 19)
    case .actions:
      return (width: 19, height: 19)
    case .exemptUsers:
      return (width: 29, height: 19)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top, spacing: 9) {
        Image(systemName: section.systemImage)
          .resizable()
          .frame(width: imageDims.width, height: imageDims.height)
          .foregroundColor(.purple)
          .offset(y: 4)
        Text(section.rawValue)
          .font(.title)
          .bold()
          .opacity(0.85)
          .padding(bottom: 12)
      }
      content()
    }
    .padding(20)
  }
}
