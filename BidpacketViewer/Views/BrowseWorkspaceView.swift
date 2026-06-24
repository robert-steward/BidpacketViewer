import SwiftUI

struct BrowseWorkspaceView: View {
    @Bindable var viewModel: BidpacketViewModel

    @State private var expandedRotationIDs: Set<String> = []
    @State private var searchText = ""
    @State private var showingSelectedOnly = false
    @State private var showScrollToTop = false
    @State private var selectedSorts: [RotationSortOption] = [.rotationNumber]
    @State private var sortAscending = true
    @State private var isHeaderCollapsed = false
    @State private var showingFilters = false
    @State private var showingSortOptions = false
    @State private var selectedExportURL: URL?

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

        return RotationSortOption.sort(
            filtered,
            by: selectedSorts,
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
                    Text("\(viewModel.primaryBase) \(viewModel.aircraft)")
                        .font(.system(size: isHeaderCollapsed ? 22 : 34, weight: .bold))

                    if !isHeaderCollapsed {
                        Text(viewModel.bidpacketName ?? "Bidpacket")
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

                    Button {
                        showingFilters = true
                    } label: {
                        Label(filterButtonTitle, systemImage: "line.3.horizontal.decrease.circle")
                            .font(.headline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.filters.hasActiveFilters
                                ? Color.blue.opacity(0.14)
                                : Color(.secondarySystemGroupedBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingFilters) {
                        FilterPanelView(viewModel: viewModel)
                    }
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

    private var rotationCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Text(sectionTitle)
                    .font(.title2)
                    .bold()

                Text("\(filteredRotations.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    showingSortOptions = true
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                .popover(isPresented: $showingSortOptions) {
                    sortOptionsPopover
                }

                toolbarDivider

                Button("Select") {
                    for rotation in filteredRotations {
                        viewModel.selectedRotationIDs.insert(rotation.id)
                    }
                }

                Button("Deselect") {
                    let visibleIDs = Set(filteredRotations.map { $0.id })
                    viewModel.selectedRotationIDs.subtract(visibleIDs)
                }

                toolbarDivider

                Button("Export") {
                    selectedExportURL = makeSelectedRotationsExportFile()
                }
                .disabled(viewModel.selectedRotations.isEmpty)

                toolbarDivider

                Button("Expand") {
                    expandedRotationIDs = Set(filteredRotations.map { $0.id })
                }

                Button("Collapse") {
                    expandedRotationIDs.removeAll()
                }
            }
            .font(.subheadline)

            if let selectedExportURL {
                ShareLink(
                    item: selectedExportURL,
                    preview: SharePreview("Selected Rotations")
                ) {
                    Label("Share Export File", systemImage: "square.and.arrow.up")
                }
            }

            if filteredRotations.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredRotations) { rotation in
                        RotationCardView(
                            rotation: rotation,
                            selectedSorts: selectedSorts,
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

    private var sortOptionsPopover: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        sortAscending.toggle()
                    } label: {
                        Label(
                            sortAscending ? "Ascending" : "Descending",
                            systemImage: sortAscending ? "arrow.up" : "arrow.down"
                        )
                    }
                }

                Section("Sort Priority") {
                    ForEach(RotationSortOption.allCases) { option in
                        Button {
                            toggleSortOption(option)
                        } label: {
                            HStack {
                                Text(option.title)

                                Spacer()

                                if let index = selectedSorts.firstIndex(of: option) {
                                    Text("\(index + 1)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(.blue)
                                        .clipShape(Circle())

                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section {
                    Button("Reset to Rotation Number") {
                        selectedSorts = [.rotationNumber]
                    }
                }
            }
            .navigationTitle("Sort Rotations")
            .navigationBarTitleDisplayMode(.inline)
            .frame(width: 380, height: 640)
        }
    }

    private func toggleSortOption(_ option: RotationSortOption) {
        if let index = selectedSorts.firstIndex(of: option) {
            selectedSorts.remove(at: index)

            if selectedSorts.isEmpty {
                selectedSorts = [.rotationNumber]
            }
        } else {
            selectedSorts.append(option)
        }
    }

    private var toolbarDivider: some View {
        Divider()
            .frame(height: 18)
    }

    private var filterButtonTitle: String {
        let count = activeFilterCount
        return count == 0 ? "Filters" : "Filters (\(count))"
    }

    private var activeFilterCount: Int {
        var count = 0

        count += viewModel.filters.selectedDayLengths.isEmpty ? 0 : 1
        count += viewModel.filters.redEyeOnly ? 1 : 0
        count += viewModel.filters.dayLayoverOnly ? 1 : 0
        count += viewModel.filters.crossTownOnly ? 1 : 0
        count += viewModel.filters.startsDeadheadOnly ? 1 : 0
        count += viewModel.filters.endsDeadheadOnly ? 1 : 0
        count += viewModel.filters.fullyCommutableOnly ? 1 : 0
        count += viewModel.filters.commuteInOnly ? 1 : 0
        count += viewModel.filters.commuteHomeOnly ? 1 : 0
        count += viewModel.filters.touchDateStrings.isEmpty ? 0 : 1

        return count
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

    private func makeSelectedRotationsExportFile() -> URL? {
        let selected = viewModel.selectedRotations.sorted {
            $0.rotationNumber.localizedStandardCompare($1.rotationNumber) == .orderedAscending
        }

        guard !selected.isEmpty else {
            return nil
        }

        let header = """
        BidpacketViewer Selected Rotations
        Packet: \(viewModel.bidpacketName ?? "Unknown")
        Base/Aircraft: \(viewModel.primaryBase) \(viewModel.aircraft)
        Selected Rotations: \(selected.count)
        Exported: \(Date().formatted(date: .abbreviated, time: .shortened))


        """

        let body = selected.map { rotation in
            rotation.rawChunkText ?? "#\(rotation.rotationNumber)"
        }
        .joined(separator: "\n\n------------------------------------------------------------\n\n")

        let safePacketName = (viewModel.bidpacketName ?? "bidpacket")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")

        let fileName = "selected_rotations_\(safePacketName).txt"

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try (header + body).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to write selected rotations export:", error)
            return nil
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

            Text("Try changing your search or filters.")
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
}

enum RotationSortOption: String, CaseIterable, Identifiable {
    case rotationNumber
    case days
    case finalScore
    case legsScore
    case restScore
    case inScore
    case outScore
    case woclScore
    case fdpOverMaxFDP
    case blockOverFDP
    case blockOverMaxBlock
    case circadianSwapScore
    case turnScore
    case commutabilityScore
    case payTafbScore
    case dhScore

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rotationNumber: return "Rotation Number"
        case .days: return "Days"
        case .finalScore: return "Final Score"
        case .legsScore: return "Legs Score"
        case .restScore: return "Rest Score"
        case .inScore: return "In Score"
        case .outScore: return "Out Score"
        case .woclScore: return "WOCL Score"
        case .fdpOverMaxFDP: return "FDP / Max FDP"
        case .blockOverFDP: return "Block / FDP"
        case .blockOverMaxBlock: return "Block / Max Block"
        case .circadianSwapScore: return "Circadian Swap"
        case .turnScore: return "Turn Score"
        case .commutabilityScore: return "Commutability"
        case .payTafbScore: return "Pay / TAFB"
        case .dhScore: return "DH Score"
        }
    }

    static func sort(
        _ rotations: [Rotation],
        by options: [RotationSortOption],
        ascending: Bool
    ) -> [Rotation] {
        rotations.sorted { left, right in
            for option in options {
                let result = option.compare(left, right)

                if result != .orderedSame {
                    return ascending
                    ? result == .orderedAscending
                    : result == .orderedDescending
                }
            }

            return left.rotationNumber.localizedStandardCompare(right.rotationNumber) == .orderedAscending
        }
    }

    private func compare(_ left: Rotation, _ right: Rotation) -> ComparisonResult {
        switch self {
        case .rotationNumber:
            return left.rotationNumber.localizedStandardCompare(right.rotationNumber)

        case .days:
            return compareValues(left.numDays, right.numDays)

        case .finalScore:
            return compareValues(left.finalScore, right.finalScore)

        case .legsScore:
            return compareValues(left.scoreParts?.legsScore, right.scoreParts?.legsScore)

        case .restScore:
            return compareValues(left.scoreParts?.restScore, right.scoreParts?.restScore)

        case .inScore:
            return compareValues(left.scoreParts?.inScore, right.scoreParts?.inScore)

        case .outScore:
            return compareValues(left.scoreParts?.outScore, right.scoreParts?.outScore)

        case .woclScore:
            return compareValues(left.scoreParts?.woclScore, right.scoreParts?.woclScore)

        case .fdpOverMaxFDP:
            return compareValues(left.scoreParts?.fdpOverMaxFDP, right.scoreParts?.fdpOverMaxFDP)

        case .blockOverFDP:
            return compareValues(left.scoreParts?.blockOverFDP, right.scoreParts?.blockOverFDP)

        case .blockOverMaxBlock:
            return compareValues(left.scoreParts?.blockOverMaxBlock, right.scoreParts?.blockOverMaxBlock)

        case .circadianSwapScore:
            return compareValues(left.scoreParts?.cirSwapScore, right.scoreParts?.cirSwapScore)

        case .turnScore:
            return compareValues(left.scoreParts?.turnScore, right.scoreParts?.turnScore)

        case .commutabilityScore:
            return compareValues(left.scoreParts?.commutabilityScore, right.scoreParts?.commutabilityScore)

        case .payTafbScore:
            return compareValues(left.scoreParts?.payTafbScore, right.scoreParts?.payTafbScore)

        case .dhScore:
            return compareValues(left.scoreParts?.dhScore, right.scoreParts?.dhScore)
        }
    }

    private func compareValues<T: Comparable>(_ left: T?, _ right: T?) -> ComparisonResult {
        switch (left, right) {
        case let (left?, right?):
            if left < right { return .orderedAscending }
            if left > right { return .orderedDescending }
            return .orderedSame

        case (nil, nil):
            return .orderedSame

        case (nil, _):
            return .orderedDescending

        case (_, nil):
            return .orderedAscending
        }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
