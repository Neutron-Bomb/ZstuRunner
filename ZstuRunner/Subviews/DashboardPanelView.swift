//
//  DashboardPanelView.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/7/5.
//

import SwiftUI

struct DashboardPanelView: View {
    
    init(_ name: String, a: Double, b: Double) {
        self.name  = name
        self.a = a
        self.b = b
        self.parameter = nil
    }
    
    init(_ name: String, a: Double, b: Double, parameter: String) {
        self.name  = name
        self.a = a
        self.b = b
        self.parameter = parameter
    }
    
    let name: String
    var a: Double
    var b: Double
    var parameter: String? = nil
    private var progress: Double { a / b }
    
    var history: some View {
        List {
            
        }.navigationTitle("History")
    }
    
    var body: some View {
        Circle().stroke(lineWidth: 16.0).opacity(0.1).foregroundColor(.accentColor)
            .overlay {
                VStack {
                    Text(String(format: "%.01f", progress * 100) + "%").bold().font(.title)
                    Text(LocalizedStringKey(name)).font(.title2)
                    Text("\(String(format: "%.01f", a))/\(String(format: "%.00f", b))\(parameter ?? "")")
                }
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 16.0, lineCap: .round, lineJoin: .round))
                    .rotationEffect(Angle(degrees: 270.0))
                    .foregroundColor(.accentColor)
            }
    }
}
