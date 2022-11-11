//
//  TechRunnerView.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/6/13.
//

import SwiftUI
import MapKit
import CoreLocation
import Gzip


struct TechRunnerView: View {
    
    @ObservedObject var settings = Settings(mode: .zstu)
    
    @State var showPref = false
    @State var stuID = UserDefaults.standard.string(forKey: "stuID") ?? ""
    @State var isWrongID = false
    @State var isChecked = false
    @State var date = Date()
    @State var notReadyToSubmit: Bool = false
    @State var isAutoGenerateMode = true
    @State var notSafeModify = false
    @State var usedTime: TimeStamp = 300
    
    @State var waitForUpload = false
    @State var returnDataString = ""
    
    #if os(iOS)
    let systemName = UIDevice.current.systemName
    #elseif os(macOS)
    let systemName = "macOS"
    #endif
    
    // Dashboard Views
//    var dashboard_ipados: some View {
//        List {
//            Text("It works!")
//        }.navigationTitle("Dashboard")
//    }
//    var dashboard_ios: some View {
//        NavigationView {
//            dashboard_ipados
//                .toolbar(content: { Button(action: { showPref.toggle() }, label: { Image(systemName: "gear") }) })
//        }.sheet(isPresented: $showPref, onDismiss: {
//            if stuID.count != 13 || Int(stuID) == nil {
//                isWrongID = true
//            }
//        }, content: { preference })
//
//    }

    // Upload Views
    var upload_ipados: some View {
        Form {
            Section {
                HStack{
                    Label("Student ID", systemImage: "person.circle.fill")
                    Spacer()
                    Text(stuID)
                }
                Toggle(isOn: $isAutoGenerateMode) { Label("Auto generate run data", systemImage: "checkmark.seal.fill")}
            }.disabled(!isChecked)
                .alert("It seems that you didn't set your student ID", isPresented: $isWrongID) {
                    Button("cancel", role: .cancel) { isChecked = false }
                    Button("Go to set") { showPref.toggle() }
                } message: {
                    Text("Please check it in preference")
                }
            
            // 手动设置上传数据
            if !isAutoGenerateMode {
                Section {
                    DatePicker(selection: $date, label: { Label("Date", systemImage: "calendar.badge.clock") })
                    HStack {
                        Label("Used time", systemImage: "clock.fill")
                        Spacer()
                        Menu("\(usedTime)") {
                            Button("360") { usedTime = 360 }
                        }
                    }
                }
                .onAppear(perform: { notSafeModify = true})
                .alert("Disabling auto generate data will be dangerous", isPresented: $notSafeModify) {
                    Button("Oh, I want to switch back") { isAutoGenerateMode.toggle() }
                    Button("Dismiss") { }
                }
            }
            
            VStack {
                Label("**CAUTION**", systemImage: "exclamationmark.triangle.fill").foregroundColor(.red).font(.title2)
                ScrollView {
                    Text("""
                         1. Be sure to check the date and **do not duplicate** the data date that has been submitted before. Otherwise, you will bear the consequences!
                         
                         2. It is best between 6:30 p.m. and 9:30 p.m., and the data beyond this range may be checked by the administrator!
                         
                         * Only after switching the toogle on can you modify the upload data *
                         """)
                }
                Toggle(isOn: $isChecked) {
                    Text("I've known the caution above.").bold()
                }.onTapGesture {
                    if stuID.isEmpty && !isChecked {
                        isWrongID = true
                    }
                }
            }.fixedSize(horizontal: false, vertical: true)
            Section {
                Button("Submit") { notReadyToSubmit = true }.disabled(!isChecked)
                    .alert("Please check all the data again to avoid ban", isPresented: $notReadyToSubmit) {
                        Button("Wait, I need to check") { }
                        Button("OK, submit") {
                            waitForUpload = true
                            if isAutoGenerateMode {
                                date = Date()
                            }
                            UploadData(beginTime: Int(date.timeIntervalSince1970 / 86400) * 86400 + TimeStamp.random(in: 43200 ... 46800), useTime: Int.random(in: 930 ... 1130), stuID: stuID , distance: Int.random(in: 3000 ... 3200)).upload()
                            print(stuID)
                            returnDataString = "OK!"
                        }
                    }
            }
        }.navigationTitle("Upload")
            .animation(.default, value: isAutoGenerateMode)
            .sheet(isPresented: $waitForUpload, content: {
                VStack {
                    if returnDataString.isEmpty {
                        ProgressView("Loading")
                    } else {
                        Text("Got data: \(returnDataString)")
                        Button("Dismiss") {
                            returnDataString = ""
                            waitForUpload.toggle()
                        }
                    }
                    
                }.interactiveDismissDisabled()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
            })
    }
    var upload_ios: some View {
        NavigationView {
            upload_ipados
                .toolbar(content: { Button(action: { showPref.toggle() }, label: { Image(systemName: "gear") }) })
        }.sheet(isPresented: $showPref, onDismiss: { if isWrongID { isChecked = false } }, content: { preference })
    }
    
