//
//  MyPrefencesView.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/8/9.
//

import SwiftUI

struct MyPrefencesView: View {
    
    @EnvironmentObject var settings: Settings
    @Environment (\.dismiss) var dismiss
    
        var body: some View {
            List {
                Section {
                    HStack {
                        Text("CHANGE_USERNAME")
                        Spacer()
                        TextField("", text: $settings.username).multilineTextAlignment(.trailing)
                            .onSubmit {
                                UserDefaults.standard.set(settings.username, forKey: "Username")
                            }
                    }
                }
                Section {
                    NavigationLink("CHANGE_PASSWORD", destination: { Password(.change).navigationBarTitleDisplayMode(.inline) })
                    NavigationLink("FIND_PASSWORD", destination: {Password(.reset).navigationBarTitleDisplayMode(.inline) })
                }
                
                Section {
                    Button("Logout", action: {
                        dismiss()
                        settings.isLogged = false
                    }).foregroundColor(.red)
                }
            }.navigationTitle("MY_SETTINGS")
        }
}

struct MyPrefencesView_Previews: PreviewProvider {
    static var previews: some View {
        MyPrefencesView()
    }
}
