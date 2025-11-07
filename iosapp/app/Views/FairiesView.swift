import SwiftUI

struct FairiesView: View {
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
  @State private var sparkles = [Sparkle]()
  @State private var timer: Timer?

  var body: some View {
    ZStack {
      Rectangle()
        .fill(Gradient(colors: [.clear, Color(self.cs, light: .violet300, dark: .violet950)]))
        .ignoresSafeArea()
      Group {
        ForEach(self.$sparkles) { $sparkle in
          Circle()
            .frame(width: 3, height: 3)
            .foregroundStyle(Color.violet500)
            .blur(radius: 3)
            .position(x: sparkle.position.x, y: sparkle.position.y)
        }
      }
      .ignoresSafeArea()
    }
    .onAppear {
      for _ in 0 ..< 30 {
        self.sparkles.append(Sparkle(
          position: Vector(
            x: Double.random(in: 0 ... UIScreen.main.bounds.width),
            y: Double.random(in: 0 ... UIScreen.main.bounds.height),
          ),
          velocity: Vector(
            x: Double.random(in: -1 ... 1),
            y: Double.random(in: -1 ... 1),
          ),
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
      repeats: true,
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
  FairiesView()
}
