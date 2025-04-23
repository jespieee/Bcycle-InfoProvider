//
//  ContentView.swift
//  Bcycle InfoProvider
//
//  Created by Michael on 4/22/25.
//

import SwiftUI

struct StationStatus: Hashable, Codable {
    let stationID: String
    let numBikesAvailable: Int
    let numDocksAvailable: Int
    let isInstalled: Bool
    let isRenting: Bool
    let isReturning: Bool
    let lastUpdated: Int
}

struct StationInfo: Hashable, Codable {
    let stationID: String
    let latitude: Double
    let longitude: Double
    let rentalURIs: StationRentalURIs
    let type: String?
    let regionID: String?
    let address: String?
    let name: String?
}

struct StationRentalURIs: Hashable, Codable {
    let iOS: String
    let android: String
}

struct GBFSPayload: Codable {
    let ttl: Int?
    let data: StationStatusData
    let version: String?
    let lastUpdated: Int?

}

struct StationStatusData: Codable {
    let stations: [StationInfo]
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
                let GBFSPayload = try JSONDecoder().decode(GBFSPayload.self, from: data)
                DispatchQueue.main.async {
                    // self?.stationStatuses = GBFSPayload.data.stations
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
                let GBFSPayload = try JSONDecoder().decode(GBFSPayload.self, from: data)
                DispatchQueue.main.async {
                    self?.stationInfo = GBFSPayload.data.stations
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
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.stationInfo, id: \.self) { stationInfo in
                    HStack {
                        Text(stationInfo.stationID).bold()
                    }
                    .padding(3)
                }
            }
            .navigationTitle(Text("Bcycle InfoProvider"))
            .onAppear {
                self.viewModel.fetchStatus()
                self.viewModel.fetchInfo()
            }
        }
    }
}

#Preview {
    ContentView()
}
