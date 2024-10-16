public func decideFlow(hostname: String?, url: String?, sourceId: String?) -> Bool {
  if sourceId?.contains("HashtagImagesExtension") == true {
    return false
  } else if sourceId?.contains("com.apple.Spotlight") == true {
    return false
  } else if sourceId?.contains(".com.apple.photoanalysisd") == true {
    return false
  }

  if url?.contains("tenor.co") == true {
    return false
  }

  if let target = url ?? hostname {
    if target.contains("cdn2.smoot.apple.com") {
      return false
    } else if target.contains("tenor.co") {
      return false
    } else if target.contains("giphy.com") {
      return false
    } else if target.contains("media.fosu2-1.fna.whatsapp.net") {
      return false
    } else if sourceId?.contains(".com.apple.MobileSMS") == true {
      if target.contains("amp-api-edge.apps.apple.com") {
        return false
      } else if target.contains("is1-ssl.mzstatic.com") {
        return false
      }
    }
  }
  return true
}
