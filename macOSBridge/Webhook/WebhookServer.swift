//
//  WebhookServer.swift
//  macOSBridge
//
//  Lightweight HTTP server for webhook-based HomeKit control
//

import Foundation
import Network

final class WebhookServer {

    static let shared = WebhookServer(port: defaultPort)

    static let defaultPort: UInt16 = 8423
    static let statusChangedNotification = Notification.Name("webhookStatusChangedNotification")
    static let enabledKey = "webhookServerEnabled"

    let port: UInt16

    enum State: Equatable {
        case stopped
        case running
        case error(String)
    }

    private(set) var state: State = .stopped {
        didSet {
            NotificationCenter.default.post(name: Self.statusChangedNotification, object: nil)
        }
    }

    private var listener: NWListener?
    private var actionEngine: ActionEngine?
    private let queue = DispatchQueue(label: "com.nickustinov.itsyhome.webhook", qos: .userInitiated)

    init(port: UInt16) {
        self.port = port
    }

    // MARK: - Configuration

    func configure(actionEngine: ActionEngine) {
        self.actionEngine = actionEngine
    }

    // MARK: - Lifecycle

    func startIfEnabled() {
        guard ProStatusCache.shared.isPro else { return }
        guard UserDefaults.standard.bool(forKey: Self.enabledKey) else { return }
        start()
    }

    func start() {
        guard listener == nil else { return }

        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            let listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            self.listener = listener

            listener.stateUpdateHandler = { [weak self] newState in
                guard let self else { return }
                switch newState {
                case .ready:
                    self.state = .running
                case .failed(let error):
                    self.state = .error(error.localizedDescription)
                    self.listener = nil
                case .cancelled:
                    self.state = .stopped
                default:
                    break
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            listener.start(queue: queue)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        state = .stopped
    }

    // MARK: - Connection handling

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)

        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, error in
            guard let self, let data, error == nil else {
                connection.cancel()
                return
            }

            guard let request = String(data: data, encoding: .utf8) else {
                self.sendResponse(connection: connection, status: 400, body: self.errorJSON("Invalid request"))
                return
            }

            guard let path = self.parseHTTPPath(from: request) else {
                self.sendResponse(connection: connection, status: 400, body: self.errorJSON("Invalid HTTP request"))
                return
            }

            self.handleRequest(path: path, connection: connection)
        }
    }

    // MARK: - HTTP parsing

    private func parseHTTPPath(from request: String) -> String? {
        guard let firstLine = request.split(separator: "\r\n", maxSplits: 1).first else { return nil }
        let parts = firstLine.split(separator: " ")
        guard parts.count >= 2, parts[0] == "GET" else { return nil }
        return String(parts[1])
    }

    // MARK: - Request handling

    private func handleRequest(path: String, connection: NWConnection) {
        guard let actionEngine else {
            sendResponse(connection: connection, status: 500, body: errorJSON("Server not configured"))
            return
        }

        guard ProStatusCache.shared.isPro else {
            sendResponse(connection: connection, status: 403, body: errorJSON("Pro required"))
            return
        }

        // Path is already percent-encoded from HTTP (e.g. /toggle/Living%20Room/Lamp)
        let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path

        guard !trimmedPath.isEmpty else {
            sendResponse(connection: connection, status: 400, body: errorJSON("Empty path"))
            return
        }

        // Build URL for URLSchemeHandler — path is already percent-encoded
        guard let url = URL(string: "itsyhome://\(trimmedPath)") else {
            sendResponse(connection: connection, status: 400, body: errorJSON("Invalid path"))
            return
        }

        guard let command = URLSchemeHandler.handle(url) else {
            let displayPath = trimmedPath.removingPercentEncoding ?? trimmedPath
            sendResponse(connection: connection, status: 400, body: errorJSON("Unknown action: \(displayPath)"))
            return
        }

        switch ActionParser.parse(command) {
        case .success(let parsed):
            let result = actionEngine.execute(target: parsed.target, action: parsed.action)
            switch result {
            case .success:
                sendResponse(connection: connection, status: 200, body: successJSON())
            case .partial(let succeeded, let failed):
                sendResponse(connection: connection, status: 200, body: partialJSON(succeeded: succeeded, failed: failed))
            case .error(let actionError):
                let statusCode = actionError.isNotFound ? 404 : 400
                sendResponse(connection: connection, status: statusCode, body: errorJSON(actionError.message))
            }
        case .failure(let parseError):
            sendResponse(connection: connection, status: 400, body: errorJSON(parseError.localizedDescription))
        }
    }

    // MARK: - HTTP response

    private func sendResponse(connection: NWConnection, status: Int, body: String) {
        let statusText: String
        switch status {
        case 200: statusText = "OK"
        case 400: statusText = "Bad Request"
        case 403: statusText = "Forbidden"
        case 404: statusText = "Not Found"
        case 500: statusText = "Internal Server Error"
        default: statusText = "Unknown"
        }

        let response = """
        HTTP/1.1 \(status) \(statusText)\r
        Content-Type: application/json\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        \r
        \(body)
        """

        let data = Data(response.utf8)
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    // MARK: - JSON helpers

    private func successJSON() -> String {
        "{\"status\":\"success\"}"
    }

    private func partialJSON(succeeded: Int, failed: Int) -> String {
        "{\"status\":\"partial\",\"message\":\"\(succeeded) succeeded, \(failed) failed\"}"
    }

    private func errorJSON(_ message: String) -> String {
        let escaped = message.replacingOccurrences(of: "\"", with: "\\\"")
        return "{\"status\":\"error\",\"message\":\"\(escaped)\"}"
    }

    // MARK: - Network info

    static func localIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            guard addrFamily == UInt8(AF_INET) else { continue }

            let name = String(cString: interface.ifa_name)
            guard name == "en0" || name == "en1" else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
            address = String(cString: hostname)
            break
        }

        return address
    }
}

// MARK: - ActionError helpers

private extension ActionError {
    var isNotFound: Bool {
        if case .targetNotFound = self { return true }
        return false
    }

    var message: String {
        switch self {
        case .targetNotFound(let target): return "Target not found: \(target)"
        case .ambiguousTarget(let options): return "Ambiguous target, options: \(options.joined(separator: ", "))"
        case .unsupportedAction(let action): return "Unsupported action: \(action)"
        case .bridgeUnavailable: return "Bridge unavailable"
        case .executionFailed(let reason): return reason
        }
    }
}
