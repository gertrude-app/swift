import SwiftUI

struct PrimaryButton: View {
  var onClick: () -> Void
  var text: String

  @State private var tapping = false

  var body: some View {
    Button {
      let impact = UIImpactFeedbackGenerator(style: .medium)
      impact.impactOccurred()
    } label: {
      ZStack {
        VStack {
          Rectangle()
            .fill(Gradient(colors: [violet400, violet500]))
          Spacer()
          Spacer()
          HStack {
            Spacer()
          }
          Spacer()
          Spacer()
          Rectangle()
            .fill(Gradient(colors: [violet500, violet700]))
        }
        .background(violet500)
        .cornerRadius(20)
        VStack {
          Spacer()
          HStack {
            Spacer()
            Text(self.text)
              .font(.system(size: 20, weight: .bold))
            Image(systemName: "arrow.right")
              .resizable()
              .frame(width: 16, height: 16)
            Spacer()
          }
          Spacer()
        }
        .background(Gradient(colors: [violet500, violet600]))
        .foregroundColor(.white)
        .cornerRadius(20)
        .padding(.vertical, 2.5)
        .padding(.horizontal, 0.5)
      }
      .frame(height: 64)
      .padding(.horizontal, 40)
      .scaleEffect(self.tapping ? 0.95 : 1)
    }
    .onLongPressGesture(minimumDuration: 0) {} onPressingChanged: { inProgress in
      withAnimation(.bouncy(duration: 0.3, extraBounce: 0.4)) {
        self.tapping = inProgress
      }
      if !inProgress {
        self.onClick()
      }
    }
  }

  init(text: String, onClick: @escaping () -> Void) {
    self.text = text
    self.onClick = onClick
  }
}
