import SwiftUI
import Combine

/// Custom month calendar grid — replaces the system graphical `DatePicker` so
/// each date cell can show small colored dots for its scheduled activities.
/// Laid out as one solid white `farmCard()` holding the weekday header row
/// and every week row together, with square (equal width/height) date cells
/// and no internal grid lines. The selected date renders as a solid green
/// filled circle with a bold white number; today (when not the selection)
/// instead gets just a green outline ring. Tapping any date — including an
/// adjacent-month day, which also switches the visible month — selects it.
/// Colors here are `CalendarTheme` (green), scoped to the Calendar tab only.
struct MonthCalendarGridView: View {
    @Binding var selectedDate: Date
    let activities: [FarmActivity]
    let calendar: Calendar

    @State private var displayedMonth: Date
    /// Measured width of the table card — cell size is derived from this so
    /// each of the 7 columns is square (width == height), not just equal-width.
    @State private var gridWidth: CGFloat = 0
    /// The day the grid treats as "today". Held as `@State` rather than read
    /// fresh per render because SwiftUI has no reason to re-render when the
    /// clock crosses midnight — it is re-read on appear and on every system
    /// significant-time-change (midnight, timezone change, manual clock edit).
    @State private var today: Date = Date()

    private let headerRowHeight: CGFloat = 36

    init(selectedDate: Binding<Date>, activities: [FarmActivity], calendar: Calendar) {
        _selectedDate = selectedDate
        self.activities = activities
        self.calendar = calendar
        _displayedMonth = State(initialValue: selectedDate.wrappedValue)
    }

