import SwiftUI

struct BrowseWorkspaceView: View {
    @Bindable var viewModel: BidpacketViewModel
    
    

    @State private var expandedRotationIDs: Set<String> = []
    @State private var searchText = ""
    @State private var showingSelectedOnly = false
    @State private var showScrollToTop = false
    @State private var selectedSort: RotationSortOption = .rotationNumber
    @State private var sortAscending = true
    @State private var isHeaderCollapsed = false
    @State private var dateToAdd = Date()

    private let topAnchorID = "top"

    private var sourceRotations: [Rotation] {
        if showingSelectedOnly {
            return viewModel.filteredRotations.filter {
                viewModel.selectedRotationIDs.contains($0.id)
            }
        }

        return viewModel.filteredRotations
    }
    
    private var filteredRotations: [Rotation] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filtered = sourceRotations.filter { rotation in
            text.isEmpty ||
            rotation.rotationNumber.localizedCaseInsensitiveContains(text) ||
            rotation.overnights?.localizedCaseInsensitiveContains(text) == true ||
            rotation.rawChunkText?.localizedCaseInsensitiveContains(text) == true ||
            rotation.effectiveDates?.joined(separator: " ").localizedCaseInsensitiveContains(text) == true
        }

        return selectedSort.sort(
            filtered,
            selectedIDs: viewModel.selectedRotationIDs,
            ascending: sortAscending
        )
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    frozenTopSection

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Color.clear
                                .frame(height: 1)
                                .id(topAnchorID)
                                .background(scrollOffsetReader)

                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .foregroundStyle(.red)
                                    .padding()
                                    .background(.red.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            rotationCardsSection
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 18)
                    }
                    .coordinateSpace(name: "scroll")
                }

                if showScrollToTop {
                    Button {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(topAnchorID, anchor: .top)
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(.blue)
                            .clipShape(Circle())
                            .shadow(radius: 8)
                    }
                    .padding(.trailing, 32)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Browse")
    }

    private var frozenTopSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.primaryBase) \(viewModel.bidpacket?.aircraft ?? "Unknown Aircraft")")
                        .font(.system(size: isHeaderCollapsed ? 22 : 34, weight: .bold))

                    if !isHeaderCollapsed,
                       let month = viewModel.bidpacket?.bidpacketMonth,
                       let year = viewModel.bidpacket?.bidpacketYear {
                        Text(monthName(month) + " " + String(year))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if !isHeaderCollapsed {
                    metricBlock(title: "Rotations", value: "\(viewModel.rotationCount)")
                    metricBlock(title: "Instances", value: "\(viewModel.instanceCount)")
                    metricBlock(title: "Selected", value: "\(viewModel.selectedCount)")
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHeaderCollapsed.toggle()
                    }
                } label: {
                    Image(systemName: isHeaderCollapsed ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if !isHeaderCollapsed {
                HStack(spacing: 14) {
                    searchSection

                    Picker("View Mode", selection: $showingSelectedOnly) {
                        Text("All").tag(false)
                        Text("Selected").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                }

                VStack(alignment: .leading, spacing: 10) {
                    dayFilterChips
                    dateFilterSection
                    operationalFilterChips
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, isHeaderCollapsed ? 10 : 18)
        .background(.regularMaterial)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.separator),
            alignment: .bottom
        )
    }
    
    private var dateFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("Touches Dates")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Mode", selection: $viewModel.filters.touchDateMode) {
                    ForEach(TouchDateFilterMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                DatePicker(
                    "",
                    selection: $dateToAdd,
                    displayedComponents: .date
                )
                .labelsHidden()

                Button("Add Date") {
                    addTouchDate(dateToAdd)
                }

                if !viewModel.filters.touchDateStrings.isEmpty {
                    Button("Clear Dates") {
                        viewModel.filters.touchDateStrings.removeAll()
                    }
                    .font(.subheadline)
                }
            }

            if !viewModel.filters.touchDateStrings.isEmpty {
                HStack(spacing: 8) {
                    ForEach(sortedTouchDateStrings, id: \.self) { dateString in
                        Button {
                            viewModel.filters.touchDateStrings.remove(dateString)
                        } label: {
                            Label(displayDate(dateString), systemImage: "xmark.circle.fill")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var sortedTouchDateStrings: [String] {
        viewModel.filters.touchDateStrings.sorted()
    }

    private func addTouchDate(_ date: Date) {
        viewModel.filters.touchDateStrings.insert(dateString(date))
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func displayDate(_ dateString: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"

        guard let date = input.date(from: dateString) else {
            return dateString
        }

        let output = DateFormatter()
        output.dateFormat = "MMM d"
        return output.string(from: date)
    }
    
    private var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search rotations, layovers, dates, or bid text", text: $searchText)
                .textFieldStyle(.plain)
                .font(.headline)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }

    private var dayFilterChips: some View {
        HStack(spacing: 8) {
            Text("Days")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach([1, 2, 3, 4, 5], id: \.self) { days in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        toggleDayLength(days)
                    }
                } label: {
                    Text(days == 5 ? "5+" : "\(days)")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            isDayLengthSelected(days)
                            ? .blue
                            : Color(.secondarySystemGroupedBackground)
                        )
                        .foregroundStyle(isDayLengthSelected(days) ? .white : .primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if viewModel.filters.hasActiveFilters {
                Button("Clear Filters") {
                    viewModel.filters.clearAll()
                }
                .font(.subheadline)
            }
        }
    }
    
    private var operationalFilterChips: some View {
        HStack(spacing: 8) {
            Text("Ops")
                .font(.caption)
                .foregroundStyle(.secondary)

            filterChip("Red-eye", isOn: viewModel.filters.redEyeOnly) {
                viewModel.filters.redEyeOnly.toggle()
            }

            filterChip("Day Layover", isOn: viewModel.filters.dayLayoverOnly) {
                viewModel.filters.dayLayoverOnly.toggle()
            }

            filterChip("Cross-town", isOn: viewModel.filters.crossTownOnly) {
                viewModel.filters.crossTownOnly.toggle()
            }

            filterChip("Starts DH", isOn: viewModel.filters.startsDeadheadOnly) {
                viewModel.filters.startsDeadheadOnly.toggle()
            }

            filterChip("Ends DH", isOn: viewModel.filters.endsDeadheadOnly) {
                viewModel.filters.endsDeadheadOnly.toggle()
            }
        }
    }
    
    private func filterChip(
        _ title: String,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                action()
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isOn ? .blue : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(isOn ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private func toggleDayLength(_ days: Int) {
        if days == 5 {
            toggleFivePlusDayLength()
            return
        }

        if viewModel.filters.selectedDayLengths.contains(days) {
            viewModel.filters.selectedDayLengths.remove(days)
        } else {
            viewModel.filters.selectedDayLengths.insert(days)
        }
    }

    private func toggleFivePlusDayLength() {
        let fivePlus = Set([5, 6, 7, 8, 9, 10])

        if !viewModel.filters.selectedDayLengths.isDisjoint(with: fivePlus) {
            viewModel.filters.selectedDayLengths.subtract(fivePlus)
        } else {
            viewModel.filters.selectedDayLengths.formUnion(fivePlus)
        }
    }

    private func isDayLengthSelected(_ days: Int) -> Bool {
        if days == 5 {
            return viewModel.filters.selectedDayLengths.contains { $0 >= 5 }
        }

        return viewModel.filters.selectedDayLengths.contains(days)
    }
    
    private var rotationCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(sectionTitle)
                    .font(.title2)
                    .bold()

                Text("\(filteredRotations.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    ForEach(RotationSortOption.allCases) { option in
                        Button {
                            selectedSort = option
                        } label: {
                            if selectedSort == option {
                                Label(option.title, systemImage: "checkmark")
                            } else {
                                Text(option.title)
                            }
                        }
                    }

                    Divider()

                    Button {
                        sortAscending.toggle()
                    } label: {
                        Label(
                            sortAscending ? "Ascending" : "Descending",
                            systemImage: sortAscending ? "arrow.up" : "arrow.down"
                        )
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }

                Button("Expand All") {
                    expandedRotationIDs = Set(filteredRotations.map { $0.id })
                }

                Button("Collapse All") {
                    expandedRotationIDs.removeAll()
                }
            }

            if filteredRotations.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredRotations) { rotation in
                        RotationCardView(
                            rotation: rotation,
                            isExpanded: expandedRotationIDs.contains(rotation.id),
                            isSelected: viewModel.isSelected(rotation),
                            onToggleExpanded: {
                                if expandedRotationIDs.contains(rotation.id) {
                                    expandedRotationIDs.remove(rotation.id)
                                } else {
                                    expandedRotationIDs.insert(rotation.id)
                                }
                            },
                            onToggleSelected: {
                                viewModel.toggleSelected(rotation)
                            }
                        )
                    }
                }
            }
        }
    }

    private var sectionTitle: String {
        if showingSelectedOnly {
            return searchText.isEmpty ? "Selected Rotations" : "Selected Search Results"
        } else {
            return searchText.isEmpty ? "Rotations" : "Search Results"
        }
    }

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 10) {
            Text(showingSelectedOnly ? "No selected rotations" : "No rotations found")
                .font(.headline)

            Text("Try changing your search or day filter.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func metricBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .bold))
        }
        .frame(minWidth: 90, alignment: .leading)
    }

    private var scrollOffsetReader: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geo.frame(in: .named("scroll")).minY
                )
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.2)) {
                showScrollToTop = value < -300
            }
        }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: month, day: 1))
        return date.map { formatter.string(from: $0) } ?? "\(month)"
    }
}

