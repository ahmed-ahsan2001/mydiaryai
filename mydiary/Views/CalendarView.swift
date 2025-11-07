import SwiftUI

struct CalendarView: View {
    let store: DiaryStore
    @State private var datesWithEntries: Set<String> = []
    @State private var month: Date = Date()

    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Month Header
            HStack {
                Button(action: {
                    month = Calendar.current.date(byAdding: .month, value: -1, to: month)!
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppTheme.lightPink)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                        )
                }

                Spacer()

                Text(month, formatter: DateFormatter.monthAndYear)
                    .font(.title3.bold())
                    .foregroundColor(.appText)

                Spacer()

                Button(action: {
                    month = Calendar.current.date(byAdding: .month, value: 1, to: month)!
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.lightPink)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // MARK: - Calendar Grid
            let grid = Array(repeating: GridItem(.flexible()), count: 7)

            LazyVGrid(columns: grid, spacing: 12) {
                // Weekday headers
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption.bold())
                        .foregroundColor(.appText.opacity(0.6))
                }

                // Calendar days
                ForEach(gridDays(for: month).indices, id: \.self) { idx in
                    let cell = gridDays(for: month)[idx]
                    Group {
                        if let date = cell {
                            NavigationLink {
                                EntryView(date: date, store: store)
                            } label: {
                                VStack(spacing: 6) {
                                    Text("\(Calendar.current.component(.day, from: date))")
                                        .font(.subheadline)
                                        .foregroundColor(.appText)

                                    Circle()
                                        .fill(AppTheme.lightPink)
                                        .frame(width: 6, height: 6)
                                        .opacity(datesWithEntries.contains(key(for: date)) ? 1 : 0)
                                }
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                        } else {
                            Color.clear.frame(height: 48)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)

            Spacer()
        }
        .background(Color(red: 0.99, green: 0.98, blue: 0.95).ignoresSafeArea())
        .navigationTitle("Calendar")
        .task {
            let entries = (try? await store.loadAll()) ?? []
            datesWithEntries = Set(entries.map { key(for: $0.date) })
        }
    }

    private var weekdays: [String] { DateFormatter.shortWeekdaySymbols }

    private func key(for date: Date) -> String {
        let comp = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(comp.year!)-\(comp.month!)-\(comp.day!)"
    }

    private func gridDays(for date: Date) -> [Date?] {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: date)!
        let comps = cal.dateComponents([.year, .month], from: date)
        let start = cal.date(from: DateComponents(year: comps.year, month: comps.month, day: 1))!
        let firstWeekday = cal.component(.weekday, from: start)
        let offset = ((firstWeekday - cal.firstWeekday) + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: offset)
        for d in range { cells.append(cal.date(byAdding: .day, value: d - 1, to: start)!) }
        return cells
    }
}

private extension DateFormatter {
    static let monthAndYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    static var shortWeekdaySymbols: [String] {
        let f = DateFormatter()
        return f.shortStandaloneWeekdaySymbols
    }
}

