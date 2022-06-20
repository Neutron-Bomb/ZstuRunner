//
//  ContentView.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/6/13.
//

import SwiftUI
import WebKit
import Gzip

class SecretForwarding: ObservableObject {
    
    init(mode: Mode) {
        self.mode = mode
    }
    
    enum Mode { case zstu, tech }
    @Published var mode: Mode
}


struct ContentView: View {
    
    @ObservedObject var secretForwarding = SecretForwarding(mode: .zstu)
    
    var columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    
    enum RunMode: String, CaseIterable, Identifiable {
        case inArea, oriented
        var id: Self { self }
    }
    enum Term: String, CaseIterable, Identifiable {
        case freshman1, freshman2, sophomore1, sophomore2, junior1, junior2, senior1, senior2
        var id: Self { self }
    }
    
    @State private var term: Term = .freshman1
    @State private var isRunning = false
    
    @State private var selectedTab = 1
    @State var isLogged = false
    
    @State private var username = ""
    @State private var password = ""
    
    @State private var runMode: RunMode = .inArea
    
    @State var dist: Double = 0
    
    @State var mileage_a: Double = 0
    @State var mileage_b: Double = 120
    
    var overview: some View {
        NavigationView {
            if isLogged {
                List {
                    Section("Current term's total mileage") {
                        DashboardPanelView("Total mileage", a: mileage_a, b: mileage_b, parameter: "km").padding()
                        Picker("Term", selection: $term) {
                            Text("Freshman 1").tag(Term.freshman1)
                            Text("Freshman 2").tag(Term.freshman2)
                            Text("Sophomore 1").tag(Term.sophomore1)
                            Text("Sophomore 2").tag(Term.sophomore2)
                            Text("Junior 1").tag(Term.junior1)
                            Text("Junior 2").tag(Term.junior2)
                            Text("Senior 1").tag(Term.senior1)
                            Text("Senior 2").tag(Term.senior2)
                        }
                    }
                    Section {
                        Button("refresh") {
                            var request = URLRequest(url: URL(string: "http://10.11.246.182:8029/DragonFlyServ/Api/webserver/getRunDataSummary")!)
                            request.httpMethod = "POST"
                            request.allHTTPHeaderFields = ["Content-Type": "application/x-www-form-urlencoded",
                                                           "Content-Encoding": "gzip",
                                                           "User-Agent": "Dalvik/2.1.0 (Linux; U; Android 11; RMX1931 Build/RKQ1.200928.002)",
                                                           "Accept-Encoding": "gzip"]
                            let task = URLSession.shared.uploadTask(with: request, from: try! "{'studentno':'\(username)','uid':'\(username)'}".data(using: .utf8)?.gzipped()) { data, response, error in
                                struct RunData: Codable {
                                    var m: String
                                }
                                if let error = error {
                                    print("error: \(error)")
                                    return
                                }
                                guard let response = response as? HTTPURLResponse, (200 ... 299).contains(response.statusCode) else {
                                    print("Server error")
                                    return
                                }
                                if let mimeType = response.mimeType,
                                    mimeType == "application/json",
                                    let data = data,
                                    let dataString = String(data: data, encoding: .utf8) {
                                    print("got data: \(dataString)")
                                    let decoder = try! JSONDecoder().decode(RunData.self, from: data)
                                    mileage_a = Double(decoder.m[decoder.m.index(decoder.m.firstIndex(of: ":") ?? decoder.m.endIndex, offsetBy: 1)..<(decoder.m.firstIndex(of: "公") ?? decoder.m.endIndex)]) ?? 0
                                }
                            }
                            task.resume()
                            
                        }
                    }
                }.navigationTitle("Overview")
            } else {
                Button("Login", action: { selectedTab = 2 })
            }
            
        }
        
    }
    
