import Foundation
import SwiftUI

func delayed(by delay: Duration, _ callback: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(deadline: .now() + delay.inMilliseconds / 1000) {
    callback()
  }
}

extension Duration {
  var inMilliseconds: Double {
    let v = components
    return Double(v.seconds) * 1000 + Double(v.attoseconds) * 1e-15
  }
}

struct Vector: Equatable, Identifiable, AdditiveArithmetic {
  var x: Double
  var y: Double
  var id: UUID

  var magnitude: Double {
    sqrt(self.x * self.x + self.y * self.y)
  }

  var isOrigin: Bool {
    self.x == 0 && self.y == 0
  }

  var normalized: Vector {
    self.scaledBy(1 / self.magnitude)
  }

  func scaledBy(_ scalar: Double) -> Vector {
    .init(x: self.x * scalar, y: self.y * scalar)
  }

  static var zero: Vector {
    .init(x: 0, y: 0)
  }

  static func - (lhs: Vector, rhs: Vector) -> Vector {
    .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
  }

  static func + (lhs: Vector, rhs: Vector) -> Vector {
    .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }

  static func += (lhs: inout Vector, rhs: Vector) {
    lhs = lhs + rhs
  }

  init(x: Double, y: Double) {
    self.x = x
    self.y = y
    self.id = UUID()
  }
}

extension View {
  func offset(_ offset: Vector) -> some View {
    self.offset(x: offset.x, y: offset.y)
  }
}

struct SwooshIn: ViewModifier {
  @Binding var vec: Vector
  let destination: Vector
  let delay: Duration
  let duration: Duration
  let animation: AnimationType

  var isDone: Bool {
    self.vec.x == self.destination.x && self.vec.y == self.destination.y
  }

  func body(content: Content) -> some View {
    content
      .offset(self.vec)
      .opacity(self.isDone ? 1 : 0)
      .blur(radius: self.isDone ? 0 : 10)
      .onAppear {
        delayed(by: self.delay) {
          withAnimation(self.animation == .bouncy ? .bouncy(
            duration: self.duration.inMilliseconds / 1000,
            extraBounce: 0.3
          ) : .smooth(duration: self.duration.inMilliseconds / 1000)) {
            self.vec.x = self.destination.x
            self.vec.y = self.destination.y
          }
        }
      }
  }

  enum AnimationType {
    case bouncy
    case smooth
  }
}

extension View {
  func deviceType() -> UIUserInterfaceIdiom {
    UIDevice.current.userInterfaceIdiom
  }

  func swooshIn(
    tracking vec: Binding<Vector>,
    to destination: Vector,
    after delay: Duration,
    for duration: Duration,
    via animation: SwooshIn.AnimationType = .bouncy
  ) -> some View {
    self.modifier(SwooshIn(
      vec: vec,
      destination: destination,
      delay: delay,
      duration: duration,
      animation: animation
    ))
  }
}
