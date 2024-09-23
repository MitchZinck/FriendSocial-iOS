import SwiftUI

struct ActivityCard: View {
    @EnvironmentObject var dataManager: DataManager
    let activity: Activity
    let scheduledActivity: ScheduledActivity
    let location: Location?
    let participants: [ActivityParticipant]
    let participantUsers: [Int: User]
    @State private var selectedEventId: Int?

    private var timeSpan: String {
        let formatter: DateFormatter = DateFormatter()
        formatter.timeStyle = .short
        let start: String = formatter.string(from: scheduledActivity.scheduledAt)
        
        let estimatedTimeComponents: [String] = activity.estimatedTime.components(separatedBy: ":")
        let hours: Double = Double(estimatedTimeComponents[0]) ?? 0
        let minutes: Double = Double(estimatedTimeComponents[1]) ?? 0
        let seconds: Double = Double(estimatedTimeComponents[2]) ?? 0
        
        let estimatedTimeInterval: TimeInterval = (hours * 3600) + (minutes * 60) + seconds
        
        let end: String = formatter.string(from: scheduledActivity.scheduledAt.addingTimeInterval(estimatedTimeInterval))
        return "\(start) - \(end)"
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(activity.name)
                            .font(.custom("Poppins-Medium", size: 18))
                        Text(unicodeToEmoji(activity.emoji) ?? " ")
                    }
                    VStack(alignment: .leading) {
                        TimeView(timeSpan: timeSpan)
                        if let location = location {
                            LocationView(location: location)
                        } else {
                            Text("No location specified")
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    ParticipantsPreview(participants: participants, participantUsers: participantUsers, selectedEventId: $selectedEventId, participantPPSize: 40)
                }
                Spacer()
                VStack {
                    Spacer()
                    ActionButtonsView(onCancel: { _ in cancelActivity(scheduledActivity, dataManager) }, onReschedule: { _ in rescheduleActivity(scheduledActivity, dataManager) }, scheduledActivity: scheduledActivity, activity: activity)
                }
            }
        }
        .padding()
        .background(
            ZStack {
                Color.white
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.yellow.opacity(0.05)]), startPoint: .top, endPoint: .bottom)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 4)
    }
}

// Subviews
struct TimeView: View {
    let timeSpan: String
    
    var body: some View {
        Text(timeSpan)
            .font(.custom("Poppins-Regular", size: 16))
            .foregroundColor(.gray)
    }
}
struct LocationView: View {
    let location: Location
    var body: some View {
        Button(action: openMaps) {
            HStack {
                Text(location.name)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.gray)
                Image(systemName: "map")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
        }
    }
    
    private func openMaps() {
        let coordinates = "\(String(describing: location.latitude)),\(String(describing: location.longitude))"
        let googleMapsURL = URL(string: "comgooglemaps://?q=\(coordinates)")
        let appleMapsURL = URL(string: "http://maps.apple.com/?ll=\(coordinates)")
        
        if let url = googleMapsURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = appleMapsURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

private func cancelActivity(_ scheduledActivity: ScheduledActivity, _ dataManager: DataManager) {
    Task {
        do {
            try await dataManager.cancelScheduledActivity(scheduledActivity)
        } catch {
            print("Error cancelling activity: \(error)")
            // Handle the error, e.g., show an alert
        }
    }
}

private func rescheduleActivity(_ scheduledActivity: ScheduledActivity, _ dataManager: DataManager) {
    // Task {
    //     do {
    //         try await dataManager.rescheduleScheduledActivity(scheduledActivity)
    //     } catch {
    //         print("Error rescheduling activity: \(error)")
    //         // Handle the error, e.g., show an alert
    //     }
    // }
}

struct ActionButtonsView: View {
    let onCancel: (ScheduledActivity) -> Void
    let onReschedule: (ScheduledActivity) -> Void
    let scheduledActivity: ScheduledActivity
    let activity: Activity
    @State private var showCancelAlert = false

    var body: some View {
        VStack(spacing: 10) {
            ActionButton(action: { onReschedule(scheduledActivity) }, imageName: "pencil", gradientColors: [.white, .yellow])
            ActionButton(action: { showCancelAlert = true }, imageName: "xmark", gradientColors: [.white, .red])
        }
        .padding(.vertical, 5)
        .alert(isPresented: $showCancelAlert) {
            Alert(
                title: Text("Cancel Activity"),
                message: Text("Are you sure you want to cancel \(activity.name)?"),
                primaryButton: .destructive(Text("Yes")) {
                    onCancel(scheduledActivity)
                },
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
}

struct ActionButton: View {
    let action: () -> Void
    let imageName: String
    let gradientColors: [Color]
    
    var body: some View {
        Button(action: action) {
            Image(systemName: imageName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 40, height: 40)
                .background(
                    ZStack {
                        Color.white
                        LinearGradient(gradient: Gradient(colors: gradientColors.map { $0.opacity(0.2) }), startPoint: .top, endPoint: .bottom)
                    }
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 0.5))
        }
    }
}
