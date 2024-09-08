import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = ActivitiesViewModel()
    @State private var userId: Int = 3 // For now, we'll set it to 3
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    quickAccessButtons
                    upcomingActivitySection
                    whosFreeSection
                    suggestionsSection
                }
                .padding(.horizontal)
            }
            .onAppear {
                viewModel.fetchAllData(for: userId)
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Hey, \(viewModel.user?.name ?? "there")!")
                    .font(.custom("Poppins-Bold", size: 24))
                Text("What are you up to today?")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.gray)
            }
            Spacer()
            notificationButton
            ProfilePictureView(user: viewModel.user)
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
                
                if viewModel.hasNotifications {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                        .offset(x: 1, y: -1)
                }
            }
        }
        .padding(.trailing, 10)
    }
    
    private var quickAccessButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(["Friends", "Calendar", "Invite", "Profile", "Settings"], id: \.self) { buttonText in
                    QuickAccessButton(text: buttonText)
                }
            }
            .padding(.vertical)
            .padding(.leading, 4)
        }
    }
    
    private var upcomingActivitySection: some View {
        Group {
            if let firstActivity = viewModel.userScheduledActivities.first,
               let activity = viewModel.activities.first(where: { $0.id == firstActivity.activityID }) {
                VStack(alignment: .leading, spacing: 10) {
                    upcomingActivityHeader
                    ActivityCard(
                        activity: activity,
                        scheduledActivity: firstActivity,
                        location: viewModel.getLocation(for: activity.locationID),
                        participants: viewModel.activityParticipants[activity.id] ?? [],
                        participantUsers: viewModel.participantUsers,
                        onCancel: viewModel.cancelActivity,
                        onReschedule: viewModel.rescheduleActivity
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
        VStack(alignment: .leading) {
            Text("Who's free")
                .font(.custom("Poppins-Bold", size: 18))
            
            HStack {
                ForEach(["profile3", "profile2", "profile1"], id: \.self) { profileName in
                    Image(profileName)
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
            
            Text("+1")
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
                .font(.custom("Poppins-Bold", size: 18))
            
            let suggestions = [
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

struct ProfilePictureView: View {
    let user: User?
    
    var body: some View {
        if let profilePictureName = user?.profilePicture {
            Image(profilePictureName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(user?.name.prefix(1).uppercased() ?? "")
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(.gray)
                )
        }
    }
}

struct AnimatedTextView: View {
    let texts: [String]
    @State private var currentIndex = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1
    
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
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            updateAnimationState()
        }
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
