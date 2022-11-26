public extension Int {
  var daysAgo: Date {
    Date(subtractingDays: self)
  }

  var daysFromNow: Date {
    Date(addingDays: self)
  }
}