    var run: some View {
        NavigationView {
            if isLogged {
                List {
                    Section("Configurations") {
                        Picker(selection: $runMode, label: Text("Choose your run mode")) {
                            Text("In-area Mode").tag(RunMode.inArea)
                            Text("Oriented Mode").tag(RunMode.oriented)
                        }
                    }
                    Section {
                        Button(action: { isRunning.toggle() }, label: {
                            HStack {
                                Spacer()
                                Text("Let's Go!").bold().foregroundColor(.white)
                                Spacer()
                            }
                        }).listRowBackground(RoundedRectangle(cornerRadius: 2).foregroundColor(.accentColor))
                            .fullScreenCover(isPresented: $isRunning) {
                                RunnerView()
                            }
                    }
                }.navigationTitle("Run")
                    .scrollDisabled(true)
            } else {
                Button("Login", action: { selectedTab = 2 })
            }
//            GeometryReader { proxy in
//                ScrollView {
//                    VStack {
//                        Text("!                             ")
//                    }.background(.background).frame(width: proxy.size.width)
//                }.frame(width: proxy.size.width)
//                    .background(.regularMaterial)
//            }.navigationTitle("Run")
        }
    }
    
    var my: some View {
        NavigationView {
            if isLogged {
                List {
                    HStack {
                        Image("portrait")
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(height: 64).clipShape(Circle()).padding(.trailing)
                            VStack(alignment: .leading) {
                                Text("Haren").font(.title2)
                                Text(username).font(.footnote)
                            }
                    }
                    
                    Section {
                        NavigationLink("Change Password", destination: { Password(.change).navigationBarTitleDisplayMode(.inline) })
                        NavigationLink("Find Password", destination: {Password(.reset).navigationBarTitleDisplayMode(.inline) })
                    }
                    
                    Section {
                        Button("Logout", action: { isLogged.toggle() }).foregroundColor(.red)
                    }
                }.navigationTitle("My")
            } else {
                List {
                    Section {
                        HStack {
                            Text("Student ID").frame(width: 100, alignment: .leading)
                            TextField("your student ID", text: $username)
                        }
                        HStack {
                            Text("Password").frame(width: 100, alignment: .leading)
                            SecureField("your password", text: $password)
                        }
                    }
                    Section {
                        HStack {
                            Spacer()
                            NavigationLink("Find Password", destination: { Password(.reset).navigationBarTitleDisplayMode(.inline) }).opacity(0).overlay {
                                HStack {
                                    Spacer()
                                    Text("Find Password").foregroundColor(.accentColor).font(.footnote)
                                }
                            }
                        }.listRowBackground(EmptyView())
                    }
                    Button("Login") {
                        if password == "techrunner" {
                            secretForwarding.mode = .tech
                        } else {
                            isLogged.toggle()
                        }
                    }
                }.navigationTitle("Login")
            }
            
        }
    }
    
    var body: some View {
        if secretForwarding.mode == .tech {
            TechRunnerView(secretForwarding: secretForwarding)
        } else {
            NavigationView {
                TabView(selection: $selectedTab) {
                    overview.tabItem { Label("Overview", systemImage: "speedometer")}.tag(0)
                    run.tabItem { Label("Run", systemImage: "figure.run") }.tag(1).badge("Go!")
                    my.tabItem { Label("My", systemImage: "person.fill") }.tag(2)
                }
                NavigationLink("", destination: {}).id("123")
            }
        }
    }
}

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

struct RunnerView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack {
                    Button("Back", action: {dismiss()})
                }.frame(width: proxy.size.width)
            }.frame(width: proxy.size.width)
        }
    }
}

struct Password: UIViewRepresentable {
    
    init(_ service: Service) {
        self.service = service
    }
    
    enum Service {
        case change, reset
    }
    let service: Service
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView(frame: .zero)
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.callAsyncJavaScript("""
    document.querySelector("body > app-stage > ion-app > ion-router-outlet > app-root > ion-router-outlet > app-retrieve-password > ion-header > ion-toolbar > ion-buttons");
    return 0;
""", arguments: [:], in: nil, in: .page) { print("********\($0)********") }
        switch service {
        case .change:
            uiView.load(URLRequest(url: URL(string: "https://service.zstu.edu.cn/public/client/phone/retrieve?backUrl=https:%2F%2Fsso.zstu.edu.cn%2Flogin")!))
        case .reset:
            uiView.load(URLRequest(url: URL(string: "https://service.zstu.edu.cn/public/client/phone/retrieve?backUrl=https:%2F%2Fsso.zstu.edu.cn%2Flogin")!))
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isLogged: true)
            .environment(\.locale, .init(identifier: "zh-Hans"))
    }
}