    // Preference View
    var preference: some View {
        NavigationView {
            Form {
                HStack {
                    Label("Student ID", systemImage: "person.circle.fill")
                    Spacer()
                    TextField("Your Student ID here", text: $stuID)
                        .alert(isPresented: $isWrongID) {
                            Alert(title: Text("Wrong Student ID format"),
                                              message: Text("Please check your student ID"),
                                              dismissButton: .default(Text("OK")))
                        }
                        .multilineTextAlignment(.trailing)
                        .onSubmit {
                            if stuID.count != 13 || Int(stuID) == nil {
                                isWrongID = true
                            } else {
                                UserDefaults.standard.set(stuID, forKey: "stuID")
                            }
                        }
                }
            }.navigationTitle("Preference")
                .toolbar { Button("OK", action: { showPref.toggle() })}
        } //.interactiveDismissDisabled()
    }
    
    var body: some View {
        ZStack {
            switch systemName {
            case "iOS":
                TabView {
                    ContentView().overview.tabItem { Label("Dashboard", systemImage: "speedometer") }
                    upload_ios.tabItem { Label("Upload", systemImage: "icloud.and.arrow.up") }
                }
            case "iPadOS":
                NavigationView {
                    Form {
                        NavigationLink(destination: upload_ipados, label: { Label("Upload", systemImage: "icloud.and.arrow.up") })
                    }.navigationTitle("TechRunner")
                        .toolbar(content: { Button(action: { showPref.toggle() }, label: { Image(systemName: "gear") }) })
                }.sheet(isPresented: $showPref, onDismiss: {
                    if stuID.count != 13 || Int(stuID) == nil {
                        isWrongID = true
                    }
                }, content: { preference })
            case "macOS":
                Text("It works!")
            default:
                Text("You're running TechRunner on a Unknown platform.\n Please try on iPhone or iPad!")
            }
            VStack {
                Button("Switch back") { settings.mode = .zstu }.buttonStyle(.bordered).buttonBorderShape(.capsule)
                Spacer()
            }
        }
    }
}

typealias TimeStamp = Int

enum DataMode { case auto, manual }

enum UploadingError: Error {
    case networkError
    case metadataError
    case timezoneError
    case UnexpectedError
}

