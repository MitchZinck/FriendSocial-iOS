import SwiftUI

struct FreeTimeScheduleView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject private var dataManager: DataManager = DataManager.shared
    @State private var selectedDate: Date = Date()
    @State private var selectedFilter: String = "See all"
    @State private var isCalendarDropdownVisible: Bool = false
    @State private var isProfileMenuOpen: Bool = false
    @State private var events: [Event] = []
    @State private var selectedEventId: Int? = nil
    
    let filters: [String] = ["See all", "Social", "Personal"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    calendarSection
                    scheduleContent
                }
                .padding(.top, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.gray.opacity(0.01), for: .navigationBar)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: updateEvents)
        .onChange(of: selectedDate) { _, _ in updateEvents() }
        .sheet(item: Binding(
            get: { selectedEventId.map { IdentifiableInt(id: $0) } },
            set: { selectedEventId = $0?.id }
        )) { identifiableEventId in
            participantsSheet(for: identifiableEventId.id)
        }
    }
    
    private var scheduleContent: some View {
        VStack(spacing: 20) {
            scheduleHeader
            fullWidthDivider
            VStack(spacing: 20) {
                eventListings
                incomingInvites
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            Spacer(minLength: 80)
        }
    }
    
    private var scheduleHeader: some View {
        VStack {
            freeTimeNotification
                .padding(.bottom, 10)
            filterSection
        }
        .padding(.horizontal)
        .padding(.top)
        .background(Color.gray.opacity(0.1))
    }
    
    private var calendarSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0..<30) { index in
                    CalendarDayView(date: getDateForIndex(index), selectedDate: $selectedDate, events: $events)
                }
            }
            .padding(.leading)
        }
    }
    // Add this function to calculate the date for each index
    private func getDateForIndex(_ index: Int) -> Date {
        let calendar: Calendar = Calendar.current
        let today: Date = Date()
        let weekday: Int = calendar.component(.weekday, from: today)
        let daysToSubtract: Int = (weekday + 5) % 7 // Calculate days to subtract to get to Monday
        
        guard let monday: Date = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
            return today
        }
        
        return calendar.date(byAdding: .day, value: index, to: monday) ?? today
    }
    
    private var freeTimeNotification: some View {
        (Text("You have ") + Text("4").bold() + Text(" hours of free time today. Let's find something fun to do! 😊"))
            .font(.custom(FontNames.poppinsRegular, size: 14))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var filterSection: some View {
        VStack(spacing: 10) {
            Text("Your free time")
                .font(.custom(FontNames.poppinsSemiBold, size: 18))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 10) {
                ForEach(filters, id: \.self) { filter in
                    Button(action: { selectedFilter = filter }) {
                        Text(filter)
                            .font(.custom(FontNames.poppinsRegular, size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFilter == filter ? Color.black : Color.gray.opacity(0.1))
                            .foregroundColor(selectedFilter == filter ? .white : .black)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var eventListings: some View {
        VStack(spacing: 15) {
            ForEach(filteredEvents, id: \.time) { event in
                EventCard(event: event, dataManager: dataManager, selectedEventId: $selectedEventId)
                fullWidthDivider
            }
            addEventButton
        }
    }

    private var filteredEvents: [Event] {
        switch selectedFilter {
        case "Social":
            return events.filter { event in
                if let scheduledActivityId = event.scheduledActivityId {
                    let participants = dataManager.getActivityParticipants(for: scheduledActivityId)
                    return participants.count > 1
                }
                return false
            }
        case "Personal":
            return events.filter { event in
                if let scheduledActivityId = event.scheduledActivityId {
                    let participants = dataManager.getActivityParticipants(for: scheduledActivityId)
                    return participants.count <= 1
                }
                return event.isAvailability
            }
        default:
            return events
        }
    }

    private var addEventButton: some View {
        HStack {
            Button(action: {
                // Action to add new event
            }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
            }
            .padding(.trailing, 10)
            
            Text("Add to your schedule")
                .font(.custom(FontNames.poppinsRegular, size: 16))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    private var fullWidthDivider: some View {
        Divider()
            .background(Color.black)
            .padding(.horizontal, -20) // Adjust this value as needed
    }
    
    private var incomingInvites: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Incoming Invites")
                .font(.custom(FontNames.poppinsMedium, size: 18))
            InviteCard(event: "Brunch", time: "Sun, 11:00 AM")
            InviteCard(event: "Hike w John", time: "Sat, 9:00 AM")
        }
    }
    
    private func updateEvents() {
        let calendar: Calendar = Calendar.current
        let weekday: Int = calendar.component(.weekday, from: selectedDate)
        let dayOfWeek: String = calendar.standaloneWeekdaySymbols[weekday - 1]
        
        // Filter user availability for the selected day
        let availabilityForDay: [UserAvailability] = dataManager.userAvailability.filter { $0.dayOfWeek == dayOfWeek || $0.specificDate == selectedDate }
        
        // Filter scheduled activities for the selected day
        let activitiesForDay: [ScheduledActivity] = dataManager.scheduledActivities.filter { calendar.isDate($0.scheduledAt, inSameDayAs: selectedDate) }
        
        // Combine availability and scheduled activities into events
        events = availabilityForDay.map { availability in
            Event(time: "\(formatTime(availability.startTime)) - \(formatTime(availability.endTime))",
                  title: "⏳ Free time",
                  color: .blue,
                  icon: "person.2.fill",
                  isAvailability: true,
                  scheduledActivityId: nil)
        } + activitiesForDay.map { scheduledActivity in
            let activity = dataManager.activities.first(where: { $0.id == scheduledActivity.activityID })
            let activityName = activity?.name ?? "Unknown Activity"
            let emoji = unicodeToEmoji(activity?.emoji ?? "") ?? ""
            let title = "\(emoji) \(activityName)"
            
            return Event(time: "\(formatTime(scheduledActivity.scheduledAt)) - \(formatTime(scheduledActivity.scheduledAt.addingTimeInterval(3600)))", // Assuming 1 hour duration
                         title: title.count > 25 ? title.prefix(22) + "..." : title,
                         color: .green,
                         icon: "person.2.fill",
                         isAvailability: false,
                         scheduledActivityId: scheduledActivity.id)
        }
        
        // Sort events by start time
        events.sort { $0.startTime < $1.startTime }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
            ToolbarItem(placement: .principal) {
                dateSelector
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                trailingButtons
            }
        }
    }
    
    private var backButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
        }
    }
    
    private var dateSelector: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.black)
                .font(.system(size: 16))
            Text(selectedDate.formatted(.dateTime.month().year()))
                .font(.custom(FontNames.poppinsRegular, size: 16))
            Button(action: { isCalendarDropdownVisible.toggle() }) {
                Text("▼")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .cornerRadius(20)
    }
    
    private var trailingButtons: some View {
        HStack(spacing: 10) {
            Button(action: { /* Implement search action */ }) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.black)
                    .padding(8)
                    .clipShape(Circle())
            }
            
            profileImage
        }
    }
    
    private var profileImage: some View {
        Image(dataManager.currentUser?.profilePicture ?? "default_profile")
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
    }
    
    private func participantsSheet(for eventId: Int) -> some View {
        let participants = dataManager.getActivityParticipants(for: eventId)
        return Group {
            if participants.count > 3 {
                ParticipantsView(participants: participants, participantUsers: dataManager.participantUsers)
            }
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    @Binding var selectedDate: Date
    @Binding var events: [Event]
    
    private var isSelected: Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    var body: some View {
        VStack {
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.custom(FontNames.poppinsRegular, size: 14))
                .foregroundColor(isSelected ? .purple : .gray)
            Text(date.formatted(.dateTime.day()))
                .font(.custom(FontNames.poppinsMedium, size: 16))
                .foregroundColor(isSelected ? .white : .black)
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.purple : Color.clear)
                .clipShape(Circle())
        }
        .onTapGesture {
            selectedDate = date
        }
    }
}

