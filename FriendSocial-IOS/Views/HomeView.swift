import SwiftUI
struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var userId: Int = 3 // For now, we'll set it to 3
    @State private var isActivitiesViewActive: Bool = false
    @State private var isFreeTimeScheduleViewActive: Bool = false
    @State private var lastDataLoadTime: Date?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if dataManager.isLoading {
                        ProgressView("Loading...")
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                headerSection
                            }
                            .padding(.horizontal)
                            VStack(alignment: .leading, spacing: 0) {
                                quickAccessButtons
                            }
                            VStack(alignment: .leading, spacing: 20) {
                                upcomingActivitySection
                                whosFreeSection
                                suggestionsSection
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .onAppear {
                    loadDataIfNeeded()
                }
            }
            .navigationDestination(isPresented: $isActivitiesViewActive) {
                ActivitiesView()
            }
            .navigationDestination(isPresented: $isFreeTimeScheduleViewActive) {
                CalendarView()
            }
        }
    }
    
    private func loadDataIfNeeded() {  
        let fiveMinutes: TimeInterval = 5 * 60
        if lastDataLoadTime == nil || Date().timeIntervalSince(lastDataLoadTime!) > fiveMinutes {
            DispatchQueue.main.async {
                dataManager.loadInitialData(for: userId)
            }
            lastDataLoadTime = Date()
        }
    }

    // Header section with profile picture and dropdown menu
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Hey, \(dataManager.currentUser?.name ?? "there")!")
                    .font(.custom("Poppins-Bold", size: 24))
                Text("What are you up to today?")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.gray)
            }
            Spacer()
            HStack(spacing: 10) {
                notificationButton
                
                // Profile picture with dropdown menu
                Menu {
                    Button(action: {
                        isActivitiesViewActive = true
                    }) {
                        Label("Activities", systemImage: "figure.run")
                    }
                    Button(action: {
                        isFreeTimeScheduleViewActive = true
                    }) {
                        Label("Calendar", systemImage: "calendar")
                    }
                    Button(action: {}) {
                        Label("Settings", systemImage: "gear")
                    }
                    Button(action: {}) {
                        Label("Log Out", systemImage: "arrow.right.square")
                    }
                    .foregroundColor(.red)
                } label: {
                    Image(dataManager.currentUser?.profilePicture ?? "default_profile")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                }
                .menuStyle(BorderlessButtonMenuStyle())
            }
        }
    }

    // Helper function to determine the destination view
    private func destinationView(for item: String) -> some View {
        switch item {
        case "Activities":
            return AnyView(ActivitiesView())
        case "Free Time":
            return AnyView(CalendarView())
        default:
            return AnyView(EmptyView())
        }
    }
    
    private var notificationButton: some View {
        Button(action: {
            // Action to view notifications
        }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                    .offset(x: 1, y: -1)
            }
        }
    }
    
    private var quickAccessButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(["Friends", "Calendar", "Invite", "Profile", "Settings"], id: \.self) { buttonText in
                    QuickAccessButton(text: buttonText)
                }
            }
            .padding(.vertical)
            .padding(.leading, 15)
        }
    }
    
    private var upcomingActivitySection: some View {
        Group {
            if let firstUpcomingActivity: ScheduledActivity = dataManager.scheduledActivities
                .filter({ $0.scheduledAt >= Date() })
                .sorted(by: { $0.scheduledAt < $1.scheduledAt })
                .first(where: { scheduledActivity in
                    let participants = dataManager.getActivityParticipants(for: scheduledActivity.id)
                    return participants.first(where: { $0.userID == dataManager.currentUser?.id })?.inviteStatus == "Accepted"
                }),
               let activity: Activity = dataManager.activities.first(where: { $0.id == firstUpcomingActivity.activityID }) {
                VStack(alignment: .leading, spacing: 10) {
                    upcomingActivityHeader
                    ActivityCard(
                        activity: activity,
                        scheduledActivity: firstUpcomingActivity,
                        location: dataManager.locations.first(where: { $0.id == activity.locationID }),
                        participants: dataManager.getActivityParticipants(for: firstUpcomingActivity.id),
                        participantUsers: dataManager.participantUsers
                    )
                }
            } else {
                Text("No upcoming activities")
                    .font(.custom("Poppins-Medium", size: 18))
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
    
    private var upcomingActivityHeader: some View {
        HStack {
            AnimatedTextView(texts: Array(["hangout", "activity", "workout", "eat-out"].shuffled()))
                .font(.custom("Poppins-Medium", size: 18))
            Spacer()
            NavigationLink(destination: ActivitiesView()) {
                Text("See All")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var whosFreeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Who's free")
                .font(.custom("Poppins-Medium", size: 18))
                .padding(.bottom, 10)
            
            HStack(spacing: 10) {
                ForEach(dataManager.friends.prefix(3)) { friend in
                    Image(friend.profilePicture ?? "")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
                additionalProfilesIndicator
                Spacer()
                reachOutButton
            }
            .padding()
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 4)
        }
    }
    
    private var additionalProfilesIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 25, height: 25)
            
            Text("+\(max(dataManager.friends.count - 3, 0))")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.gray)
        }
    }
    
    private var reachOutButton: some View {
        Button(action: { /* Add action for creating new activity */ }) {
            Text("Reach Out")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.yellow.opacity(0.3)]),
                                startPoint: .top,
                                endPoint: .bottom)
                )
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                )
        }
    }
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggestions for you")
                .font(.custom("Poppins-Medium", size: 18))
            
            let suggestions: [(String, String)] = [
                ("Outdoors", "🌳"), ("Party", "🎉"), ("Sports", "⚽️"),
                ("Music", "🎵"), ("Crafts", "🎨"), ("Indoors", "🏠")
            ]
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(suggestions, id: \.0) { suggestion in
                    SuggestionButton(text: suggestion.0, emoji: suggestion.1)
                }
            }
        }
    }
}

struct AnimatedTextView: View {
    let texts: [String]
    @State private var currentIndex: Int = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 4) {
            Text("Your next")
                .font(.custom("Poppins-Medium", size: 18))
            
            ZStack(alignment: .leading) {
                ForEach(0..<texts.count, id: \.self) { index in
                    Text(texts[index])
                        .font(.custom("Poppins-Medium", size: 18))
                        .opacity(index == currentIndex ? opacity : 0)
                        .scaleEffect(index == currentIndex ? scale : 0.8)
                        .animation(.easeInOut(duration: 0.5), value: currentIndex)
                }
            }
            .frame(width: 100, alignment: .leading)
            
            Spacer()
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            updateAnimationState()
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateAnimationState() {
        // Fade out the current text
        withAnimation(.easeInOut(duration: 0.5)) {
            opacity = 0
            scale = 0.8
        }
        
        // Wait for the fade-out animation to complete, then update the index
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            currentIndex = (currentIndex + 1) % texts.count
            
            // Fade in the new text
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 1
                scale = 1
            }
        }
    }
}

struct QuickAccessButton: View {
    let text: String
    
    var body: some View {
        Button(action: {
            // Action for each button
        }) {
            Text(text)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
        }
    }
}

struct SuggestionButton: View {
    let text: String
    let emoji: String
    
    var body: some View {
        Button(action: {
            // Action for suggestion button
        }) {
            HStack {
                Text(text)
                Text(emoji)
            }
            .font(.custom("Poppins-Regular", size: 16))
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
        }
    }
}
