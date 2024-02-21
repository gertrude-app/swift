import Foundation

class ClientUDS {
  private var socketDescriptor: Int32?
  private let socketPath: String

  init() {
    let filepath =
      "file:///Users/jared/Library/Group Containers/WFN83LM943.com.netrivet.gertrude.group"
    socketPath = URL(fileURLWithPath: filepath)
      .appendingPathComponent("gertrude.sock")
      .path
  }

  /// Attempts to connect to the Unix socket.
  func connect() {
    log("Attempting to connect to socket path: \(socketPath)")

    socketDescriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
    guard let socketDescriptor = socketDescriptor, socketDescriptor != -1 else {
      logError("Error creating socket")
      return
    }

    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    socketPath.withCString { ptr in
      withUnsafeMutablePointer(to: &address.sun_path.0) { dest in
        _ = strcpy(dest, ptr)
      }
    }

    log("File exists: \(FileManager.default.fileExists(atPath: socketPath))")

    if Darwin.connect(
      socketDescriptor,
      withUnsafePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
      },
      socklen_t(MemoryLayout<sockaddr_un>.size)
    ) == -1 {
      logError("Error connecting to socket - \(String(cString: strerror(errno)))")
      return
    }

    log("Successfully connected to socket")

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      self.log("about to read data (3)")
      self.readData()
      self.sendMsg("hello from App 1")
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
      self.log("about to read data (6)")
      self.readData()
      self.sendMsg("hello from App 2")
    }
  }

  /// Reads data from the connected socket.
  func readData() {
    DispatchQueue.global().async {
      while true {
        var buffer = [UInt8](repeating: 0, count: 1024)
        guard let socketDescriptor = self.socketDescriptor else {
          self.logError("Socket descriptor is nil")
          return
        }
        let bytesRead = read(socketDescriptor, &buffer, buffer.count)
        if bytesRead <= 0 {
          self.logError("Error reading from socket or connection closed")
          break // exit loop on error or closure of connection
        }

        // Print the data for debugging purposes
        let data = Data(buffer[..<bytesRead])
        self.log("Received data: \(data)")

        if let str = String(data: data, encoding: .utf8) {
          // Now you have converted the Data back to a string
          print("jared, string: \(str)")
        }
      }

      if let socketDescriptor = self.socketDescriptor {
        close(socketDescriptor)
      }
    }
  }

  func sendMsg(_ msg: String) {
    let data: Data = msg.data(using: .utf8)!
    guard let clientSocket = socketDescriptor else {
      log("[G•] No connected client.")
      return
    }

    if data.isEmpty {
      log("[G•] No data to send!")
      return
    }

    data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
      let pointer = bytes.bindMemory(to: UInt8.self)
      let bytesWritten = Darwin.send(clientSocket, pointer.baseAddress!, data.count, 0)

      if bytesWritten == -1 {
        logError("[G•] Error sending data")
        return
      }
      log("[G•] \(bytesWritten) bytes written")
    }
  }

  /// Logs a message.
  /// - Parameter message: The message to log.
  private func log(_ message: String) {
    print("jared: ClientUnixSocket: \(message)")
  }

  /// Logs an error message.
  /// - Parameter message: The error message to log.
  private func logError(_ message: String) {
    print("jared: ClientUnixSocket: [ERROR] \(message)")
  }
}
