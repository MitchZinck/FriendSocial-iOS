import SwiftUI

struct ScheduleActivityView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddScheduledActivityViewModel = AddScheduledActivityViewModel()
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var showToOthers: Bool = true
    @State private var selectedDates: Set<DateComponents> = []
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600)
    @State private var isRepeating: Bool = false
    @State private var selectedDays: Set<Int> = [1, 3, 5] // Sunday, Tuesday, Thursday
    @State private var repeatFrequency: Int = 1
    @State private var repeatUnit: String = "Week"
    @State private var locationName: String = ""
    @State private var locationAddress: String = ""
    @State private var selectedEmoji: String = "😊"
    @State private var selectedParticipants: [User] = []
    @State private var showFriendPicker = false
    @State private var isRepeatDisabled: Bool = false
    @State private var isLoading: Bool = false
    @State private var isDatePickerHighlighted: Bool = false
    @State private var selectedEventId: Int?

    let daysOfWeek: [String] = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        profileSection
                        descriptionSection
                        showToOthersToggle
                        participantsSection
                        dateTimeSection
                        repeatSection
                        locationSection
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.1))
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: saveActivity) {
                            Text("Save")
                                .font(.custom(FontNames.poppinsRegular, size: 14))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.4))
                                .cornerRadius(15)
                        }
                        .disabled(isLoading)
                    }
                }
                .navigationTitle("Schedule Activity")
                .navigationBarTitleDisplayMode(.inline)

                if isLoading {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
        .background(Color.gray.opacity(0.1))
        .onAppear {
            viewModel.fetchActivities()
            if let currentUser = dataManager.currentUser {
                selectedParticipants = [currentUser]
            }
        }
    }

    private var profileSection: some View {
        HStack(alignment: .top, spacing: 15) {
            EmojiPicker(selectedEmoji: $selectedEmoji)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 5) {
                Text("Title")
                    .font(.custom(FontNames.poppinsRegular, size: 14))
                    .foregroundColor(.black)
                HStack {
                    TextField("Add yours or select one", text: $title)
                        .frame(height: 40)
                        .padding(.horizontal, 8)
                        .background(isTitleHighlighted ? Color.red.opacity(0.1) : Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isTitleHighlighted ? Color.red : Color.clear, lineWidth: 1)
                        )
                    Menu {
                        ForEach(viewModel.activities) { activity in
                            Button(action: {
                                selectActivity(activity)
                            }) {
                                HStack {
                                    Text(activity.name)
                                    Spacer()
                                    Text(viewModel.getLocationName(for: activity.locationID ?? 0))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Description")
                .font(.custom(FontNames.poppinsRegular, size: 14))
                .foregroundColor(.black)
            TextField("", text: $description)
                .frame(height: 40)
                .padding(.horizontal, 8)
                .font(.custom(FontNames.poppinsRegular, size: 14))
                .foregroundColor(.gray)
                .background(Color.white)
                .cornerRadius(8)
        }
    }

    private var showToOthersToggle: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle("Show to others", isOn: $showToOthers)
                .tint(.purple)
                .font(.custom(FontNames.poppinsRegular, size: 14))
                .foregroundColor(.black)
            Text("Allows friends to invite you if enabled.")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Participants")
                .font(.custom(FontNames.poppinsRegular, size: 14))
                .foregroundColor(.black)
            HStack {
                ParticipantsPreview(
                    participants: selectedParticipants.map { ActivityParticipant(id: $0.id, userID: $0.id, scheduledActivityID: 0, inviteStatus: $0.id == dataManager.currentUser?.id ? "Accepted" : "Pending") },
                    participantUsers: Dictionary(uniqueKeysWithValues: selectedParticipants.map { ($0.id, $0) }),
                    selectedEventId: $selectedEventId, participantPPSize: 30
                )
                Button(action: {
                    showFriendPicker = true
                }) {
                    Image(systemName: "person.badge.plus")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerView(selectedParticipants: $selectedParticipants)
        }
    }

    var bounds: Range<Date> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .month, value: 6, to: start)!
        return start..<end
    }

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Date and Time")
                .font(.custom(FontNames.poppinsRegular, size: 14))
                .foregroundColor(.black)
            
            CustomMultiDatePicker(selectedDates: $selectedDates, bounds: bounds, isHighlighted: $isDatePickerHighlighted)
                .onChange(of: selectedDates) { oldValue, newValue in
                    isRepeatDisabled = newValue.count > 1
                    if isRepeatDisabled {
                        isRepeating = false
                    }
                    isDatePickerHighlighted = false
                }
            
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("From")
                        .font(.custom(FontNames.poppinsRegular, size: 14))
                        .foregroundColor(.black)
                    CustomTimePicker(time: $startTime, label: "Start Time")
                }
                Spacer()
                VStack(alignment: .leading, spacing: 5) {
                    Text("To")
                        .font(.custom(FontNames.poppinsRegular, size: 14))
                        .foregroundColor(.black)
                    CustomTimePicker(time: $endTime, label: "End Time")
                }
            }
        }
    }

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Repeat", isOn: $isRepeating)
                .tint(.purple)
                .font(.custom(FontNames.poppinsRegular, size: 14))
                .foregroundColor(.black)
                .disabled(isRepeatDisabled)
            
            if isRepeating {
                HStack {
                    ForEach(0..<7) { index in
                        Button(action: {
                            if selectedDays.contains(index) {
                                selectedDays.remove(index)
                            } else {
                                selectedDays.insert(index)
                            }
                        }) {
                            Text(daysOfWeek[index])
                                .frame(width: 30, height: 30)
                                .background(selectedDays.contains(index) ? Color.purple : Color.clear)
                                .foregroundColor(selectedDays.contains(index) ? .white : .black)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.purple, lineWidth: 1))
                        }
                    }
                }
                Text("Every")
                    .font(.custom(FontNames.poppinsRegular, size: 14))
                    .foregroundColor(.black)
                HStack {
                    TextField("", text: Binding(
                        get: { String(repeatFrequency) },
                        set: { newValue in
                            if let value = Int(newValue), value > 0, value <= 12 {
                                repeatFrequency = value
                            } else if newValue.isEmpty {
                                repeatFrequency = 0 // Handle empty string
                            }
                        }
                    ))
                    .keyboardType(.numberPad)
                    .onChange(of: repeatFrequency) { oldValue, newValue in
                        if newValue > 12 {
                            repeatFrequency = 12 // Cap the value at 12
                        } else if newValue < 1 {
                            repeatFrequency = 1 // Ensure it doesn't drop below 1
                        }
                    }
                    .frame(width: 40)
                    .multilineTextAlignment(.center)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )

                    Picker("", selection: $repeatUnit) {
                        Text("Week").tag("Week")
                        Text("Month").tag("Month")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Location Name")
                .font(.custom(FontNames.poppinsRegular, size: 14))
                .foregroundColor(.black)
            TextField("", text: $locationName)
                .padding(10)
                .background(isLocationNameHighlighted ? Color.red.opacity(0.1) : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isLocationNameHighlighted ? Color.red : Color.clear, lineWidth: 1)
                )
            
            Text("Location Address")
                .font(.custom(FontNames.poppinsRegular, size: 14))
                .foregroundColor(.black)
            TextField("", text: $locationAddress)
                .padding(10)
                .background(isLocationAddressHighlighted ? Color.red.opacity(0.1) : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isLocationAddressHighlighted ? Color.red : Color.clear, lineWidth: 1)
                )
        }
    }

    private func selectActivity(_ activity: Activity) {
        title = activity.name
        selectedEmoji = unicodeToEmoji(activity.emoji) ?? "😊"
        locationName = viewModel.getLocationName(for: activity.locationID ?? 0)
        locationAddress = viewModel.getLocationAddress(for: activity.locationID ?? 0)
        description = viewModel.getActivityDescription(for: activity.id)
        
        let noon: Date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        startTime = noon
        
        let estimatedTimeComponents: [String] = activity.estimatedTime.components(separatedBy: ":")
        let hours: Double = Double(estimatedTimeComponents[0]) ?? 0
        let minutes: Double = Double(estimatedTimeComponents[1]) ?? 0
        let seconds: Double = Double(estimatedTimeComponents[2]) ?? 0
        
        let estimatedTimeInterval: TimeInterval = (hours * 3600) + (minutes * 60) + seconds
        endTime = noon.addingTimeInterval(estimatedTimeInterval)
    }

    @State private var isTitleHighlighted: Bool = false
    @State private var isLocationNameHighlighted: Bool = false
    @State private var isLocationAddressHighlighted: Bool = false

    private func saveActivity() {
        var hasError = false

        // Check for empty fields
        if title.isEmpty {
            isTitleHighlighted = true
            hasError = true
        } else {
            isTitleHighlighted = false
        }

        if locationName.isEmpty {
            isLocationNameHighlighted = true
            hasError = true
        } else {
            isLocationNameHighlighted = false
        }

        if locationAddress.isEmpty {
            isLocationAddressHighlighted = true
            hasError = true
        } else {
            isLocationAddressHighlighted = false
        }

        // Check for selected dates
        if selectedDates.isEmpty {
            isDatePickerHighlighted = true
            hasError = true
        } else {
            isDatePickerHighlighted = false
        }

        // If any field is invalid, do not proceed
        if hasError {
            return
        }

        // Continue with saving the activity
        isLoading = true
        let newLocation = Location(id: 0, name: locationName, address: locationAddress, latitude: 82.645872, longitude: -38.749455)
        let newActivity = Activity(id: 0, name: title, description: description, estimatedTime: formatTimeInterval(from: startTime, to: endTime), locationID: nil, userCreated: true, emoji: selectedEmoji)

        Task {
            do {
                try await dataManager.saveNewScheduledActivity(location: newLocation, activity: newActivity, selectedDates: Array(selectedDates), startTime: startTime, endTime: endTime, participants: selectedParticipants, isRepeating: isRepeating, repeatFrequency: repeatFrequency, repeatUnit: repeatUnit, selectedDays: Array(selectedDays))

                DispatchQueue.main.async {
                    isLoading = false
                    dismiss()
                }
            } catch {
                print("Error saving activity: \(error)")
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
    }

    private func formatTimeInterval(from start: Date, to end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct CustomMultiDatePicker: View {
    @Binding var selectedDates: Set<DateComponents>
    let bounds: Range<Date>
    @Binding var isHighlighted: Bool
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack {
            Button(action: {
                isExpanded.toggle()
            }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.black)
                        .font(.custom(FontNames.poppinsRegular, size: 16))
                    
                    Text(formattedDates)
                        .font(.custom(FontNames.poppinsRegular, size: 14))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.black)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(isHighlighted ? Color.red.opacity(0.1) : Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isHighlighted ? Color.red : Color.clear, lineWidth: 1)
                )
            }
            
            if isExpanded {
                MultiDatePicker("Select Dates", selection: $selectedDates, in: bounds)
                    .labelsHidden()
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .frame(maxHeight: 300)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
    }

    private var formattedDates: String {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        let sortedDates: [Date] = selectedDates.compactMap { 
            Calendar.current.date(from: $0) 
        }.sorted()
        
        switch sortedDates.count {
        case 0:
            return "Select dates"
        case 1:
            return dateFormatter.string(from: sortedDates[0])
        default:
            let displayDates: ArraySlice<Date> = sortedDates.prefix(2)
            let formattedDisplayDates: String = displayDates.map { 
                dateFormatter.string(from: $0) 
            }.joined(separator: " & ")
            
            return sortedDates.count > 2 ? "\(formattedDisplayDates) & more" : formattedDisplayDates
        }
    }
}

struct CustomTimePicker: View {
    @Binding var time: Date
    let label: String

    var body: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.black)
                .font(.custom(FontNames.poppinsRegular, size: 16))
            
            DatePicker(label, selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(CompactDatePickerStyle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct AddFreeTimeActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleActivityView()
    }
}

class AddScheduledActivityViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var locations: [Location] = []
    
    private let apiService: APIService = APIService()
    
    func fetchActivities() {
        Task {
            do {
                let fetchedActivities = try await apiService.fetchAllActivities()
                await MainActor.run {
                    self.activities = fetchedActivities
                    self.fetchLocations()
                }
            } catch {
                print("Error fetching activities: \(error)")
            }
        }
    }
    
    private func fetchLocations() {
        let locationIDs: Set<Int> = Set(activities.map { $0.locationID ?? 0 })
        Task {
            do{
                let fetchedLocations = try await apiService.fetchLocations(ids: Array(locationIDs))
                await MainActor.run {
                    self.locations = fetchedLocations
                }
            } catch {
                print("Error fetching locations: \(error)") 
            }
        }
    }
    
    func getLocationName(for locationID: Int) -> String {
        locations.first(where: { $0.id == locationID })?.name ?? "Unknown Location"
    }

    func getLocationAddress(for locationID: Int) -> String {
        locations.first(where: { $0.id == locationID })?.address ?? "Unknown Address"
    }

    func getActivityDescription(for activityID: Int) -> String {
        activities.first(where: { $0.id == activityID })?.description ?? "Unknown Description"
    }   

    func saveNewActivity(location: Location, activity: Activity, selectedDates: [DateComponents], startTime: Date, endTime: Date, participants: [User], isRepeating: Bool, repeatFrequency: Int, repeatUnit: String, selectedDays: [Int]) async throws {
        let dataManager = DataManager.shared
        try await dataManager.saveNewScheduledActivity(location: location, activity: activity, selectedDates: selectedDates, startTime: startTime, endTime: endTime, participants: participants, isRepeating: isRepeating, repeatFrequency: repeatFrequency, repeatUnit: repeatUnit, selectedDays: selectedDays)
    }
}

struct FriendPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedParticipants: [User]

    init(selectedParticipants: Binding<[User]>) {
        self._selectedParticipants = selectedParticipants
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.friends.filter { friend in
                    !selectedParticipants.contains(where: { $0.id == friend.id })
                }, id: \.id) { friend in
                    Button(action: {
                        selectedParticipants.append(friend)
                        dismiss()
                    }) {
                        HStack {
                            Image(friend.profilePicture ?? "")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            Text(friend.name)
                                .font(.custom(FontNames.poppinsRegular, size: 14))
                        }
                    }
                }
            }
            .navigationTitle("Select Friends")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}