/// example:
///     "{'begintime': '1651581003', 'uid': '2020316101023', 'schoolno': '10338', 'distance': '3100', 'studentno': '2020316101023', 'atttype': '3', 'eventno': '801', 'speed': '6.4662798476885905', 'endtime': '1651582156', 'usetime': '1153', 'location': '30.31263324631008,120.35565898185429;1651581003;null;null;16;null@30.3127496875285,120.35566497652745;1651581003;null;null;16;null@30.312317033273448,120.35566497128903;1651581003;null;null;16;null@30.312196150194268,120.3556889822428;1651581003;null;null;16;null@30.31190213840757,120.35567094314703;1651581003;null;null;16;null@30.31169347700526,120.35592326989509;1651581003;null;null;16;null@30.31166377363067,120.35608747827874;1651581003;null;null;16;null@30.311759411637826,120.3564139133997;1651581003;null;null;16;null@30.312015423870573,120.35649405299627;1651581003;null;null;16;null@30.312135455702546,120.35648603687505;1651581003;null;null;16;null@30.31234336019412,120.35642799011961;1651581003;null;null;16;null@30.31256859078578,120.35645203703508;1651581003;null;null;16;null@30.312633597780987,120.35645304487986;1651581003;null;null;16;null@30.312860510020915,120.35640700240715;1651581003;null;null;16;null@30.31302509493594,120.35617770367037;1651581003;null;null;16;null@30.31305039107054,120.35578818352954;1651581003;null;null;16;null@30.312936316064295,120.35572109576873;1651581003;null;null;16;null@30.312839163029555,120.3556419706669;1651581003;null;null;16;null@30.312515058329726,120.35563594479343;1651581003;null;null;16;null@30.312256173854966,120.35573906001967;1651581003;null;null;16;null@30.31212414125125,120.35574006067817;1651581003;null;null;16;null@30.311888028853296,120.35568394935318;1651581003;null;null;16;null@30.311693366364747,120.35589121581289;1651581003;null;null;16;null@30.311713214132208,120.35632579978567;1651581003;null;null;16;null@30.311828439213233,120.356496025436;1651581003;null;null;16;null@30.312131399751912,120.356450996001;1651581003;null;null;16;null@30.31236642204377,120.35645100839598;1651581003;null;null;16;null@30.31260342088297,120.35644502655911;1651581003;null;null;16;null@30.312747480088547,120.35646205527851;1651581003;null;null;16;null@30.31274751505209,120.35646205229796;1651581003;null;null;16;null@30.313057992638786,120.3561626921157;1651581003;null;null;16;null@30.3130176159071,120.35593338488277;1651581003;null;null;16;null@30.31304043814653,120.35576696591164;1651581003;null;null;16;null@30.31286424375484,120.35563496157155;1651581003;null;null;16;null@30.312661041055,120.35564096965555;1651581003;null;null;16;null@30.31233008508077,120.3556930136653;1651581003;null;null;16;null@30.31209919183043,120.35574005970868;1651581003;null;null;16;null@30.31190407450211,120.35568396802196;1651581003;null;null;16;null@30.31181726843795,120.3557470353528;1651581003;null;null;16;null@30.31181726843795,120.3557470353528;1651581003;null;null;16;null@30.31181726843795,120.3557470353528;1651581003;null;null;16;null@30.31181726843795,120.3557470353528;1651581003;null;null;16;null@30.31181726843795,120.3557470353528;1651581003;null;null;16;null@30.31181726843795,120.3557470353528;1651581003;null;null;16;null@30.31181726843795,120.3557470353528;1651581003;null;null;16;null@30.31181726843795,120.3557470353528;1651581003;null;null;16;null@30.311758284664297,120.35581712050559;1651581003;null;null;16;null@30.311758284664297,120.35581712050559;1651581003;null;null;16;null@30.311627807393574,120.35611751307746;1651581003;null;null;16;null@30.311786332225367,120.35644396960421;1651581003;null;null;16;null@30.3118735046678,120.35649404222117;1651581003;null;null;16;null@30.31223557552794,120.35649706178788;1651581003;null;null;16;null@30.3126424910328,120.35648707929705;1651581003;null;null;16;null@30.31286553030276,120.35640699916964;1651581003;null;null;16;null@30.313014285493235,120.35624979669836;1651581003;null;null;16;null@30.313025625520577,120.35593738063055;1651581003;null;null;16;null@30.31304036156159,120.35575797162721;1651581003;null;null;16;null@30.312699205234605,120.35562793923071;1651581003;null;null;16;null@30.312437176895752,120.35568801149368;1651581003;null;null;16;null@30.312144160591142,120.35569298298157;1651581003;null;null;16;null@30.31186121319104,120.35569597412757;1651581003;null;null;16;null@30.311698481236867,120.35588821010847;1651581003;null;null;16;null@30.31165402877656,120.35622866272591;1651581003;null;null;16;null@30.31185440637294,120.3565040370213;1651581003;null;null;16;null@30.31224764452733,120.35654211707754;1651581003;null;null;16;null@30.312511517967295,120.35646203974848;1651581003;null;null;16;null@30.31276147846229,120.35643202252243;1651581003;null;null;16;null@30.31276147846229,120.35643202252243;1651581003;null;null;16;null@30.31276147846229,120.35643202252243;1651581003;null;null;16;null@30.31276147846229,120.35643202252243;1651581003;null;null;16;null@30.31276147846229,120.35643202252243;1651581003;null;null;16;null@30.31276147846229,120.35643202252243;1651581003;null;null;16;null@30.31276147846229,120.35643202252243;1651581003;null;null;16;null@30.31276151065063,120.3564320196008;1651581003;null;null;16;null'}".data(using: .utf8)!


struct UploadData {
    
    let url = URL(string: "http://10.11.246.182:8029/DragonFlyServ/Api/webserver/uploadRunData")!
    
