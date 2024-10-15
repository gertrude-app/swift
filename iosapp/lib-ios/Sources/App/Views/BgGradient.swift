import SwiftUI

struct BgGradient: View {
  @State var t: CGFloat = 0
  @State var timer: Timer?

  var body: some View {
    if #available(iOS 18.0, *) {
      MeshGradient(
        width: 3,
        height: 4,
        points: [
          [0, 0], [0.5, 0], [1, 0],
          [0, 0.33], [Float(cos(self.t) / 2.5 + 0.5), Float(sin(2 * self.t) / 6 + 0.33)], [1, 0.5],
          [0, 0.66], [Float(-cos(self.t) / 2.5 + 0.5), Float(-sin(self.t) / 4 + 0.66)], [1, 0.5],
          [0, 1], [0.5, 1], [1, 1],
        ],
        colors: [
          fuchsia300, violet300, .white,
          .white, .white, fuchsia300,
          violet100, fuchsia300, violet300,
          fuchsia300, violet300, violet100,
        ],
        smoothsColors: true
      ).onAppear {
        self.startAnimation()
      }.onDisappear {
        self.stopAnimation()
      }
    } else {
      Rectangle().fill(Gradient(colors: [.white, violet300]))
    }
  }

  private func startAnimation() {
    self.timer = Timer.scheduledTimer(
      withTimeInterval: 0.016,
      repeats: true
    ) { _ in
      withAnimation(.linear(duration: 0.016)) {
        self.t += 0.005
      }
    }
  }

  private func stopAnimation() {
    self.timer?.invalidate()
    self.timer = nil
  }
}
