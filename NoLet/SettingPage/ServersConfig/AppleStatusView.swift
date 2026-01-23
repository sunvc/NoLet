//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - AppleStatusView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/1/23 23:41.

import SwiftUI

struct AppleStatusView: View {
    @StateObject private var viewModel = ApnsServerMonitoring()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Fetching status...")
            } else if let error = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .padding()
                    Button("Retry") {
                        Task {
                            try? await viewModel.fetchStatus()
                        }
                    }
                }
            } else {
                List {
                    ForEach(viewModel.services, id: \.serviceName) { service in
                        ServiceRow(service: service)
                    }
                }
                .refreshable {
                    await viewModel.run()
                }
            }
        }
        .navigationTitle(String("Apple Status"))
        .task {
            await viewModel.run()
        }
    }
}

struct ServiceRow: View {
    let service: ApnsServerMonitoring.Service

    var statusColor: Color {
        switch service.currentStatus {
        case .available: return .green
        case .maintenance: return .orange
        case .outage: return .red
        case .issue: return .yellow
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                Text(service.serviceName)
                    .font(.headline)
                Spacer()
                Text(service.currentStatus.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !service.events.isEmpty {
                ForEach(service.events, id: \.messageId) { event in
                    // Only show active events in detail, or maybe all recent ones
                    // Here we show a summary
                    if event.eventStatus.lowercased() != "resolved" && event.eventStatus
                        .lowercased() != "completed"
                    {
                        Text("⚠️ \(event.message)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

final class ApnsServerMonitoring: ObservableObject {
    @Published var services: [Service] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func run() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedServices = try await fetchStatus()
            services = fetchedServices
        } catch {
            errorMessage = "Failed to fetch status: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func fetchStatus() async throws -> [Service] {
        let urlString = "https://www.apple.com/support/systemstatus/data/developer/system_status_en_US.js"
        guard let url = URL(string: urlString) else {
            throw AppleStatusError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AppleStatusError.invalidResponse
        }

        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw AppleStatusError.dataError
        }

        // Strip JSONP wrapper: jsonCallback( ... );
        let cleanedString = jsonString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "^jsonCallback\\(", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\);$", with: "", options: .regularExpression)

        guard let jsonData = cleanedString.data(using: .utf8) else {
            throw AppleStatusError.dataError
        }

        do {
            let statusResponse = try JSONDecoder().decode(AppleStatusResponse.self, from: jsonData)
            return statusResponse.services
        } catch {
            throw AppleStatusError.decodingError(error)
        }
    }
}

extension ApnsServerMonitoring {
    enum AppleStatusError: Error {
        case invalidURL
        case invalidResponse
        case decodingError(Error)
        case dataError
    }

    struct AppleStatusResponse: Codable {
        let services: [Service]
    }

    enum ServiceStatus: String, Codable {
        case available = "Available"
        case maintenance = "Maintenance"
        case outage = "Outage"
        case issue = "Issue"

        var description: String {
            switch self {
            case .available: String(localized: "可用")
            case .maintenance: String(localized: "维护中")
            case .outage: String(localized: "不可用")
            case .issue: String(localized: "有异常")
            }
        }
    }

    struct Service: Codable, Equatable {
        static func == (
            lhs: ApnsServerMonitoring.Service,
            rhs: ApnsServerMonitoring.Service
        ) -> Bool {
            lhs.serviceName == rhs.serviceName
        }

        let serviceName: String
        let redirectUrl: String?
        let events: [Event]

        var currentStatus: ServiceStatus {
            // Filter for active events
            let activeEvents = events.filter { event in
                // If eventStatus is "resolved" or "completed", it's not active
                let status = event.eventStatus.lowercased()
                return status != "resolved" && status != "completed"
            }

            if activeEvents.isEmpty {
                return .available
            }

            // Determine the most severe status among active events
            // Priority: Outage > Maintenance > Issue
            if activeEvents.contains(where: { $0.statusType == "Outage" }) {
                return .outage
            } else if activeEvents.contains(where: { $0.statusType == "Maintenance" }) {
                return .maintenance
            } else {
                return .issue
            }
        }
    }

    struct Event: Codable {
        let usersAffected: String
        let epochStartDate: TimeInterval
        let epochEndDate: TimeInterval?
        let messageId: String
        let statusType: String
        let datePosted: String
        let startDate: String
        let endDate: String?
        let eventStatus: String
        let message: String
    }
}
