//
//  ContentView.swift
//  Bcycle InfoProvider
//
//  Created by Michael on 4/22/25.
//

import SwiftUI

struct StationStatusPayload: Codable {
    let ttl: Int?
    let data: StationStatusData
    let version: String?
}

struct StationInfoPayload: Codable {
    let ttl: Int?
    let data: StationInfoData
    let version: String?
    let lastUpdated: Int?
}

struct StationStatusData: Codable {
    let stations: [StationStatus]
}

struct StationInfoData: Codable {
    let stations: [StationInfo]
}

struct StationStatus: Hashable, Codable {
    let stationID: String
    let numBikesAvailable: Int
    let numDocksAvailable: Int
    let isInstalled: Bool
    let isRenting: Bool
    let isReturning: Bool
    let lastUpdated: Int
    
    enum CodingKeys: String, CodingKey {
        case stationID = "station_id"
        case numBikesAvailable = "num_bikes_available"
        case numDocksAvailable = "num_docks_available"
        case isInstalled = "is_installed"
        case isRenting = "is_renting"
        case isReturning = "is_returning"
        case lastUpdated = "last_reported"
    }
}

struct StationInfo: Decodable, Encodable, Hashable {
    let stationID: String
    let latitude: Double
    let longitude: Double
    let rentalURIs: StationRentalURIs
    let type: String?
    let regionID: String?
    let address: String?
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case stationID = "station_id"
        case latitude = "lat"
        case longitude = "lon"
        case rentalURIs = "rental_uris"
        case type = "_bcycle_station_type"
        case regionID = "region_id"
        case address = "address"
        case name = "name"
    }
}

struct StationRentalURIs: Hashable, Codable {
    let iOS: String
    let android: String
    
    enum CodingKeys: String, CodingKey {
        case iOS = "ios"
        case android = "android"
    }
}

class ViewModel: ObservableObject {
    
    @Published var stationStatuses: [StationStatus] = []
    @Published var stationInfo: [StationInfo] = []
    
    func fetchStatus() {
        guard let url = URL(string:
        "https://gbfs.bcycle.com/bcycle_madison/station_status.json") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                return
            }
            
            do {
                let statusPayload = try JSONDecoder().decode(StationStatusPayload.self, from: data)
                DispatchQueue.main.async {
                    self?.stationStatuses = statusPayload.data.stations
                    print(statusPayload.data.stations)
                }
            }
            catch {
                return
            }
        }
        
        task.resume()
    }
    
    func fetchInfo() {
        guard let url = URL(string:
        "https://gbfs.bcycle.com/bcycle_madison/station_information.json") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                return
            }
            
            do {
                let infoPayload = try JSONDecoder().decode(StationInfoPayload.self, from: data)
                DispatchQueue.main.async {
                    self?.stationInfo = infoPayload.data.stations
                    print(infoPayload.data.stations)
                }
            }
            catch {
                return
            }
        }
        
        task.resume()
    }
}

struct ContentView: View {
    
    @StateObject var viewModel = ViewModel()
    @State private var selectedStationID: String?
    private var selectedStationName: String {
            if let station = viewModel.stationInfo.first(where: { $0.stationID == selectedStationID }) {
                return station.name ?? station.stationID
            }
            return "None Selected"
        }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Picker(selection: $selectedStationID) {
                        ForEach(viewModel.stationInfo, id: \.stationID) { station in
                            Text(station.name ?? station.stationID)
                                .tag(station.stationID)
                        }
                    } label: {
                        HStack {
                            Text("Station")
                            Spacer()
                            Text(selectedStationName)
                                .foregroundColor(.gray)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    
                    // Optional: Show station details for selected station
                    if let stationID = selectedStationID,
                       let selectedStation = viewModel.stationInfo.first(where: { $0.stationID == stationID }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Station Name: \(selectedStation.name ?? "Unknown")")
                            Text("Address: \(selectedStation.address ?? "N/A")")
                            Text("Region: \(selectedStation.regionID ?? "N/A")")
                            Text("Type: \(selectedStation.type ?? "N/A")")
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Bcycle InfoProvider")
            .onAppear {
                viewModel.fetchStatus()
                viewModel.fetchInfo()
            }
        }
    }
}

#Preview {
    ContentView()
}
