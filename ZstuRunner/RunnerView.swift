//
//  RunnerView.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/7/9.
//

import SwiftUI
import CoreLocation
import _MapKit_SwiftUI

struct RunnerView: View {
    
    class Delegate: NSObject, CLLocationManagerDelegate {
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            print(locations)
        }
    }
    
    typealias Meter = Double
    @Environment(\.dismiss) private var dismiss // Button("Back", action: {dismiss()})
    @State private var selection = 1
    
//    @State var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 30.3123, longitude: 120.3564),
//                                           latitudinalMeters: 360, longitudinalMeters: 360)
    
    @State var timer: Timer? = nil
    
    @State var ready = 3
    @State var isReady = false
    
    @State var mapOpacity: Double = 1
    
    @State var finishCheck = false
    
    @State var hour: Int = 0
    @State var minute: Int = 0
    @State var second: Int = 0
    @State var msec: Int = 0
    
    @State var jumpToSummary: Int? = -2
    
    @StateObject var manager = LocationManager()
    @State var tracking: MapUserTrackingMode = .follow
    
    @State var distance: Meter = 0
    var speed_average: Double {
        if hour == minute && minute == second && second == 0 {
            return 0
        } else {
            return distance / (Double(hour) * 3600 + Double(minute) * 60 + Double(second))
        }
    }
    var speed_current: Double {
        if hour == minute && minute == second && second == 0 {
            return 0
        } else {
            return distance / (Double(hour) * 3600 + Double(minute) * 60 + Double(second))
        }
    }
    
//    struct Coordinate {
//        let timeStamp: Double
//        let latitude: Double
//        let longitude: Double
//    }
//    @State var coordinates = [Coordinate]()
    
    func pause() {
        mapOpacity = 0.5
        timer?.invalidate()
        timer = nil
    }
    func resume() {
        mapOpacity = 1
        startTrackingTimer()
    }
    
    var control: some View {
        VStack {
            HStack {
                if mapOpacity == 1 {
                    Button(action: { pause() }) { Label("RUN_PAUSE", systemImage: "pause.circle")}.buttonStyle(.bordered).foregroundColor(.yellow)
                } else {
                    Button(action: { resume() }) { Label("RUN_RESUME", systemImage: "play.circle")}.buttonStyle(.bordered).foregroundColor(.green)
                }
                Spacer()
                Button(action: { pause(); finishCheck.toggle() }) { Label("RUN_FINISH", systemImage: "stop.circle")}.buttonStyle(.bordered).foregroundColor(.red)
                    .alert("RUN_FINISH_CHECK", isPresented: $finishCheck) {
                        Button("RUN_FINISH_CHECK_CANCEL", role: .cancel, action: { resume() })
                        Button("RUN_FINISH_CHECK_OK") { jumpToSummary = -1 }
                    }
            }
        }
    }
    
    var overview: some View {
        VStack {
            if isReady {
                VStack {
                    HStack {
                        Text("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%02d", msec))")
                            .bold().font(.title2).frame(width: 140)
                        Text("RUN_TIME").font(.footnote)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Text("\(String(format: "%.01f", manager.distance)) m").bold().font(.title)
                        Text("RUN_DIST").font(.footnote)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Text("\(String(format: "%.01f", manager.speed_average)) m/s").bold().font(.title)
                        Text("RUN_SPEED_AVERAGE").font(.footnote)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Text("\(String(format: "%.01f", manager.speed_current)) m/s").bold().font(.title)
                        Text("RUN_SPEED_CURRENT").font(.footnote)
                        Spacer()
                    }
                }.padding()
//                    .onAppear { startTrackingTimer() } // 有奇怪的bug，使用之后会出现加速问题
                    .onAppear {
                        // 实现Delegate
                        
                    }
            } else {
                VStack {
                    Spacer()
                    if ready != 0 {
                        Text("\(ready)").bold().font(.largeTitle)
                    } else {
                        Text("Go!").bold().font(.largeTitle)
                    }
                    Spacer()
                    Button(action: { dismiss() }, label: { Text("RUN_CANCEL").font(.footnote) }).padding(.bottom)
                }
            }
        }
    }
    
    var test: some View {
        Text("?")
    }
    
    func setTimer() {
        timer = Timer(timeInterval: 1.0, repeats: true) { tempTimer in
            ready -= 1
            if ready < 0 {
                timer?.invalidate()
                timer = nil
                isReady = true
                startTrackingTimer()
            }
        }
        RunLoop.main.add(timer!, forMode: RunLoop.Mode.common)
    }
    
    func resetTimer() {
        ready = 0
        timer?.invalidate()
        timer = nil
        setTimer()
    }
    
    func startTrackingTimer() {
        timer = Timer(timeInterval: 0.01, repeats: true) { tempTimer in
            if msec < 0 {
                msec = 0
            } else if msec < 99 {
                msec += 1
            } else if msec == 99 {
                msec = 0
                if second < 0 {
                    second = 0
                } else if second < 59 {
                    second += 1
                } else if second == 59 {
                    second = 0
                    if minute < 0 {
                        minute = 0
                    } else if minute < 59 {
                        minute += 1
                    } else if minute == 59 {
                        minute = 0
                        if hour < 0 {
                            hour = 0
                        } else if second < 59 {
                            hour += 1
                        } else {
                            exit(1)
                        }
                    } else {
                        minute = 0
                    }
                } else {
                    second = 0
                }
            } else {
                msec = 0
            }
        }
        timer?.tolerance = 0.001
        RunLoop.main.add(timer!, forMode: RunLoop.Mode.common)
    }
    
    var summary: some View {
        VStack {
            Spacer().frame(height: UIScreen.main.bounds.height / 10)
            Text("Well Done!").font(.largeTitle).padding(.bottom)
            VStack(spacing: 20) {
                HStack {
                    Text("Distance")
                    Spacer()
                    Text("10km")
                }
                HStack {
                    Text("Time")
                    Spacer()
                    Text("45min")
                }
                HStack {
                    Text("Average Speed")
                    Spacer()
                    Text("4.5min/km")
                }
                HStack {
                    Text("Upload Data")
                    Spacer()
                    Text("Valid")
                }
            }.padding(.horizontal)
            Spacer()
            VStack(spacing: 30) {
                Button("Exit") { dismiss() }.foregroundColor(.red)
                Button("Start a new tracker") { dismiss() }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Map(
                   coordinateRegion: $manager.region,
                   interactionModes: MapInteractionModes.all,
                   showsUserLocation: true,
                   userTrackingMode: $tracking
                )
                    .edgesIgnoringSafeArea([.top, .bottom])
                    .opacity(mapOpacity)
                    .overlay {
                        VStack {
                            Spacer()
                            TabView(selection: $selection) {
                                Section {
                                    control.tag(0)
                                    overview.tag(1)
                                    test.tag(2)
                                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding([.trailing, .leading, .top])
                                    .onTapGesture {
                                        if !isReady {
                                            resetTimer()
                                        }
                                    }
                            }.tabViewStyle(.page)
                                .frame(height: UIScreen.main.bounds.size.height / 2.8)
                        }.edgesIgnoringSafeArea([.top, .bottom])
                    }
                NavigationLink("RUN_FINISH_CHECK_OK", tag: -1, selection: $jumpToSummary, destination: { summary.navigationBarBackButtonHidden() }).hidden()
            }.edgesIgnoringSafeArea([.top, .bottom])
                .onAppear {
                    setTimer()
                }
        }
    }
    
}

struct RunnerView_Previews: PreviewProvider {
    static var previews: some View {
        RunnerView()
    }
}
