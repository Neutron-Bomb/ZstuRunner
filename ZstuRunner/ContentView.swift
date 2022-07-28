//
//  ContentView.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/6/13.
//

import _MapKit_SwiftUI
import CoreLocation
import SwiftUI
import WebKit
import UIKit
import Gzip

class Settings: ObservableObject {
    
    init(mode: Mode) {
        self.mode = mode
    }
    
    enum Mode { case zstu, tech }
    
    @Published var mode: Mode
    @Published var stuID: String = ""
    @Published var manager = LocationManager()
    @Published var tracking: MapUserTrackingMode = .follow
}

extension LocalizedStringKey {
// imagine `self` is equal to LocalizedStringKey("KEY_HERE")

    var stringKey: String {
        let description = "\(self)"
        // in this example description will be `LocalizedStringKey(key: "KEY_HERE", hasFormatting: false, arguments: [])`
        // for more clarity, `let description = "\(self)"` will have no differences
        // compared to `let description = "\(LocalizedStringKey(key: "KEY_HERE", hasFormatting: false, arguments: []))"` in this example.
        
        let components = description.components(separatedBy: "key: \"")
            .map { $0.components(separatedBy: "\",") }
        // here we separate the string by its components.
        // in `LocalizedStringKey(key: "KEY_HERE", hasFormatting: false, arguments: [])`
        // our key lays between two strings which are `key: "` and `",`.
        // if we manage to get what is between `key: "` and `",`, that would be our Localization Key
        // which in this example is `KEY_HERE`
        
        return components[1][0]
        // by trial, we know that `components[1][0]` will always be our localization Key
        // which is `KEY_HERE` in this example.
    }
}

struct ContentView: View {
    
    @ObservedObject var settings = Settings(mode: .zstu)
    
    var columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    
    enum RunMode: String, CaseIterable, Identifiable {
        case inArea, oriented
        var id: Self { self }
    }
    
    enum Term: String, CaseIterable, Identifiable {
        case freshman1, freshman2, sophomore1, sophomore2, junior1, junior2, senior1, senior2
        var id: Self { self }
    }
    
    @Environment(\.colorScheme) var colorScheme
    
// MARK: - @State Properties
    @State var moreApps = false
    
    @State private var term: Term = .freshman1
    @State private var isRunning = false
    
    @State var selectedTab = 1
    @State var isLogged = UserDefaults.standard.bool(forKey: "isLogged")
    
    @State var stuID = UserDefaults.standard.string(forKey: "stuID") ?? ""
    @State private var password = UserDefaults.standard.string(forKey: "Password") ?? ""
    
    @State private var runMode: RunMode = .inArea
    
    @State var dist: Double = 0
    
    @State var area_a: Double = 0
    @State var orientate_a: Double = 0
    @State private var mileage_b: Double = 120
    
    @State var isstuIDEmpty = false
    @State var isLocationRequestDenied = false
    
    @State var username = UserDefaults.standard.string(forKey: "Username") ?? LocalizedStringKey("_USERNAME").stringKey
    
