//
//  LoginView.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/8/9.
//

import Foundation
import SwiftUI
import RegexBuilder

struct LoginView: View {
    
    @EnvironmentObject var settings: Settings
    
    @State var isLogging = false
    @State var isLogFailed = false
    @State var isDebugging = false
    
    @State var croypto = ""
    @State var execution = ""
    
    func login(stuID: String, passwd: String) {
        self.isLogging = true
        
        let croyptoReg = /<p id="login-croypto">(.*?)<\/p>/
        let executionReg = /<p id="login-page-flowkey">(.*?)<\/p>/
        
        let baseUrl = URL(string: "https://sso-443.webvpn.zstu.edu.cn/login")!
        let queryString = "username=\(stuID)&type=UsernamePassword&_eventId=submit&geolocation=&execution=??&captcha_code=&croypto=??&password=??"
        var request = URLRequest(url: baseUrl)
        request.httpMethod = "POST"
        request.httpBody = queryString.data(using: .utf8)
        
        let task_prepare = URLSession.shared.dataTask(with: baseUrl) { data, response, error in
            if let error = error {
                print("error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ... 299).contains(response.statusCode) else {
                print("Server error")
                return
            }
            if let mimeType = response.mimeType, mimeType == "text/html", let data = data, let dataString = String(data: data, encoding: .utf8) {
                if let croyptoMatch = dataString.firstMatch(of: croyptoReg), let executionMatch = dataString.firstMatch(of: executionReg) {
                    self.croypto = String(croyptoMatch.output.1)
                    self.execution = String(executionMatch.output.1)
                }
            }
        }
        
        let task_login = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("error: \(error)")
                self.isLogging = false
                isLogFailed = true
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ... 299).contains(response.statusCode) else {
                print("Server error")
                self.isLogging = false
                isLogFailed = true
                return
            }
            if let mimeType = response.mimeType, mimeType == "application/json", let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("got data: \(dataString)")
                let decoder = JSONDecoder()
                settings.isLogged = true
            }
        }
        
        task_prepare.resume()
        task_login.resume()
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Student ID").frame(width: 60, alignment: .leading)
                        TextField("your student ID", text: $settings.stuID).opacity(isLogging ? 0.5 : 1)
                    }
                    HStack {
                        Text("Password").frame(width: 60, alignment: .leading)
                        SecureField("your password", text: $settings.password).opacity(isLogging ? 0.5 : 1)
                    }
                }.disabled(isLogging)
                Section {
                    HStack {
                        Spacer()
                        NavigationLink("FIND_PASSWORD", destination: { Password(.reset).navigationBarTitleDisplayMode(.inline) }).opacity(0).overlay {
                            HStack {
                                Spacer()
                                Text("FIND_PASSWORD").foregroundColor(.accentColor).font(.footnote)
                            }
                        }
                    }.listRowBackground(EmptyView())
                }
                Button(isLogging ? "" : "_LOGIN") {
                    if settings.password == "techrunner" {
                        settings.mode = .tech
                        settings.password = ""
                    } else {
                        login(stuID: settings.stuID, passwd: settings.password)
                    }
                    UserDefaults.standard.set(settings.stuID, forKey: "stuID")
                    UserDefaults.standard.set(settings.password, forKey: "Password")
                    UserDefaults.standard.set(settings.isLogged, forKey: "isLogged")
                }.overlay {
                    if isLogging {
                        ProgressView().padding(.leading)
                    }
                }
                .disabled(settings.stuID.isEmpty || settings.password.isEmpty)
                if isDebugging {
                    Section("DEBUG") {
                        Text(croypto)
                        Text(execution)
                    }
                }
            }.navigationTitle("_LOGIN")
                .alert("LOGIN_FAILED", isPresented: $isLogFailed, actions: {
                    
                }, message: {
                    Text("LOGIN_RETRY")
                })
                .toolbar {
                    ToolbarItem {
                        Button (action: { isDebugging.toggle() }, label: { Image(systemName: "screwdriver.fill").foregroundColor(.secondary) })
                    }
                }
        }.onDisappear { isLogging = false }
    }
}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//    }
//}
