//
//  DashboardView.swift
//  ZstuRunner
//
//  Created by 陈驰坤 on 2022/11/11.
//

import SwiftUI

struct DashboardView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section("CURRENT_TERM_TOTAL_MILEAGE") {
                    DashboardPanelView("TOTAL_MILEAGE", a: viewModel.areaFinished + viewModel.orieFinished, b: viewModel.mileageTarget, parameter: "km").padding()
                    HStack {
                        Text("ORIENTATE_DIST")
                        Spacer()
                        Text("\(String(format: "%.01f", viewModel.orieFinished))km")
                    }
                    HStack {
                        Text("AREA_DIST")
                        Spacer()
                        Text("\(String(format: "%.01f", viewModel.areaFinished))km")
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
                    HStack {
                        if viewModel.refreshing {
                            ProgressView().padding(.trailing, 4)
                        }
                        Button("_REFRESH") {
                            Task { await viewModel.fetchRunData() }
                        }.disabled(viewModel.refreshing)
                    }
                }.alert("ID_EMPTY", isPresented: $viewModel.alertStuIDEmpty) {
                    Button("Dismiss", role: .cancel) {}
                }
                .alert("Timeout", isPresented: $viewModel.alertTimeout) {
                    Button("Dismiss", role: .cancel) {}
                }
            }.navigationTitle("_OVERVIEW")
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
