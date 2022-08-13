//
//  Settings.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/8/4.
//

import Foundation
import _MapKit_SwiftUI

class Settings: ObservableObject {
    // Initializers
    init() {
        
    }
    
    init(mode: Mode) {
        self.mode = mode
    }
    
    init(stuID: String) {
        self.stuID = stuID
    }
    
    init(stuID: String, isLogged: Bool) {
        self.stuID = stuID
        self.isLogged = isLogged
    }
    
    enum Mode { case zstu, tech }
    
    // Published properties
    @Published var mode: Mode = .zstu
    @Published var stuID = UserDefaults.standard.string(forKey: "stuID") ?? ""
    @Published var manager = LocationManager()
    @Published var tracking: MapUserTrackingMode = .follow
    @Published var isLogged = UserDefaults.standard.bool(forKey: "isLogged")
    
    @Published var username = UserDefaults.standard.string(forKey: "Username") ?? "student"
    @Published var password = UserDefaults.standard.string(forKey: "Password") ?? ""
    @Published var isTabBarHidden = false
}
