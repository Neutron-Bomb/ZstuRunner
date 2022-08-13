//
//  QRCodeView.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/7/5.
//

import SwiftUI
import QRCode

struct QRCodeView: View {
    
    @EnvironmentObject var settings: Settings
    @Environment(\.colorScheme) var colorScheme
    
    var dateFormat = "MM月dd日"
    var timeFormat = "HH:mm:ss"
    
    var qrcodeString: String { "http://e4.zstu.edu.cn/zstu/scanstudent?param1=2020316101023&param2=\(qrcodeRandomInt)" }
    @State var qrcodeRandomInt = 321820
    
    @State var date = Date()
    
    @State var dateString = "00月00日"
    @State var timeString = "00:00:00"
    
    @State var isEditing = false
    
    @State var college = UserDefaults.standard.string(forKey: "College") ?? "未知学院"
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                ScrollView {
                    ZStack {
                        // Background
                        VStack(spacing: 0) {
                            Rectangle().frame(height: proxy.size.height / 5).foregroundColor(.blue)
                            Rectangle().frame(height: 4 * proxy.size.height / 5).foregroundColor(.init(white: 0.9648))
                        }.brightness(isEditing ? -0.25 : 0)
                        
                        // Contents
                        VStack(spacing: 0) {
                            // Card View
                            VStack(spacing: 5) {
                                Text("\(dateString)\n\(timeString)").font(.largeTitle).fontWeight(.medium).multilineTextAlignment(.center).padding(.top, 5).foregroundColor(.black)
                                Divider().padding(.horizontal, 10)
                                HStack {
                                    if !isEditing {
                                        Text(college)
                                    } else {
                                        TextField("你的学院", text: $college)
                                            .colorScheme(.light)
                                            .onSubmit {
                                                UserDefaults.standard.set(college, forKey: "College")
                                            }
                                    }
                                    Spacer()
                                    if !isEditing {
                                        Text("2020316101023")
                                    } else {
                                        TextField("你的学号", text: $settings.stuID)
                                            .colorScheme(.light)
                                            .onSubmit {
                                                UserDefaults.standard.set($settings.stuID, forKey: "settings.stuID")
                                            }
                                    }
                                }.padding([.horizontal, .bottom]).foregroundColor(.black)
                                Image(uiImage: try! QRCode(string: qrcodeString, color: .init(red: 60/255, green: 112/255, blue: 236/255, alpha: 1), size: .init(width: 1024, height: 1024))!.image())
                                    .resizable().aspectRatio(contentMode: .fit).padding(.horizontal, 40)
                                HStack {
                                    Text("陈驰坤").foregroundColor(.black)
                                    Button("刷新") {
                                        qrcodeRandomInt = Int.random(in: 100000...999999)
                                    }
                                }.padding(.bottom)
                            }.frame(maxWidth: proxy.size.width)
                                .textFieldStyle(.roundedBorder)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding()
                                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.08), radius: 16)
                                .onAppear {
                                    if !isEditing {
                                        let df = DateFormatter(); let tf = DateFormatter()
                                        df.dateFormat = dateFormat; tf.dateFormat = timeFormat
                                    
                                        RunLoop.main.add(Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                                            date = Date()
                                            dateString = df.string(from: date)
                                            timeString = tf.string(from: date)
                                        }, forMode: RunLoop.Mode.common)
                                    } else {
                                        
                                    }
                                }
                            
                            // Bottom Info View
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("2021-08-31 至 2022-01-15").foregroundColor(.black)
                                    HStack {
                                        Text(" 通行码类型：").foregroundColor(.gray)
                                        Text("临时通行码").foregroundColor(.black)
                                    }
                                    HStack {
                                        Text(" 剩余次数：").foregroundColor(.gray)
                                        Text("10000").foregroundColor(.black)
                                    }
                                    HStack {
                                        Text(" 第一次刷卡时间：").foregroundColor(.gray)
                                        Text("").foregroundColor(.black)
                                    }
                                }
                                Spacer()
                            }.padding(.horizontal, 30)
                            Spacer()
                            HStack {
                                Button("通行记录", action: {})
                                Divider().frame(height: 20)
                                Button("普通码", action: {})
                            }.padding(.bottom, 20)
                        }
                    }
                }.frame(width: proxy.size.width)
            }.navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: { dismiss() }, label: { Label("", systemImage: "xmark").scaleEffect(0.8)}).foregroundColor(.primary)
                    }
                    ToolbarItem(placement: .principal) {
                        Text("学生通行码")
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: { /* isEditing.toggle() */ }, label: { Label("", systemImage: "ellipsis").scaleEffect(0.8)}).foregroundColor(.primary)
                    }
                }
                .ignoresSafeArea(.all, edges: .bottom)
        }
    }
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView()
    }
}
