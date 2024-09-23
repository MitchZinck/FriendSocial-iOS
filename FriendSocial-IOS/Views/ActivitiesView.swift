import SwiftUI

struct ActivitiesView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    @State private var isProfileMenuOpen = false
    @State private var showScheduleActivityView = false
    @State private var numberOfActivitiesToShow = 10

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    addNewActivityButton
                }
                VStack(alignment: .leading, spacing: 0) {
                    suggestedActivitiesSection
                }
                VStack(alignment: .leading, spacing: 20) {
                    scheduledActivitiesSection
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showScheduleActivityView) {
                ScheduleActivityView()
            }
            .onAppear {
                print("ActivitiesView appeared")
                print("Number of scheduled activities: \(dataManager.scheduledActivities.count)")
                print("Number of activities: \(dataManager.activities.count)")
            }
        }
    }

    // MARK: - Subviews

    private var addNewActivityButton: some View {
        Button(action: {
            showScheduleActivityView = true
        }) {
            Label("Add New", systemImage: "plus.circle.fill")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.yellow.opacity(0.3)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                )
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var suggestedActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggested Activities")
                .font(.custom("Poppins-SemiBold", size: 18))
                .padding(.leading, 15)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(SuggestedActivity.mockData) { activity in
                        SuggestedActivityCard(activity: activity)
                    }
                }
                .padding(.leading, 18)
            }
        }
    }

    private var scheduledActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Scheduled")
                .font(.custom("Poppins-SemiBold", size: 18))

            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(groupedScheduledActivities.keys.sorted().prefix(numberOfActivitiesToShow)), id: \.self) { date in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(dateString(from: date))
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.gray)

                        ForEach(groupedScheduledActivities[date] ?? []) { scheduledActivity in
                            if let activity = dataManager.activities.first(where: { $0.id == scheduledActivity.activityID }),
                               let currentUserParticipant = dataManager.getActivityParticipants(for: scheduledActivity.id).first(where: { $0.userID == dataManager.currentUser?.id }),
                               currentUserParticipant.inviteStatus == "Accepted" {
                                ActivityCard(
                                    activity: activity,
                                    scheduledActivity: scheduledActivity,
                                    location: dataManager.locations.first(where: { $0.id == activity.locationID }),
                                    participants: dataManager.activityParticipants[scheduledActivity.id] ?? [],
                                    participantUsers: dataManager.participantUsers
                                )
                            }
                        }
                    }
                }
            }

            if numberOfActivitiesToShow < groupedScheduledActivities.keys.count {
                Button(action: {
                    numberOfActivitiesToShow += 10
                }) {
                    Text("See More")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.blue)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
        }
    }

    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Activities")
                    .font(.custom("Poppins-Bold", size: 24))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                profileImage
            }
        }
    }

    private var profileImage: some View {
        Menu {
            Button(action: {
                // Profile action
            }) {
                Label("Profile", systemImage: "person.circle")
            }
            Button(action: {
                // Settings action
            }) {
                Label("Settings", systemImage: "gear")
            }
            Button(action: {
                // Logout action
            }) {
                Label("Log Out", systemImage: "arrow.right.square")
            }
            .foregroundColor(.red)
        } label: {
            Image(dataManager.currentUser?.profilePicture ?? "default_profile")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        }
    }

    // MARK: - Helper Methods

    private var groupedScheduledActivities: [Date: [ScheduledActivity]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: dataManager.scheduledActivities.filter { scheduledActivity in
            let participants = dataManager.getActivityParticipants(for: scheduledActivity.id)
            return participants.first(where: { $0.userID == dataManager.currentUser?.id })?.inviteStatus == "Accepted"
        }) { (activity) -> Date in
            calendar.startOfDay(for: activity.scheduledAt)
        }
        return grouped
    }

    private func dateString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        return dateFormatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct SuggestedActivity: Identifiable {
    let id = UUID()
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
                Text("\(activity.emoji) \(activity.name)")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(activity.date, style: .date)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.gray)
            }
            .frame(width: 150, alignment: .leading)
        }
    }
}
