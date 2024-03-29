//
//  DashboardViewModel.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/11/11.
//

import SwiftUI

extension DashboardView {
    @MainActor final class ViewModel: ObservableObject {
        @Published var mileageTarget: Double = 120
        @Published var areaFinished: Double = 0
        @Published var orieFinished: Double = 0
        @AppStorage("StuID") var stuid: String = "2020316101023"
        
        @Published var alertStuIDEmpty: Bool = false
        @Published var alertTimeout: Bool = false
        
        @Published var refreshing: Bool = false
        
        func clearRunData() {
            areaFinished = 0
            orieFinished = 0
        }
        
        func fetchRunData() async {
            struct RunData: Codable { var m: String }
            struct RunDataAlter: Codable { var data: ReceiveData }
            struct ReceiveData: Codable { var total: Double; var region: Double }
            
            refreshing = true
            defer {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.refreshing = false
                }
            }
            
            guard var url = URL(string: "http://10.11.246.182:8029/DragonFlyServ/Api/webserver/getRunDataSummary") else {
                print("Invalid URL")
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 3
            request.allHTTPHeaderFields = ["Content-Type": "application/x-www-form-urlencoded",
                                           "Content-Encoding": "gzip",
                                           "User-Agent": "Dalvik/2.1.0 (Linux; U; Android 11; RMX1931 Build/RKQ1.200928.002)",
                                           "Accept-Encoding": "gzip"]
            
            guard !stuid.isEmpty else {
                alertStuIDEmpty = true
                print("Student ID empty!")
                return
            }
            request.httpBody = try! "{'studentno':'\(stuid)','uid':'\(stuid)'}".data(using: .utf8)?.gzipped()
            
            do {
                clearRunData()
                let (data, _) = try await URLSession.shared.data(for: request)
                print(String(data: data, encoding: .utf8) ?? "data invalid")
                if let decodedData = try? JSONDecoder().decode(RunData.self, from: data) {
                    if let areaIndex = decodedData.m.firstIndex(of: "动") {
                        withAnimation {
                            areaFinished = Double(decodedData.m[decodedData.m.index(areaIndex, offsetBy: 2) ..< (decodedData.m.lastIndex(of: "公") ?? decodedData.m.endIndex)]) ?? 0
                        }
                        if let orieIndex = decodedData.m.firstIndex(of: "跑") {
                            withAnimation {
                                orieFinished = Double(decodedData.m[decodedData.m.index(orieIndex, offsetBy: 2) ..< (decodedData.m.firstIndex(of: "公") ?? decodedData.m.endIndex)]) ?? 0
                            }
                        }
                    }
                }
            } catch URLError.timedOut {
                print("Timeout")
                do {
                    url = URL(string: "http://haren724.top:9090/common/exercisemileage/\(stuid)")!
                    let (data, _) = try await URLSession.shared.data(from: url)
                    print(String(data: data, encoding: .utf8) ?? "data invalid")
                    if let decodedData = try? JSONDecoder().decode(RunDataAlter.self, from: data) {
                        withAnimation {
                            areaFinished = decodedData.data.region
                            orieFinished = decodedData.data.total - decodedData.data.total
                        }
                    }
                } catch URLError.timedOut {
                    alertTimeout = true
                    print("Timeout (alter)")
                } catch {
                    print("Invalid data (alter)")
                }
            } catch {
                print("Invalid data")
            }
//            let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
//                if let error = error {
//                    print("error: \(error)")
//                    return
//                }
//                guard let response = response as? HTTPURLResponse, (200 ... 299).contains(response.statusCode) else {
//                    print("Server error")
//                    return
//                }
//                if let mimeType = response.mimeType, mimeType == "application/json", let data = data, let dataString = String(data: data, encoding: .utf8) {
//                    print("got data: \(dataString)")
//                    do {
//                        let decoder = try JSONDecoder().decode(RunData.self, from: data)
//                        if let areaIndex = decodedData.m.firstIndex(of: "动") {
//                            self.areaFinished = Double(decodedData.m[decodedData.m.index(areaIndex, offsetBy: 2) ..< (decodedData.m.lastIndex(of: "公") ?? decodedData.m.endIndex)]) ?? 0
//                            if let orieIndex = decodedData.m.firstIndex(of: "跑") {
//                                self.orieFinished = Double(decodedData.m[decodedData.m.index(orieIndex, offsetBy: 2) ..< (decodedData.m.firstIndex(of: "公") ?? decodedData.m.endIndex)]) ?? 0
//                            }
//                        }
//                    } catch {
//                        print("format error!")
//                    }
//                }
//            })
//            task.resume()
        }
    }
}