    // Overview
    @State var isRefreshing = false
    
// MARK: - Overview
    var overview: some View {
        NavigationView {
            if isLogged {
                List {
                    Section("CURRENT_TERM_TOTAL_MILEAGE") {
                        DashboardPanelView("TOTAL_MILEAGE", a: area_a + orientate_a, b: mileage_b, parameter: "km").padding()
                        HStack {
                            Text("ORIENTATE_DIST")
                            Spacer()
                            Text("\(String(format: "%.01f", orientate_a))km")
                        }
                        HStack {
                            Text("AREA_DIST")
                            Spacer()
                            Text("\(String(format: "%.01f", area_a))km")
                        }
//                        这个是一个学期选择器，本来是用来查询每个学期的跑步情况（暂时弃用）
//                        Picker("Term", selection: $term) {
//                            Text("Freshman 1").tag(Term.freshman1)
//                            Text("Freshman 2").tag(Term.freshman2)
//                            Text("Sophomore 1").tag(Term.sophomore1)
//                            Text("Sophomore 2").tag(Term.sophomore2)
//                            Text("Junior 1").tag(Term.junior1)
//                            Text("Junior 2").tag(Term.junior2)
//                            Text("Senior 1").tag(Term.senior1)
//                            Text("Senior 2").tag(Term.senior2)
//                        }
                    }
                    Section {
                        Button("_REFRESH") {
                            if !stuID.isEmpty {
                                isstuIDEmpty = false
//                                { (_ tuple: (orientate: Double, area: Double)) in
//                                    orientate_a = tuple.orientate
//                                    area_a = tuple.area
//                                }(overviewRefresh(stuID))
                                print(overviewRefresh(stuID))
                            } else {
                                isstuIDEmpty = true
                            }
                        }.alert("ID_EMPTY", isPresented: $isstuIDEmpty) {
                            Button("Dismiss", role: .cancel) {}
                        }
                    }
                }.navigationTitle("OVERVIEW")
            } else {
                Button("_LOGIN", action: { selectedTab = 2 })
            }
        }
    }
    
// MARK: - Run
    var run: some View {
        NavigationView {
            if isLogged {
                if #available(iOS 16.0, *) {
                    run_legacy.scrollDisabled(true)
                } else {
                    // Fallback on earlier versions
                    run_legacy
                }
            } else {
                Button("_LOGIN", action: { selectedTab = 2 })
            }
        }
    }

    var run_legacy: some View {
        List {
            Section("CONFIGURATION") {
                Picker(selection: $runMode, label: Text("CHOOSE_RUN_MODE")) {
                    Text("IN_AREA_MODE").tag(RunMode.inArea)
                    Text("ORIENTED_MODE").tag(RunMode.oriented)
                }
            }
            Section {
                Map(
                    coordinateRegion: .constant(.init(center: .init(latitude: 30.3135, longitude: 120.3565), latitudinalMeters: 600, longitudinalMeters: 600)),
                    interactionModes: MapInteractionModes(),
                    showsUserLocation: true,
                    userTrackingMode: $settings.tracking
                ).background(RoundedCorners(color: .blue, tl: 0, tr: 0, bl: 0, br: 0)).scaledToFit()
                    .listRowBackground(EmptyView()).listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                Label {
                    Text("Location Verified")
                } icon: {
                    Image(systemName: "checkmark.circle").foregroundColor(.green)
                }
            }.listRowSeparator(.hidden)
            Section {
                Button(action: {
                    if LocationManager().manager.authorizationStatus == .notDetermined {
                        LocationManager().manager.requestWhenInUseAuthorization()
                    } else if LocationManager().manager.authorizationStatus == .denied {
                        isLocationRequestDenied = true
                    } else {
                        isRunning = true
                    }
                }, label: {
                    HStack {
                        Spacer()
                        Text("_GO").bold().foregroundColor(.white)
                        Spacer()
                    }
                }).listRowBackground(RoundedRectangle(cornerRadius: 2).foregroundColor(.accentColor))
                    .fullScreenCover(isPresented: $isRunning) {
                        RunnerView()
                    }
                    .alert("LOCATION_SERVICE_DENIED", isPresented: $isLocationRequestDenied) {
                        
                    }
            }
        }.navigationTitle("_RUN")
    }
    
