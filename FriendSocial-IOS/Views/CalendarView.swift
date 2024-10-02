import SwiftUI

struct CalendarView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDate: Date = Date()
    @State private var selectedFilter: String = "See all"
    @State private var isCalendarDropdownVisible: Bool = false
    @State private var isProfileMenuOpen: Bool = false
    @State private var events: [Event] = []
    @State private var invites: [Invite] = []
    @State private var selectedEventId: Int? = nil
    @State private var showScheduleActivityView: Bool = false
    
    let filters: [String] = ["See all", "Social", "Personal"]
    
    var body: some View {
        NavigationStack {
            mainContent
        }
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: updateEvents)
        .onChange(of: selectedDate) { _, _ in
            updateEvents()
            updateInvites()
        }
        .onChange(of: dataManager.invites) { _, _ in
            updateInvites()
        }
       .sheet(isPresented: $showScheduleActivityView) {
            ScheduleActivityView()
                .environmentObject(dataManager)
                .onDisappear {
                    updateEvents()
                    updateInvites()
                }
        }
        .sheet(item: Binding(
            get: { selectedEventId.map { IdentifiableInt(id: $0) } },
            set: { selectedEventId = $0?.id }
        )) { identifiableEventId in
            participantsSheet(for: identifiableEventId.id)
        }
    }
    
    private var mainContent: some View {
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
    
    private var scheduleContent: some View {
        VStack(spacing: 0) {
            scheduleHeader
            fullWidthDivider
            VStack(spacing: 20) {
                eventListings
                incomingInvites
            }
            .padding(.horizontal)
            .padding(.top, 15)
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
        .padding(.vertical)
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
    
    private func getDateForIndex(_ index: Int) -> Date {
        let calendar: Calendar = Calendar.current
        let today: Date = Date()
        let weekday: Int = calendar.component(.weekday, from: today)
        let daysToSubtract: Int = (weekday + 5) % 7
        
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
            ForEach(filteredEvents) { event in
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
                return event.isActive
            }
        default:
            return events
        }
    }

    private var addEventButton: some View {
        HStack {
            Button(action: {
                showScheduleActivityView = true
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
            .padding(.horizontal, -20)
    }

    private func updateInvites() {
        invites = dataManager.retrieveInvitesForDate(date: selectedDate)
    }
    
    private var incomingInvites: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Incoming Invites")
                .font(.custom(FontNames.poppinsMedium, size: 18))
            if(invites.count > 0) {
                ForEach(invites) { invite in
                    InviteCard(invite: invite)
                }
            } else {
                Text("No invites for today")
                    .font(.custom(FontNames.poppinsRegular, size: 14))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func updateEvents() {
        let calendar: Calendar = Calendar.current
        let weekday: Int = calendar.component(.weekday, from: selectedDate)
        let dayOfWeek: String = calendar.standaloneWeekdaySymbols[weekday - 1]
        
        let availabilityForDay: [UserAvailability] = dataManager.userAvailability.filter { $0.dayOfWeek == dayOfWeek || $0.specificDate == selectedDate }
        
        let activitiesForDay: [ScheduledActivity] = dataManager.scheduledActivities.filter { calendar.isDate($0.scheduledAt, inSameDayAs: selectedDate) }
        
        events = availabilityForDay.map { availability in
            Event(time: "\(formatTime(availability.startTime)) - \(formatTime(availability.endTime))",
                  title: "⏳ Free time",
                  color: .blue,
                  icon: "person.2.fill",
                  isActive: true,
                  scheduledActivityId: nil)
        } + activitiesForDay.compactMap { scheduledActivity in
            let participants = dataManager.getActivityParticipants(for: scheduledActivity.id)
            guard let currentUserParticipant = participants.first(where: { $0.userID == dataManager.currentUser?.id }),
                  currentUserParticipant.inviteStatus == "Accepted" else {
                return nil
            }
            
            let activity = dataManager.activities.first(where: { $0.id == scheduledActivity.activityID })
            let activityName = activity?.name ?? "Unknown Activity"
            let emoji = unicodeToEmoji(activity?.emoji ?? "") ?? ""
            let title = "\(emoji) \(activityName)"
            
            return Event(time: "\(formatTime(scheduledActivity.scheduledAt)) - \(formatTime(scheduledActivity.scheduledAt.addingTimeInterval(3600)))",
                         title: title.count > 25 ? String(title.prefix(22)) + "..." : title,
                         color: .green,
                         icon: "person.2.fill",
                         isActive: false,
                         scheduledActivityId: scheduledActivity.id)
        }
        
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
                            ParticipantsPreview(participants: participants, participantUsers: dataManager.participantUsers, selectedEventId: $selectedEventId, participantPPSize: 30)
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

struct Event: Identifiable {
    let id: UUID
    let time: String
    let title: String
    let color: Color
    let icon: String
    let isActive: Bool
    let scheduledActivityId: Int?
    
    var startTime: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.date(from: time.components(separatedBy: " - ")[0]) ?? Date()
    }
    
    init(time: String, title: String, color: Color, icon: String, isActive: Bool, scheduledActivityId: Int?) {
        self.id = UUID()
        self.time = time
        self.title = title
        self.color = color
        self.icon = icon
        self.isActive = isActive
        self.scheduledActivityId = scheduledActivityId
    }
}

struct IdentifiableInt: Identifiable {
    let id: Int
}

struct FreeTimeScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(DataManager.shared)
    }
}
