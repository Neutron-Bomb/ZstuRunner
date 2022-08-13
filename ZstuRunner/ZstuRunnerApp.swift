//
//  ZstuRunnerApp.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/6/13.
//

import SwiftUI

@main
struct ZstuRunnerApp: App {
    
    @StateObject private var settings = Settings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
