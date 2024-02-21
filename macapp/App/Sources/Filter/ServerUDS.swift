import Foundation
import os.log

public class ServerUDS {
  private var socket: Int32?
  private var clientSocket: Int32?
  private let socketPath: String

  init() {
    let filepath =
      "file:///Users/jared/Library/Group Containers/WFN83LM943.com.netrivet.gertrude.group"
    socketPath = URL(fileURLWithPath: filepath)
      .appendingPathComponent("gertrude.sock")
      .path
  }

  /// Starts the server and begins listening for connections.
  func startBroadcasting() {
    createSocket()
    bindSocket()
    listenOnSocket()
    waitForConnection()
  }

  /// Creates a socket for communication.
  private func createSocket() {
    socket = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
    guard socket != nil, socket != -1 else {
      os_log("[G•] Error creating socket")
      return
    }
    os_log("[G•] Socket created successfully")
  }

  /// Binds the created socket to a specific address.
  private func bindSocket() {
    guard let socket = socket else { return }

    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    socketPath.withCString { ptr in
      withUnsafeMutablePointer(to: &address.sun_path.0) { dest in
        _ = strcpy(dest, ptr)
      }
    }

    unlink(socketPath) // Remove any existing socket file

    if Darwin.bind(
      socket,
      withUnsafePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
      },
      socklen_t(MemoryLayout<sockaddr_un>.size)
    ) == -1 {
      os_log("[G•] Error binding socket - %{public}s", String(cString: strerror(errno)))
      return
    }
    os_log("[G•] Binding to socket path: %{public}s", socketPath)

    socketPath.withCString { ptr in
      withUnsafeMutablePointer(to: &address.sun_path.0) { dest in
        _ = chown(dest, 501, 20)
      }
    }
  }

  /// Listens for connections on the bound socket.
  private func listenOnSocket() {
    guard let socket = socket else { return }

    if Darwin.listen(socket, 1) == -1 {
      os_log("[G•] Error listening on socket - %{public}s", String(cString: strerror(errno)))
      return
    }
    os_log("[G•] Listening for connections...")
  }

  /// Waits for a connection and accepts it when available.
  private func waitForConnection() {
    DispatchQueue.global().async { [weak self] in
      self?.acceptConnection()
    }
  }

  /// Accepts a connection request from a client.
  private func acceptConnection() {
    guard let socket = socket else { return }

    var clientAddress = sockaddr_un()
    var clientAddressLen = socklen_t(MemoryLayout<sockaddr_un>.size)
    clientSocket = Darwin.accept(
      socket,
      withUnsafeMutablePointer(to: &clientAddress) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
      },
      &clientAddressLen
    )

    if clientSocket == -1 {
      os_log("[G•] Error accepting connection - %{public}s", String(cString: strerror(errno)))
      return
    }
    os_log("[G•] Connection accepted!")
  }

  /// Sends the provided data to the connected client.
  /// - Parameter data: The data to send.
  func sendData(_ data: Data) {
    guard let clientSocket = clientSocket else {
      os_log("[G•] No connected client.")
      return
    }

    if data.isEmpty {
      os_log("[G•] No data to send!")
      return
    }

    data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
      let pointer = bytes.bindMemory(to: UInt8.self)
      let bytesWritten = Darwin.send(clientSocket, pointer.baseAddress!, data.count, 0)

      if bytesWritten == -1 {
        os_log("[G•] Error sending data")
        return
      }
      os_log("[G•] %{public}d bytes written", bytesWritten)
    }
  }

  /// Reads data from the connected socket.
  func readData() {
    DispatchQueue.global().async {
      while true {
        var buffer = [UInt8](repeating: 0, count: 1024)
        guard let socketDescriptor = self.socket else {
          os_log("[G•] readData() err Socket descriptor is nil")
          return
        }
        let bytesRead = read(socketDescriptor, &buffer, buffer.count)
        if bytesRead <= 0 {
          os_log("[G•] readData() err reading from socket or closed %{public}d", bytesRead)
          break // exit loop on error or closure of connection
        }

        // Print the data for debugging purposes
        let data = Data(buffer[..<bytesRead])
        os_log("[G•] Received data: %{public}d", data.count)

        if let str = String(data: data, encoding: .utf8) {
          // Now you have converted the Data back to a string
          os_log("[G•] the string is: %{public}s", str)
        }
      }
    }
  }

  /// Stops the server and closes any open connections.
  func stopBroadcasting() {
    if let clientSocket = clientSocket {
      os_log("[G•] Closing client socket...")
      close(clientSocket)
    }
    if let socket = socket {
      os_log("[G•] Closing server socket...")
      close(socket)
    }
    unlink(socketPath)
    os_log("[G•] Broadcasting stopped.")
  }
}
