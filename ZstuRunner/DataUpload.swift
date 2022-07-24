//
//  DataUpload.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/7/5.
//

import Foundation

func overviewRefresh(_ stuID: String) -> Double {
    var orientate: Double = 0
    var area: Double = 0
    var request = URLRequest(url: URL(string: "http://10.11.246.182:8029/DragonFlyServ/Api/webserver/getRunDataSummary")!)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = ["Content-Type": "application/x-www-form-urlencoded",
                                   "Content-Encoding": "gzip",
                                   "User-Agent": "Dalvik/2.1.0 (Linux; U; Android 11; RMX1931 Build/RKQ1.200928.002)",
                                   "Accept-Encoding": "gzip"]
    
    let task = URLSession.shared.uploadTask(with: request, from: try! "{'studentno':'\(stuID)','uid':'\(stuID)'}".data(using: .utf8)?.gzipped()) { data, response, error in
        struct RunData: Codable { var m: String }
        if let error = error {
            print("error: \(error)")
            return
        }
        guard let response = response as? HTTPURLResponse, (200 ... 299).contains(response.statusCode) else {
            print("Server error")
            return
        }
        if let mimeType = response.mimeType, mimeType == "application/json", let data = data, let dataString = String(data: data, encoding: .utf8) {
            print("got data: \(dataString)")
            let decoder = try! JSONDecoder().decode(RunData.self, from: data)
            if let areaIndex = decoder.m.firstIndex(of: "动") {
                area = Double(decoder.m[decoder.m.index(areaIndex, offsetBy: 2) ..< (decoder.m.lastIndex(of: "公") ?? decoder.m.endIndex)]) ?? 0
                if let orieIndex = decoder.m.firstIndex(of: "跑") {
                    orientate = Double(decoder.m[decoder.m.index(orieIndex, offsetBy: 2) ..< (decoder.m.firstIndex(of: "公") ?? decoder.m.endIndex)]) ?? 0
                }
            }
            
        }
    }
    task.resume()
    return area
}