private enum RotationSortOption: String, CaseIterable, Identifiable {
    case rotationNumber
    case days
    case credit
    case firstStartDate
    case selectedFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rotationNumber: return "Rotation Number"
        case .days: return "Days"
        case .credit: return "Credit"
        case .firstStartDate: return "First Start Date"
        case .selectedFirst: return "Selected First"
        }
    }

    func sort(
        _ rotations: [Rotation],
        selectedIDs: Set<String>,
        ascending: Bool
    ) -> [Rotation] {
        let sorted: [Rotation]

        switch self {
        case .rotationNumber:
            sorted = rotations.sorted {
                $0.rotationNumber.localizedStandardCompare($1.rotationNumber) == .orderedAscending
            }

        case .days:
            sorted = rotations.sorted {
                ($0.numDays ?? 0, $0.rotationNumber) < ($1.numDays ?? 0, $1.rotationNumber)
            }

        case .credit:
            sorted = rotations.sorted {
                ($0.totalCredit?.minutes ?? 0, $0.rotationNumber) < ($1.totalCredit?.minutes ?? 0, $1.rotationNumber)
            }

        case .firstStartDate:
            sorted = rotations.sorted {
                ($0.effectiveDates?.first ?? "9999-99-99", $0.rotationNumber) <
                ($1.effectiveDates?.first ?? "9999-99-99", $1.rotationNumber)
            }

        case .selectedFirst:
            sorted = rotations.sorted {
                let leftSelected = selectedIDs.contains($0.id)
                let rightSelected = selectedIDs.contains($1.id)

                if leftSelected != rightSelected {
                    return leftSelected && !rightSelected
                }

                return $0.rotationNumber.localizedStandardCompare($1.rotationNumber) == .orderedAscending
            }
        }

        if self == .selectedFirst {
            return sorted
        }

        return ascending ? sorted : sorted.reversed()
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