struct EventCard: View {
    let event: Event
    let dataManager: DataManager
    @Binding var selectedEventId: Int?
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .center) {
                    Text(event.time.components(separatedBy: " - ")[0])
                        .font(.custom(FontNames.poppinsRegular, size: 16))
                    Text(event.time.components(separatedBy: " - ")[1])
                        .font(.custom(FontNames.poppinsRegular, size: 16))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.custom(FontNames.poppinsMedium, size: 16))
                        .lineLimit(1)
                    
                    let locationName: String = {
                        if let id = event.scheduledActivityId,
                           let activity = dataManager.activities.first(where: { $0.id == dataManager.scheduledActivities.first(where: { $0.id == id })?.activityID }),
                           let location = dataManager.locations.first(where: { $0.id == activity.locationID }) {
                            return "📍 \(location.name)"
                        } 
                        return "📍 Earth"
                    }()
                    
                    Text(locationName)
                        .font(.custom(FontNames.poppinsRegular, size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 15) {
                    if let id = event.scheduledActivityId,
                       let activity = dataManager.activities.first(where: { $0.id == dataManager.scheduledActivities.first(where: { $0.id == id })?.activityID }) {
                        HStack(alignment: .top) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text(activity.description)
                                .font(.custom(FontNames.poppinsRegular, size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        let participants = dataManager.getActivityParticipants(for: id)
                        HStack {
                            ParticipantsPreview(participants: participants, participantUsers: dataManager.participantUsers, selectedEventId: $selectedEventId)
                            Spacer()
                            Button(action: {
                                // Edit action
                            }) {
                                Label("Edit", systemImage: "pencil")
                                    .font(.custom(FontNames.poppinsRegular, size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue)
                                    .cornerRadius(15)
                            }
                            Button(action: {
                                // Delete action
                            }) {
                                Label("Delete", systemImage: "trash")
                                    .font(.custom(FontNames.poppinsRegular, size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.red)
                                    .cornerRadius(15)
                            }
                        }
                    } else {
                        Text("There's nothing here yet! 🥳")
                            .font(.custom(FontNames.poppinsRegular, size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 5)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(event.color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ParticipantsPreview: View {
    let participants: [ActivityParticipant]
    let participantUsers: [Int: User]
    @Binding var selectedEventId: Int?
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(participants.prefix(3).indices, id: \.self) { index in
                if let user = participantUsers[participants[index].userID] {
                    Image(user.profilePicture ?? "default_profile")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                }
            }
            if participants.count > 3 {
                Text("+\(participants.count - 3)")
                    .font(.custom(FontNames.poppinsRegular, size: 12))
                    .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .onTapGesture {
            if participants.count > 3 {
                selectedEventId = participants.first?.scheduledActivityID
            }
        }
    }
}

private struct ParticipantsView: View {
    let participants: [ActivityParticipant]
    let participantUsers: [Int: User]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(participants, id: \.id) { participant in
                    if let user = participantUsers[participant.userID] {
                        HStack {
                            Image(user.profilePicture ?? "default_profile")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            Text(user.name)
                                .font(.custom(FontNames.poppinsRegular, size: 16))
                        }
                    }
                }
            }
            .navigationTitle("Participants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

struct InviteCard: View {
    let event: String
    let time: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event)
                    .font(.custom(FontNames.poppinsMedium, size: 16))
                Text(time)
                    .font(.custom(FontNames.poppinsRegular, size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()
            HStack {
                Button(action: {}) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
                Button(action: {}) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// Constants
enum FontNames {
    static let poppinsRegular: String = "Poppins-Regular"
    static let poppinsMedium: String = "Poppins-Medium"
    static let poppinsSemiBold: String = "Poppins-SemiBold"
    static let interMedium: String = "Inter_18pt-Medium"
    static let interRegular: String = "Inter_18pt-Regular"
    static let interSemiBold: String = "Inter_18pt-SemiBold"
}

struct Event {
    let time: String
    let title: String
    let color: Color
    let icon: String
    let isAvailability: Bool
    let scheduledActivityId: Int?
    
    var startTime: Date {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.date(from: time.components(separatedBy: " - ")[0]) ?? Date()
    }
}

struct IdentifiableInt: Identifiable {
    let id: Int
}

struct FreeTimeScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        FreeTimeScheduleView()
            .environmentObject(DataManager.shared)
    }
}