    private var cellSize: CGFloat { gridWidth / 7 }

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            monthHeader
            VStack(spacing: 0) {
                weekdayHeaderRow
                ForEach(Array(weeksInGrid.enumerated()), id: \.offset) { _, week in
                    weekRow(week)
                }
            }
            // `maxWidth: .infinity` gives this its own width (from the parent
            // layout) independent of `cellSize` — every cell below is sized
            // FROM `cellSize`, so without this the container has nothing to
            // claim a width with and the whole grid collapses to zero.
            .frame(maxWidth: .infinity)
            .farmCard()
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { gridWidth = proxy.size.width }
                        .onChange(of: proxy.size.width) { gridWidth = $0 }
                }
            )
        }
        .onAppear { today = Date() }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.significantTimeChangeNotification)) { _ in
            today = Date()
        }
        // A rollover can move "today" into the next month; bring the visible
        // month along with the selection so the new today is actually on screen.
        .onChange(of: selectedDate) { newValue in
            if !calendar.isDate(newValue, equalTo: displayedMonth, toGranularity: .month) {
                displayedMonth = newValue
            }
        }
    }

    // MARK: - Header

    private var monthHeader: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(CalendarTheme.deepGreen)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(BorderlessButtonStyle())

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(CalendarTheme.deepGreen)
                Text(LocalizedDate.monthYearString(displayedMonth))
                    .font(Theme.Fonts.heading)
                    .fontWeight(.bold)
                    .foregroundColor(CalendarTheme.deepGreen)
            }

            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(CalendarTheme.deepGreen)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }

    /// Top row of the table: full weekday names, columns matching the date
    /// cells below (no dividers between them).
    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(CalendarTheme.farmGreenDark)
                    .frame(width: cellSize, height: headerRowHeight)
            }
        }
    }

    private var weekdaySymbols: [String] {
        LocalizedDate.weekdayHeaderFullNames(firstWeekday: calendar.firstWeekday)
    }

    // MARK: - Week row

    private func weekRow(_ week: [GridDay]) -> some View {
        HStack(spacing: 0) {
            ForEach(week) { day in
                dayCell(for: day)
            }
        }
    }

    // MARK: - Day cell

    /// One square grid cell, always a real date — either in `displayedMonth`
    /// (full color, tappable to select) or in the adjacent month (shown in
    /// light gray, still tappable: tapping it jumps the grid to that month).
    private func dayCell(for day: GridDay) -> some View {
        let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
        // "Today" is a day-granularity comparison in the device's own calendar
        // and timezone — never `==` on two `Date` values, which still carry a
        // time component and so would never match.
        let isToday = calendar.isDate(day.date, inSameDayAs: today)
        // Today only gets its outline ring when it isn't also the selection —
        // the selected day always wins with a solid fill.
        let isTodayRing = isToday && !isSelected
        let isEmphasized = isSelected || isToday
        let categories = categoriesByDay[calendar.startOfDay(for: day.date)] ?? []
        let circleSize = max(28, min(38, cellSize - 14))

        return VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: day.date))")
                .font(.system(size: isEmphasized ? 17 : 16, weight: isEmphasized ? .bold : .semibold))
                .foregroundColor(dayNumberColor(isSelected: isSelected, isTodayRing: isTodayRing, isInCurrentMonth: day.isInCurrentMonth))
                .frame(width: circleSize, height: circleSize)
                .background(Circle().fill(isSelected ? CalendarTheme.farmGreen : Color.clear))
                .overlay(
                    Circle().stroke(CalendarTheme.farmGreen, lineWidth: isTodayRing ? 2 : 0)
                )

            HStack(spacing: 3) {
                ForEach(Array(categories.prefix(3).enumerated()), id: \.offset) { _, category in
                    Circle()
                        .fill(category.calendarAccent)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(width: cellSize, height: cellSize)
        .contentShape(Rectangle())
        .onTapGesture {
            if !day.isInCurrentMonth {
                displayedMonth = day.date
            }
            selectedDate = day.date
        }
    }

    private func dayNumberColor(isSelected: Bool, isTodayRing: Bool, isInCurrentMonth: Bool) -> Color {
        if isSelected { return .white }
        if isTodayRing { return CalendarTheme.farmGreen }
        return isInCurrentMonth ? CalendarTheme.farmText : CalendarTheme.farmSubtext.opacity(0.45)
    }

    // MARK: - Data

    /// Unique scheduled-activity categories per day, in `FarmActivityCategory.allCases`
    /// order — drives the small colored dots shown below each date's number.
    private var categoriesByDay: [Date: [FarmActivityCategory]] {
        var categoriesByDay: [Date: Set<FarmActivityCategory>] = [:]
        for activity in activities {
            let day = calendar.startOfDay(for: activity.date)
            categoriesByDay[day, default: []].insert(activity.category)
        }
        return categoriesByDay.mapValues { categories in
            FarmActivityCategory.allCases.filter { categories.contains($0) }
        }
    }

    /// A single grid cell's date plus whether it falls in `displayedMonth` —
    /// dates outside the month are still shown (in gray), not blanked out.
    private struct GridDay: Identifiable {
        let date: Date
        let isInCurrentMonth: Bool
        var id: Date { date }
    }

    /// 6 full weeks (42 days) starting on the grid week that contains the
    /// month's 1st, grouped into rows, then any trailing week made up
    /// entirely of next-month days is dropped so the grid doesn't show two
    /// blank extra rows for a 4-week month — matching how a standard
    /// calendar lays out overflow days.
    private var weeksInGrid: [[GridDay]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        var days: [Date] = []
        var current = firstWeek.start
        for _ in 0..<42 {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        let cells: [GridDay] = days.map { day in
            GridDay(date: day, isInCurrentMonth: calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month))
        }

        var weeks = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<min($0 + 7, cells.count)]) }
        weeks.removeAll { week in !week.contains { $0.isInCurrentMonth } }
        return weeks
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

struct MonthCalendarGridView_Previews: PreviewProvider {
    static var previews: some View {
        MonthCalendarGridView(
            selectedDate: .constant(Date()),
            activities: [
                FarmActivity(title: "Water", date: Date(), category: .watering),
                FarmActivity(title: "Fertilize", date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(), category: .fertilizing)
            ],
            calendar: .current
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
