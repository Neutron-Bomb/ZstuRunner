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

struct ZstuRunnerWidgetEntryView : View {
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

@main
struct ZstuRunnerWidget: Widget {
    let kind: String = "ZstuRunnerWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            ZstuRunnerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("校园码快捷展示")
        .description("快速展示微信校园码")
    }
}

struct ZstuRunnerWidget_Previews: PreviewProvider {
    static var previews: some View {
        ZstuRunnerWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.locale, .init(identifier: "zh-Hans"))
    }
}
