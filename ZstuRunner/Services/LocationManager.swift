//
//  LocationManager.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/6/29.
//

import MapKit
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    let manager = CLLocationManager()
    
    @Published var region = MKCoordinateRegion()    // 地图展示坐标点
    
    @Published var distance: Double = 0
    @Published var speed_average: Double = 0
    @Published var speed_current: Double = 0
    
    var coordinates = [CLLocation]()
    
    override init() {
        super.init()
        manager.delegate = self
//        manager.allowsBackgroundLocationUpdates = true
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.last.map {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        print(locations.last!)
        coordinates.append(locations.last!)
        distance += coordinates.last?.distance(from: coordinates.dropLast().last ?? coordinates.last!) ?? 0
        if let dropLast = coordinates.dropLast().last?.timestamp.timeIntervalSince1970 {
            speed_current = coordinates.last?.distance(from: coordinates.dropLast().last ?? coordinates.last!) ?? 0 / (coordinates.last!.timestamp.timeIntervalSince1970 - dropLast)
        }
        speed_average = distance / (coordinates.last!.timestamp.timeIntervalSince1970 -  coordinates[0].timestamp.timeIntervalSince1970)
    }
}


class testLocationManagerDelegate: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    let manager = CLLocationManager()
    
    
}
