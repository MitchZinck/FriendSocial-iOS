import SwiftUI

struct ActivitiesView: View {
    @StateObject private var viewModel = ActivitiesViewModel()
    @State private var selectedTab: Tab = .upcoming
    
    enum Tab {
        case upcoming, complete
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    addNewActivityButton
                    suggestedActivitiesSection
                    scheduledActivitiesSection
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { titleView }
                ToolbarItem(placement: .navigationBarTrailing) { profileButton }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var addNewActivityButton: some View {
        Button(action: { /* Add action for creating new activity */ }) {
            Label("Add New", systemImage: "plus.circle.fill")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundColor(.black)
                .padding(.horizontal, 30)
                .padding(.vertical, 5)
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
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var suggestedActivitiesSection: some View {
        VStack(alignment: .leading) {
            Text("Suggested Activities")
                .font(.custom("Poppins-Bold", size: 18))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(SuggestedActivity.mockData, id: \.name) { activity in
                        SuggestedActivityCard(activity: activity)
                    }
                }
                .padding(.leading, 3)
            }
        }
    }
    
    private var scheduledActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Scheduled")
                .font(.custom("Poppins-Bold", size: 18))
            Text("Today, \(Date().formatted(.dateTime.month().day()))")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            ForEach(filteredScheduledActivities, id: \.id) { scheduledActivity in
                if let activity = viewModel.activities.first(where: { $0.id == scheduledActivity.activityID }) {
                    ActivityCard(
                        activity: activity,
                        scheduledActivity: scheduledActivity,
                        location: viewModel.getLocation(for: activity.locationID),
                        participants: viewModel.activityParticipants[activity.id] ?? [],
                        participantUsers: viewModel.participantUsers,
                        onCancel: viewModel.cancelActivity,
                        onReschedule: viewModel.rescheduleActivity
                    )
                    .padding(.bottom, 10)
                }
            }
        }
    }
    
    private var titleView: some View {
        Text("Activities")
            .font(.custom("Poppins-Bold", size: 24))
    }
    
    private var profileButton: some View {
        Button(action: { /* Add user profile action here */ }) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .foregroundColor(.black)
                .background(
                    Circle()
                        .fill(Color.pink.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                )
        }
    }
    
    // MARK: - Helper Methods
    
    private var filteredScheduledActivities: [ScheduledActivity] {
        viewModel.userScheduledActivities.filter { selectedTab == .upcoming ? !$0.isActive : $0.isActive }
    }
}

// MARK: - Supporting Types

struct SuggestedActivity {
    let name: String
    let date: Date
    let image: String
    let emoji: String
    static let mockData = [
        SuggestedActivity(name: "Drinks w/ Martha", date: Date().addingTimeInterval(86400), image: "Drinks", emoji: "🍹"),
        SuggestedActivity(name: "Monday Gym", date: Date().addingTimeInterval(172800), image: "Gym", emoji: "🏋️"),
        SuggestedActivity(name: "Tennis w/ Dave", date: Date().addingTimeInterval(259200), image: "Tennis", emoji: "🎾")
    ]
}

struct SuggestedActivityCard: View {
    let activity: SuggestedActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(activity.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 100)
                .clipped()
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(activity.emoji + " " + activity.name)
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack(spacing: 0) {
                    Text(activity.emoji + " ")
                        .opacity(0)
                        .font(.custom("Poppins-Regular", size: 16))
                    Text(activity.date.formatted(.dateTime.weekday().month().day()))
                        .font(.custom("Poppins-Regular", size: 14))
                }
                .foregroundColor(.gray)
            }
            .frame(width: 150, alignment: .leading)
        }
    }
}
