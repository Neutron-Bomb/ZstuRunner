//
//  ZstuRunnerWidget.swift
//  ZstuRunnerWidget
//
//  Created by 陈驰坤 on 2022/7/5.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

// MARK: - QRCode Widget
struct QRCodeWidgetEntryView : View {
    var entry: Provider.Entry
    var body: some View {
//        Text(entry.date, style: .time)
        VStack {
            HStack {
                Image(systemName: "qrcode").resizable().aspectRatio(contentMode: .fit).foregroundColor(.secondary)
                Text("Haren").bold().font(.title2)
            }
            Spacer()
            Text(LocalizedStringKey("显示校园码")).foregroundColor(.accentColor)
        }
        .padding()
        .widgetURL(URL(string: "okay")!)
    }
}


struct QRCodeWidget: Widget {
    let kind: String = "QRCode Widget"
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            QRCodeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("校园码快捷展示")
        .description("快速展示微信校园码")
    }
}

// MARK: - SWAEService Widget
struct SWAEServiceWidgetEntryView: View {
    var entry: Provider.Entry
    var body: some View {
        HStack {
            VStack {
                HStack {
                    Circle()
                    VStack {
                        Text("更新时间:").font(.footnote).bold()
                        Text("2022-7-24")
                    }
                }
                Divider()
                Spacer()
                HStack {
                    Text("已用:").font(.footnote).bold()
                    Text("3038度")
                    Spacer()
                    Divider().frame(height: 30)
                    Spacer()
                    Text("剩余:").font(.footnote).bold()
                    Text("4.43度")
                }
            }.padding()
        }.background(Color.mint)
            .foregroundColor(.white)
    }
}

struct SWAEServiceWidget: Widget {
    let kind: String = "SWAEService Widget"
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            SWAEServiceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("寝室电费查询")
        .description("寝室电费余额及使用情况一览")
    }
}

// MARK: - Life Cycle
@main
struct ZstuRunnerWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        QRCodeWidget()
        SWAEServiceWidget()
    }
}


struct ZstuRunnerWidget_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.locale, .init(identifier: "zh-Hans"))
        SWAEServiceWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.locale, .init(identifier: "zh-Hans"))
    }
}
