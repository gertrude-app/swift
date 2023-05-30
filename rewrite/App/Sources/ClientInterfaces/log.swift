import os.log

public func unexpectedError(id: String, _ error: Error? = nil) {
  os_log(
    "[G•] unexpected error %{public}s %{public}s",
    id,
    error.map { String(describing: $0) } ?? ""
  )
}
