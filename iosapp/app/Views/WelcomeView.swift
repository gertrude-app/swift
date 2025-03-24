import SwiftUI

struct WelcomeView: View {
  let onPrimaryBtnTap: () -> Void

  let greeting = "Hi there!"

  @State private var showButton = false
  @State private var showBg = false
  @State private var lettersOffset = Array(repeating: Vector(x: 0, y: 40), count: "Hi there!".count)
  @State private var subtitleOffset = Vector(x: 0, y: 20)
  @State private var buttonOffset = Vector(x: 0, y: 20)

  @Environment(\.colorScheme) var cs

  var body: some View {
    ZStack {
      Background()
        .opacity(self.showBg ? 1 : 0)
        .scaleEffect(y: self.deviceType() == .pad ? 1 : (self.showBg ? 1 : 0))
        .offset(y: self.showBg ? 0 : -440)
        .ignoresSafeArea()
        .onAppear {
          withAnimation(.smooth(duration: 1)) {
            self.showBg = true
          }
        }
        .onDisappear {
          withAnimation(.smooth(duration: 1)) {
            self.showBg = false
          }
        }

      VStack(alignment: self.deviceType() == .pad ? .center : .leading, spacing: 12) {
        if self.deviceType() == .phone {
          Spacer()
        }

        HStack(spacing: 0) {
          ForEach(Array(self.greeting.enumerated()), id: \.offset) { index, char in
            Text(String(char))
              .font(.system(size: 50, weight: .black))
              .swooshIn(
                tracking: self.$lettersOffset[index],
                to: .zero,
                after: .seconds(Double(index) / 15.0 + 0.5),
                for: .milliseconds(600)
              )
          }
        }

        Text("Gertrude blocks unwanted stuff, like GIFs, from your device.")
          .font(.system(size: 16, weight: .medium))
          .multilineTextAlignment(self.deviceType() == .pad ? .center : .leading)
          .swooshIn(
            tracking: self.$subtitleOffset,
            to: .zero,
            after: .seconds(1.0),
            for: .milliseconds(800)
          )

        BigButton("Get started", type: .button {
          self.vanishingAnimations()
          delayed(by: .milliseconds(800)) {
            self.onPrimaryBtnTap()
          }
        }, variant: .primary)
          .swooshIn(
            tracking: self.$buttonOffset,
            to: .zero,
            after: .seconds(1.3),
            for: .milliseconds(800)
          )
          .padding(.top, 20)
      }
      .padding(30)
      .frame(maxWidth: 500)
    }
  }

  func vanishingAnimations() {
    withAnimation(.smooth(duration: 1)) {
      self.showBg = false
    }

    for (i, _) in self.lettersOffset.enumerated() {
      delayed(by: .milliseconds(200)) {
        withAnimation(.smooth(duration: 0.5)) {
          self.lettersOffset[i].y = 50
        }
      }
    }

    delayed(by: .milliseconds(100)) {
      withAnimation(.smooth(duration: 0.5)) {
        self.subtitleOffset.y = 50
      }
    }

    delayed(by: .zero) {
      withAnimation(.smooth(duration: 0.5)) {
        self.buttonOffset.y = 50
      }
    }
  }
}

struct Background: View {
  @Environment(\.colorScheme) var cs

  var body: some View {
    if #available(iOS 18.0, *) {
      MeshGradient(width: 3, height: 6, points: [
        .init(0, 0), .init(0.5, 0), .init(1, 0),
        .init(0, 0.25), .init(0.5, 0.25), .init(1, 0.25),
        .init(0, 0.12), .init(0.5, 0.2), .init(1, 0.5),
        .init(0, 0.70), .init(0.5, 0.7), .init(1, 0.8),
        .init(0, 0.85), .init(0.5, 0.85), .init(1, 0.8),
        .init(0, 1), .init(0.5, 1), .init(1, 1),
      ], colors: [
        Color(cs, light: .violet100, dark: .violet950.opacity(0.25)),
        Color(cs, light: .fuchsia300, dark: .fuchsia950.opacity(0.5)),
        Color(cs, light: .violet700, dark: .violet700.opacity(0.5)),
        Color(cs, light: .violet400, dark: .violet900.opacity(0.5)),
        Color(cs, light: .clear, dark: .violet950.opacity(0.25)),
        Color(cs, light: .fuchsia400, dark: .fuchsia950.opacity(0.5)),
        .clear, .clear, .clear,
        .clear, .clear, .clear,
        .clear, .clear, .clear,
        .clear, .clear, .clear,
      ], smoothsColors: true)
    } else {
      Rectangle()
        .fill(Gradient(colors: [Color(self.cs, light: .violet300, dark: .violet950), .clear]))
    }
  }
}

#Preview {
  WelcomeView {}
}
