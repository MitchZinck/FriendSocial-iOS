import SwiftUI

struct ActivitiesView: View {
    @StateObject private var viewModel = ActivitiesViewModel()
    @State private var selectedTab: Tab = .upcoming
    
    enum Tab {
        case upcoming, complete
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor(red: 1.0, green: 0.98, blue: 0.8, alpha: 1.0))
                .edgesIgnoringSafeArea(.all)
            
            EmojiBackground()
                .edgesIgnoringSafeArea(.all)
            
            // Content
            VStack {
                // Top buttons
                HStack {
                    Button(action: { selectedTab = .upcoming }) {
                        Text("Upcoming")
                            .padding()
                            .background(selectedTab == .upcoming ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    
                    Button(action: { selectedTab = .complete }) {
                        Text("Complete")
                            .padding()
                            .background(selectedTab == .complete ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                }
                .padding()
                
                // Activity card stack
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(selectedTab == .upcoming ? viewModel.userScheduledActivities.filter { !$0.isActive } : viewModel.userScheduledActivities.filter { $0.isActive }, id: \.id) { scheduledActivity in
                            if let activity = viewModel.activities.first(where: { $0.id == scheduledActivity.activityID }) {
                                let location = viewModel.getLocation(for: activity.locationID)
                                let participants = viewModel.activityParticipants[activity.id] ?? []
                                ActivityCard(activity: activity, scheduledActivity: scheduledActivity, location: location, participants: participants, participantUsers: viewModel.participantUsers, onCancel: viewModel.cancelActivity, onReschedule: viewModel.rescheduleActivity)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct EmojiBackground: View {
    let emojis = ["🎉", "🎈", "🎊", "🥳", "👯‍♀️", "🕺", "💃", "🍻", "🍾", "🥂", 
                  "⚽️", "🏀", "🏈", "⚾️", "🎾", "🏐", "🏉", "🥏", "🎱", "🏓",
                  "🏸", "🏒", "🏑", "🥍", "🏏", "🪃", "🥊", "🥋", "🎿", "⛷️",
                  "🏂", "🏋️", "🤼", "🤸", "🤺", "⛸️", "🏄", "🚴", "🧗", "🎬",
                  "🎭", "🎨", "🎤", "🎧", "🎼", "🎹", "🪗", "🎸", "🎻", "🎺",
                  "🎷", "🥁", "🎯", "🎳", "🎮", "🕹️", "🎰", "🎲", "🧩", "🍿",
                  "🥤", "🍔", "🍕", "🌭", "🍣", "🍱", "🍜", "🍝", "🍳", "🧑‍🍳",
                  "🏛️", "🏰", "🏯", "🏠", "🏡", "🏢", "🏣", "🏤", "🏥", "🏦",
                  "🏨", "🏩", "🏪", "🏫", "🏬", "🏭", "🏟️", "🏗️", "🧱", "🪵",
                  "🛖", "🏕️", "⛺️", "🏙️", "🌄", "🌅", "🌆", "🌇", "🌉", "🌁"]
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<200) { _ in
                Text(emojis.randomElement()!)
                    .font(.system(size: 20))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .opacity(0.08)
            }
        }
    }
}
