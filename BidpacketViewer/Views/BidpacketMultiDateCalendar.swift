//
//  BidpacketMultiDateCalendar.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 7/13/26.
//

import SwiftUI
import UIKit

@MainActor
struct BidpacketMultiDateCalendar: UIViewRepresentable {
    @Binding var selectedDates: Set<DateComponents>

    let initialVisibleMonth: DateComponents

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        
        calendarView.clipsToBounds = true
        calendarView.layer.masksToBounds = true

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        calendarView.calendar = calendar
        calendarView.locale = Locale(identifier: "en_US")
        calendarView.fontDesign = .rounded

        let selectionBehavior = UICalendarSelectionMultiDate(
            delegate: context.coordinator
        )

        calendarView.selectionBehavior = selectionBehavior

        let normalizedSelections = selectedDates.map {
            normalizedDateComponents($0)
        }

        selectionBehavior.setSelectedDates(
            normalizedSelections,
            animated: false
        )

        calendarView.setVisibleDateComponents(
            normalizedMonthComponents(initialVisibleMonth),
            animated: false
        )

        context.coordinator.selectionBehavior = selectionBehavior

        return calendarView
    }

    func updateUIView(
        _ calendarView: UICalendarView,
        context: Context
    ) {
        context.coordinator.parent = self
        guard let selectionBehavior =
                calendarView.selectionBehavior
                as? UICalendarSelectionMultiDate else {
            return
        }

        let desiredDates = Set(
            selectedDates.map {
                normalizedDateComponents($0)
            }
        )

        let currentDates = Set(
            selectionBehavior.selectedDates.map {
                normalizedDateComponents($0)
            }
        )

        if desiredDates != currentDates {
            selectionBehavior.setSelectedDates(
                Array(desiredDates),
                animated: false
            )
        }
    }

    private func normalizedDateComponents(
        _ components: DateComponents
    ) -> DateComponents {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: components.year,
            month: components.month,
            day: components.day
        )
    }

    private func normalizedMonthComponents(
        _ components: DateComponents
    ) -> DateComponents {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: components.year,
            month: components.month,
            day: 1
        )
    }

    @MainActor
    final class Coordinator:
        NSObject,
        UICalendarSelectionMultiDateDelegate
    {
        var parent: BidpacketMultiDateCalendar
        weak var selectionBehavior: UICalendarSelectionMultiDate?

        init(parent: BidpacketMultiDateCalendar) {
            self.parent = parent
        }

        func multiDateSelection(
            _ selection: UICalendarSelectionMultiDate,
            didSelectDate dateComponents: DateComponents
        ) {
            updateBinding(from: selection)
        }

        func multiDateSelection(
            _ selection: UICalendarSelectionMultiDate,
            didDeselectDate dateComponents: DateComponents
        ) {
            updateBinding(from: selection)
        }

        private func updateBinding(
            from selection: UICalendarSelectionMultiDate
        ) {
            parent.selectedDates = Set(
                selection.selectedDates.map { components in
                    DateComponents(
                        calendar: Calendar(identifier: .gregorian),
                        timeZone: TimeZone(secondsFromGMT: 0),
                        year: components.year,
                        month: components.month,
                        day: components.day
                    )
                }
            )
        }
    }
}