// MARK: - My
    var my: some View {
        NavigationView {
            if isLogged {
                List {
                    NavigationLink(destination: {
                        List  {
                            Section {
                                HStack {
                                    Text("CHANGE_USERNAME")
                                    Spacer()
                                    TextField("", text: $username).multilineTextAlignment(.trailing)
                                        .onSubmit {
                                            UserDefaults.standard.set(username, forKey: "Username")
                                        }
                                }
                            }
                            Section {
                                NavigationLink("CHANGE_PASSWORD", destination: { Password(.change).navigationBarTitleDisplayMode(.inline) })
                                NavigationLink("FIND_PASSWORD", destination: {Password(.reset).navigationBarTitleDisplayMode(.inline) })
                            }
                            
                            Section {
                                Button("Logout", action: { isLogged.toggle() }).foregroundColor(.red)
                            }
                        }.navigationTitle("MY_SETTINGS")
                    }, label: {
                        HStack {
                            Image("portrait")
                                .resizable().aspectRatio(contentMode: .fit)
                                .frame(height: 64).clipShape(Circle()).padding(.trailing)
                            VStack(alignment: .leading) {
                                Text("\(username)").font(.title2)
                                Text(stuID).font(.footnote)
                            }
                        }
                    })
                    Section {
                        DisclosureGroup("CHECK_RUNNING_PLAN") {
                            Section {
                                VStack(alignment: .leading) {
                                    Text("_BOY").bold().padding(.bottom, 1)
                                    Section {
                                        Text("BOY_MIN_DISTANCE")
                                        Text("BOY_SPEED_RANGE")
                                    }.padding(.leading)
                                }
                                VStack(alignment: .leading) {
                                    Text("_GIRL").bold().padding(.bottom, 1)
                                    Section {
                                        Text("GIRL_MIN_DISTANCE")
                                        Text("GIRL_SPEED_RANGE")
                                    }.padding(.leading)
                                }
                            }.foregroundColor(.primary)
                            
                        }.accentColor(.init(white: colorScheme == .light ? 0.72 : 0.35))
                    }
                    Section {
                        HStack {
                            Text("VERSION")
                            Spacer()
                            Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Button("CHECK_UPDATE") { }
                            Spacer()
                            Text("_LATEST").foregroundColor(.secondary)
                        }
                        Button("MORE_APPS", action: { moreApps.toggle() }).fullScreenCover(isPresented: $moreApps, content: { QRCodeView() })
                    }
                }.navigationTitle("My")
            } else {
                // login menu
                List {
                    Section {
                        HStack {
                            Text("Student ID").frame(width: 60, alignment: .leading)
                            TextField("your student ID", text: $stuID)
                        }
                        HStack {
                            Text("Password").frame(width: 60, alignment: .leading)
                            SecureField("your password", text: $password)
                        }
                    }
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
                    Button("_LOGIN") {
                        if password == "techrunner" {
                            settings.mode = .tech
                            password = ""
                        } else {
                            isLogged.toggle()
                        }
                        UserDefaults.standard.set(stuID, forKey: "stuID")
                        UserDefaults.standard.set(password, forKey: "Password")
                        UserDefaults.standard.set(isLogged, forKey: "isLogged")
                    }
                }.navigationTitle("_LOGIN")
            }
            
        }
    }
    
// MARK: - Body
    var body: some View {
        if settings.mode == .tech {
            TechRunnerView(settings: settings)
        } else {
            TabView(selection: $selectedTab) {
                overview.tabItem { Label("OVERVIEW", systemImage: "speedometer")}.tag(0)
                run.tabItem { Label("_RUN", systemImage: "figure.run") }.tag(1).badge("Go!")
                my.tabItem { Label("My", systemImage: "person.fill") }.tag(2)
            }.onOpenURL(perform: {url in
                self.selectedTab = 2
                self.moreApps = url == URL(string: "okay")!
            })
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


struct RoundedCorners: View {
    var color: Color = .blue
    var tl: CGFloat = 0.0
    var tr: CGFloat = 0.0
    var bl: CGFloat = 0.0
    var br: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                
                let w = geometry.size.width
                let h = geometry.size.height
                
                // Make sure we do not exceed the size of the rectangle
                let tr = min(min(self.tr, h/2), w/2)
                let tl = min(min(self.tl, h/2), w/2)
                let bl = min(min(self.bl, h/2), w/2)
                let br = min(min(self.br, h/2), w/2)
                
                path.move(to: CGPoint(x: w / 2.0, y: 0))
                path.addLine(to: CGPoint(x: w - tr, y: 0))
                path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
                path.addLine(to: CGPoint(x: w, y: h - br))
                path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
                path.addLine(to: CGPoint(x: bl, y: h))
                path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
                path.addLine(to: CGPoint(x: 0, y: tl))
                path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
            }
            .fill(self.color)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selectedTab: 1, isLogged: true, stuID: "2020316101023")
            .environment(\.locale, .init(identifier: "zh-Hans"))
        ContentView(selectedTab: 2, isLogged: false, stuID: "2020316101023")
            .environment(\.locale, .init(identifier: "zh-Hans"))
        RunnerView()
            .environment(\.locale, .init(identifier: "zh-Hans"))
    }
}
