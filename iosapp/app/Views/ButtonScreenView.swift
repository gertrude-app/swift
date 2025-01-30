import SwiftUI

struct ButtonScreenView: View {
  let text: String
  let primaryBtnText: String
  let onPrimaryBtnTap: () -> Void
  
  init(text: String, buttonText: String, onButtonTap: @escaping () -> Void) {
    self.text = text
    self.primaryBtnText = buttonText
    self.onPrimaryBtnTap = onButtonTap
  }
  
  @State var showBg = false
  @State var iconOffset = Vector(0, -20)
  @State var textOffset = Vector(0, 20)
  @State var buttonOffset = Vector(0, 20)
  
  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "info.circle")
        .font(.system(size: 40, weight: .regular))
        .foregroundStyle(Color.violet500)
        .swooshIn(tracking: $iconOffset, to: .origin, after: .zero, for: .milliseconds(800))
      
      Spacer()
      
      Text("The setup usually takes about 5-8 minutes, but in some cases extra steps are required.")
        .font(.system(size: 18, weight: .medium))
        .multilineTextAlignment(.center)
        .swooshIn(tracking: $textOffset, to: .origin, after: .zero, for: .milliseconds(800))
      
      BigButton("Next", variant: .primary) {
        self.vanishingAnimations()
        delayed(by: .milliseconds(800)) {
          self.onPrimaryBtnTap()
        }
      }
        .swooshIn(tracking: $buttonOffset, to: .origin, after: .milliseconds(150), for: .milliseconds(800))
    }
    .padding(30)
    .padding(.top, 50)
    .background(Gradient(colors: [.violet200, .white]))
    .opacity(showBg ? 1 : 0)
    .onAppear {
      withAnimation(.smooth(duration: 0.7)) {
        self.showBg = true
      }
    }
  }
  
  func vanishingAnimations() {
    withAnimation {
      self.iconOffset.y = -20
      self.buttonOffset.y = 20
    }
    
    delayed(by: .milliseconds(100)) {
      withAnimation {
        self.textOffset.y = 20
        self.showBg = false
      }
    }
  }
}

#Preview {
  ButtonScreenView(text: "Lorem ipsum dolor sit amet consectetur", buttonText: "Next") {}
}
