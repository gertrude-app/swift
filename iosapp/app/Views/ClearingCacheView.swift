import Foundation
import SwiftUI

struct ClearingCacheView: View {
  struct Sparkle: Identifiable {
    var id: UUID
    var position: Vector
    var velocity: Vector

    mutating func update() {
      self.position += self.velocity
    }

    init(position: Vector, velocity: Vector) {
      self.id = UUID()
      self.position = position
      self.velocity = velocity
    }
  }

  @Environment(\.colorScheme) var cs
  @State var sparkles = [Sparkle]()
  @State var timer: Timer?

  @State var spinnerOffset = Vector(x: 0, y: 20)
  @State var titleOffset = Vector(x: 0, y: 20)
  @State var subtitleOffset = Vector(x: 0, y: 20)
  @State var amountClearedOffset = Vector(x: 0, y: 20)
  @State var showBg = false

  var body: some View {
    ZStack {
      Rectangle()
        .fill(Gradient(colors: [.clear, Color(self.cs, light: .violet300, dark: .violet950)]))
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation {
            self.showBg = true
          }
        }
      Group {
        ForEach(self.$sparkles) { $sparkle in
          Circle()
            .frame(width: 3, height: 3)
            .foregroundStyle(Color.violet500)
            .blur(radius: 3)
            .position(x: sparkle.position.x, y: sparkle.position.y)
        }
      }
      .opacity(self.showBg ? 1 : 0)
      .ignoresSafeArea()

      VStack(spacing: 0) {
        ProgressView()
          .swooshIn(
            tracking: self.$spinnerOffset,
            to: .zero,
            after: .seconds(0.2),
            for: .seconds(0.5)
          )

        Text("Clearing cache...")
          .font(.system(size: 24, weight: .medium))
          .padding(.top, 16)
          .swooshIn(
            tracking: self.$titleOffset,
            to: .zero,
            after: .seconds(0.3),
            for: .seconds(0.5)
          )

        Text("This may take a little while.")
          .padding(.top, 6)
          .font(.system(size: 18, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.7), dark: .white.opacity(0.7)))
          .swooshIn(
            tracking: self.$subtitleOffset,
            to: .zero,
            after: .seconds(0.4),
            for: .seconds(0.5)
          )

        Text("243.3 MB cleared") // TODO: this will change as cache is cleared
          .font(.system(size: 18, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.4), dark: .white.opacity(0.4)))
          .padding(.top, 20)
          .swooshIn(
            tracking: self.$amountClearedOffset,
            to: .zero,
            after: .seconds(0.5),
            for: .seconds(0.5)
          )
      }
    }
    .onAppear {
      for _ in 0 ..< 30 {
        self.sparkles.append(Sparkle(
          position: Vector(
            x: Double.random(in: 0 ... UIScreen.main.bounds.width),
            y: Double.random(in: 0 ... UIScreen.main.bounds.height)
          ),
          velocity: Vector(
            x: Double.random(in: -1 ... 1),
            y: Double.random(in: -1 ... 1)
          )
        ))
      }
      self.animate()
    }
    .onDisappear {
      self.stopAnimation()
    }
  }

  func animate() {
    self.timer = Timer.scheduledTimer(
      withTimeInterval: 0.016,
      repeats: true
    ) { _ in
      for index in self.sparkles.indices {
        self.sparkles[index].update()
        if self.sparkles[index].position.y > UIScreen.main.bounds.height + 10 {
          self.sparkles[index].position.y = -10
        }
        if self.sparkles[index].position.y < -10 {
          self.sparkles[index].position.y = UIScreen.main.bounds.height + 10
        }
        if self.sparkles[index].position.x > UIScreen.main.bounds.width + 10 {
          self.sparkles[index].position.x = -10
        }
        if self.sparkles[index].position.x < -10 {
          self.sparkles[index].position.x = UIScreen.main.bounds.width + 10
        }
      }
    }
  }

  func stopAnimation() {
    self.timer?.invalidate()
    self.timer = nil
  }
}

#Preview {
  ClearingCacheView()
}
