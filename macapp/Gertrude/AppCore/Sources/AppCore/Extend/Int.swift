extension Int {
  var futureHumanTime: String? {
    switch self {
    case ...0:
      return nil
    case 1 ..< 45:
      return "less than a minute from now"
    case 45 ..< 85:
      return "about a minute from now"
    case 85 ..< 100:
      return "about 90 seconds from now"
    case 100 ..< 120:
      return "about 2 minutes from now"
    case 120 ..< 3000:
      return "\(self / 60) minutes from now"
    case 3000 ..< 4200:
      return "about an hour from now"
    case 4200 ..< 7200:
      return "1 hour \((self - 3600) / 60) minutes from now"
    case 7200 ..< 172800:
      return "about \(self / 3600) hours from now"
    default:
      return "\(self / 86400) days from now"
    }
  }
}