    var origin = [
        [30.31263324631008, 120.35565898185429],
        [30.312437116338312, 120.35566497652745],
        [30.312317033273448, 120.35566497128903],
        [30.312196150194268, 120.3556889822428],
        [30.31190213840757, 120.35567094314703],
        [30.31169347700526, 120.35592326989509],
        [30.31166377363067, 120.35608747827874],
        [30.311759411637826, 120.3564139133997],
        [30.312015423870573, 120.35649405299627],
        [30.312135455702546, 120.35648603687505],
        [30.31234336019412, 120.35642799011961],
        [30.31256859078578, 120.35645203703508],
        [30.312633597780987, 120.35645304487986],
        [30.312860510020915, 120.35640700240715],
        [30.31302509493594, 120.35617770367037],
        [30.31305039107054, 120.35578818352954],
        [30.312936316064295, 120.35572109576873],
        [30.312839163029555, 120.3556419706669],
        [30.312515058329726, 120.35563594479343],
        [30.312256173854966, 120.35573906001967],
        [30.31212414125125, 120.35574006067817],
        [30.311888028853296, 120.35568394935318],
        [30.311693366364747, 120.35589121581289],
        [30.311713214132208, 120.35632579978567],
        [30.311828439213233, 120.356496025436],
        [30.312131399751912, 120.356450996001],
        [30.31236642204377, 120.35645100839598],
        [30.31260342088297, 120.35644502655911],
        [30.312747480088547, 120.35646205527851],
        [30.31274751505209, 120.35646205229796],
        [30.313057992638786, 120.3561626921157],
        [30.3130176159071, 120.35593338488277],
        [30.31304043814653, 120.35576696591164],
        [30.31286424375484, 120.35563496157155],
        [30.312661041055, 120.35564096965555],
        [30.31233008508077, 120.3556930136653],
        [30.31209919183043, 120.35574005970868],
        [30.31190407450211, 120.35568396802196],
        [30.31181726843795, 120.3557470353528],
        [30.31181726843795, 120.3557470353528],
        [30.31181726843795, 120.3557470353528],
        [30.31181726843795, 120.3557470353528],
        [30.31181726843795, 120.3557470353528],
        [30.31181726843795, 120.3557470353528],
        [30.31181726843795, 120.3557470353528],
        [30.31181726843795, 120.3557470353528],
        [30.311758284664297, 120.35581712050559],
        [30.311758284664297, 120.35581712050559],
        [30.311627807393574, 120.35611751307746],
        [30.311786332225367, 120.35644396960421],
        [30.3118735046678, 120.35649404222117],
        [30.31223557552794, 120.35649706178788],
        [30.3126424910328, 120.35648707929705],
        [30.31286553030276, 120.35640699916964],
        [30.313014285493235, 120.35624979669836],
        [30.313025625520577, 120.35593738063055],
        [30.31304036156159, 120.35575797162721],
        [30.312699205234605, 120.35562793923071],
        [30.312437176895752, 120.35568801149368],
        [30.312144160591142, 120.35569298298157],
        [30.31186121319104, 120.35569597412757],
        [30.311698481236867, 120.35588821010847],
        [30.31165402877656, 120.35622866272591],
        [30.31185440637294, 120.3565040370213],
        [30.31224764452733, 120.35654211707754],
        [30.312511517967295, 120.35646203974848],
        [30.31276147846229, 120.35643202252243],
        [30.31276147846229, 120.35643202252243],
        [30.31276147846229, 120.35643202252243],
        [30.31276147846229, 120.35643202252243],
        [30.31276147846229, 120.35643202252243],
        [30.31276147846229, 120.35643202252243],
        [30.31276147846229, 120.35643202252243],
        [30.31276151065063, 120.3564320196008]
    ]
    
    let beginTime: TimeStamp
    let useTime: Int
    var endTime: TimeStamp { beginTime + useTime }
    let stuID: String
    let distance: Int
    var speed: Double { Double(useTime) / 60 / (Double(distance) / 1000) }
    
    var returnString = ""
    
    var location: String {
        var outputStr = ""
        let PORTION = origin.count
        let DURATION = (Double(endTime) - Double(beginTime)) / Double(PORTION)
        
        var modified = origin
        for i in 0 ..< origin.endIndex {
            modified[1][0]  = origin[i][0] + Double.random(in: -0.000012 ... 0.000012 )
        }
        
        var time = Double(beginTime)
        for i in modified {
            outputStr += "\(i[0]),\(i[1]);\(TimeStamp(time));null;null;\(Int(DURATION));null@"
            time += DURATION
        }
        outputStr.removeLast()
        
        return outputStr
    }
    
    var data: Data { "{'begintime': '\(beginTime)', 'uid': '\(stuID)', 'schoolno': '10338', 'distance': '\(distance)', 'studentno': '\(stuID)', 'atttype': '3', 'eventno': '801', 'speed': '\(speed)', 'endtime': '\(endTime)', 'usetime': '\(useTime)', 'location': '\(location)'}".data(using: .utf8) ?? Data() }
    
    func upload() {
        print(String(data: data, encoding: .utf8)!)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["Content-Type": "application/x-www-form-urlencoded",
                                       "Content-Encoding": "gzip",
                                       "User-Agent": "Dalvik/2.1.0 (Linux; U; Android 11; RMX1931 Build/RKQ1.200928.002)",
                                       "Accept-Encoding": "gzip"]
        let task = URLSession.shared.uploadTask(with: request, from: try! data.gzipped()) { data, response, error in
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
                
            }
        }
        task.resume()
    }
}

struct TechRunnerVIew_Previews: PreviewProvider {
    static var previews: some View {
        TechRunnerView()
    }
}
