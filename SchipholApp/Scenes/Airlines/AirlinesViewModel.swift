//
//  AirportsViewModel.swift
//  SchipholApp
//
//  Created by abuzeid on 30.10.20.
//  Copyright © 2020 abuzeid. All rights reserved.
//

import Foundation

protocol AirlinesViewModelType {
    var airlinesList: Observable<[Airline]> { get }
    var error: Observable<String?> { get }
    var isLoading: Observable<Bool> { get }
    func loadAirlinesData(of current: Airport)
}

final class AirlinesViewModel: AirlinesViewModelType {
    private let airlinesLoader: AirlinesDataSource
    private let flightsLoader: FlightsDataSource
    private let airportsLoader: AirportsDataSource
    let airlinesList: Observable<[Airline]> = .init([])
    let isLoading: Observable<Bool> = .init(false)
    let error: Observable<String?> = .init(nil)

    init(airlinesLoader: AirlinesDataSource = AirlinesLocalLoader(),
         flightsLoader: FlightsDataSource = FlightsLocalLoader(),
         airportsLoader: AirportsDataSource = AirportsLocalLoader()) {
        self.airlinesLoader = airlinesLoader
        self.flightsLoader = flightsLoader
        self.airportsLoader = airportsLoader
    }

    func loadAirlinesData(of current: Airport) {
        isLoading.next(true)
        let dispatchGroup = DispatchGroup()

        var airlines: [Airline] = []
        dispatchGroup.enter()
        getAirlines {
            airlines = $0
            dispatchGroup.leave()
        }

        var airports: [String: Airport] = [:]
        dispatchGroup.enter()
        getAirports {
            airports = $0
            dispatchGroup.leave()
        }

        var flightsList: [Flight] = []
        dispatchGroup.enter()
        getFlights {
            flightsList = $0
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: DispatchQueue.global()) { [weak self] in
            guard let self = self else { return }
            let flights = self.flightsStarts(from: current, flightsList, with: airports)
            let dataList = self.getAirlinesSortedByDistance(flights: flights, airlines: airlines)
            self.airlinesList.next(dataList)
            self.isLoading.next(false)
        }
    }
}

private extension AirlinesViewModel {
    func flightsStarts(from: Airport, _ flightsList: [Flight], with airports: [String: Airport]) -> [String: Double] {
        var flights: [String: Double] = [:]
        for flight in flightsList
            where flight.departureAirportID == from.id {
            guard let toAirport = airports[flight.arrivalAirportID] else { continue }
            let distance = from.distance(to: toAirport)
            flights[flight.airlineID] = flights[flight.airlineID] ?? 0 + distance
        }
        return flights
    }

    func getAirlinesSortedByDistance(flights: [String: Double], airlines: [Airline]) -> [Airline] {
        var airlinesWithFlights: [Airline] = []
        airlinesWithFlights.reserveCapacity(min(airlines.capacity, flights.count))

        for airline in airlines {
            guard let distance = flights[airline.id], distance > 0 else { continue }
            var airlineWithDistancew = airline
            airlineWithDistancew.totalDistance = distance
            airlinesWithFlights.append(airlineWithDistancew)
        }
        return airlinesWithFlights.sorted(by: {
            $0.totalDistance ?? 0 < $1.totalDistance ?? 0
        })
    }

    func getAirlines(callback: @escaping ([Airline]) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.airlinesLoader.loadAirlines { data in
                switch data {
                case let .success(response):
                    callback(response)
                case let .failure(error):
                    self.error.next(error.localizedDescription)
                    callback([])
                }
            }
        }
    }

    func getAirports(callback: @escaping ([String: Airport]) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.airportsLoader.loadAirports { data in
                switch data {
                case let .success(response):
                    var airports: [String: Airport] = [:]
                    response.forEach { airports[$0.id] = $0 }
                    callback(airports)
                case let .failure(error):
                    self.error.next(error.localizedDescription)
                    callback([:])
                }
            }
        }
    }

    func getFlights(callback: @escaping ([Flight]) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.flightsLoader.loadFlights { data in
                switch data {
                case let .success(response):
                    callback(response)
                case let .failure(error):
                    self.error.next(error.localizedDescription)
                    callback([])
                }
            }
        }
    }
}
