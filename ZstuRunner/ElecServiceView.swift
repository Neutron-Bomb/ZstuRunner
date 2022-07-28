//
//  ElecServiceView.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/7/27.
//

import SwiftUI
import Foundation

struct SmartWaterAndElectricityService: Codable {
    var code_: Int
    var sign: String
    var result_: String
    var body: String
    var message_: String
}

struct SmartWaterAndElectricityServiceBody: Codable {
    var modlist: [Mod]
    var collecdate: String
    var cardtype: String
    var ccbschoolid: String
    var message: String
    var result: String
    var ccbsecretkey: String
    var roomnum: String
    var identitytype: String
    var roomfullname: String
    var roomverify: String
    var status: String
}

extension SmartWaterAndElectricityServiceBody {
    struct Mod: Codable {
        var isshowpay: Int
//        var monthuselist: []
        var todayuse: Double
        var modstatus: String
        var collecdate: String
        var accode: Int
        var ecardacccode: Int
        var odd: Double
//        var weekuselist: []
        var status: String
    }
}

extension SmartWaterAndElectricityServiceBody.Mod {
    
}

class SWAEServlet: ObservableObject {
    
    @Published var test = ""
    @Published var SWAEData: SmartWaterAndElectricityService?
    @Published var SWAEBodyData: SmartWaterAndElectricityServiceBody?
    
    func ElecService_fetchData(_ account: String) {
        
        var request = URLRequest(url: URL(string: "https://xqh5.17wanxiao.com/smartWaterAndElectricityService/SWAEServlet")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Cookie" : "SERVERID=c69912e21354c6cedcf308ed1610416e|1658928177|1658928170; sid=dFc2OUJ0dEctYkI2UC1ZQ3hQLVpDWlktR0dYeFBBWEJyWDk2",
            "content-type" : "application/x-www-form-urlencoded;charset=UTF-8",
            "accept" : "application/json, text/plain, */*",
            "origin" : "https://xqh5.17wanxiao.com",
            "accept-language" : "zh-CN,zh-Hans;q=0.9",
            "user-agent" : "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Wanxiao/5.5.9 CCBSDK/2.4.0",
            "referer" : "https://xqh5.17wanxiao.com/userwaterelec/index.html"
        ]
        request.httpBody = "param=%7B%22cmd%22%3A%22getstuindexpage%22%2C%22roomverify%22%3A%222-19--188-70304%22%2C%22account%22%3A%222020316101023%22%2C%22timestamp%22%3A%2220220727212338574%22%7D&customercode=599&method=getstuindexpage".data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
                let decoder = JSONDecoder()
                DispatchQueue.main.async {
                    self.test = dataString
                    self.SWAEData = try! decoder.decode(SmartWaterAndElectricityService.self, from: data)
                    self.SWAEBodyData = try! decoder.decode(SmartWaterAndElectricityServiceBody.self, from: (self.SWAEData?.body.data(using: .utf8)!)!)
                }
            }
        }
        task.resume()
    }
}

struct ElecServiceView: View {
    
    @ObservedObject var servlet = SWAEServlet()
    
    var body: some View {
        List {
            if let SWAEData = servlet.SWAEData, let SWAEBodyData = servlet.SWAEBodyData {
                Text("\(SWAEData.code_)")
                Text(SWAEData.sign)
                Text(SWAEData.result_)
                Text("\(SWAEBodyData.modlist[0].odd)")
                Text(SWAEData.message_)
            }
            Section {
                Button("Fetch data") {
                    servlet.ElecService_fetchData("2020316101023")
                }
            }
        }
    }
}

struct ElecServiceView_Previews: PreviewProvider {
    static var previews: some View {
        ElecServiceView()
    }
}
