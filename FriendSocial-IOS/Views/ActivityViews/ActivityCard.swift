import SwiftUI

struct ActivityCard: View {
    let activity: Activity
    let scheduledActivity: ScheduledActivity
    let location: Location?
    let participants: [ActivityParticipant]
    let participantUsers: [Int: User]
    let onCancel: (ScheduledActivity) -> Void
    let onReschedule: (ScheduledActivity) -> Void

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
                    ParticipantsView(participants: participants, participantUsers: participantUsers)
                }
                Spacer()
                VStack {
                    Spacer()
                    ActionButtonsView(onCancel: onCancel, onReschedule: onReschedule, scheduledActivity: scheduledActivity)
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

private struct ParticipantsView: View {
    let participants: [ActivityParticipant]
    let participantUsers: [Int: User]
    @State private var showAllParticipants: Bool = false
    
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Button(action: {
                    showAllParticipants = true
                }) {
                    // Sort participants by invite status, with Accepted at the top, then Pending, then Rejected
                    let sortedParticipants = participants.sorted { $0.inviteStatus < $1.inviteStatus }
                    ForEach(sortedParticipants.prefix(3), id: \.id) { participant in
                        if let user = participantUsers[participant.userID] {
                            ParticipantView(user: user, inviteStatus: participant.inviteStatus)
                        }
                    }
                    
                    if participants.count > 3 {
                        AdditionalParticipantsView(count: participants.count - 3)
                    }
                }
                InviteParticipantView()
            }
        }
        .sheet(isPresented: $showAllParticipants) {
            AllParticipantsView(participants: participants, participantUsers: participantUsers)
        }
    }
}

private struct ParticipantView: View {
    let user: User
    let inviteStatus: String
    
    var body: some View {
        ZStack {
            if let profilePicture: String = user.profilePicture {
                Image(profilePicture)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(statusColor(for: inviteStatus), lineWidth: 2)
                    )
                    .padding(.vertical, 5)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(statusColor(for: inviteStatus), lineWidth: 2)
                    )
                
                Text(String(user.name.prefix(1)))
                    .font(.custom("Poppins-Bold", size: 16))
                    .foregroundColor(.gray)
            }
            
            statusIcon
                .offset(x: 15, y: -15)
        }
    }
    
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
            
            Image(systemName: statusImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundColor(statusColor(for: inviteStatus))
        }
    }
    
    private var statusImageName: String {
        switch inviteStatus.lowercased() {
        case "accepted":
            return "checkmark"
        case "pending":
            return "questionmark"
        case "rejected":
            return "xmark"
        default:
            return ""
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "accepted":
            return .green
        case "pending":
            return .yellow
        case "rejected":
            return .red
        default:
            return .clear
        }
    }
}

struct ActionButtonsView: View {
    let onCancel: (ScheduledActivity) -> Void
    let onReschedule: (ScheduledActivity) -> Void
    let scheduledActivity: ScheduledActivity
    
    var body: some View {
        VStack(spacing: 10) {
            ActionButton(action: { onReschedule(scheduledActivity) }, imageName: "pencil", gradientColors: [.white, .yellow])
            ActionButton(action: { onCancel(scheduledActivity) }, imageName: "xmark", gradientColors: [.white, .red])
        }
        .padding(.vertical, 5)
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

struct AdditionalParticipantsView: View {
    let count: Int
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 25, height: 25)
            
            Text("+\(count)")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.gray)
        }
    }
}

struct AllParticipantsView: View {
    let participants: [ActivityParticipant]
    let participantUsers: [Int: User]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(participants.sorted { $0.inviteStatus < $1.inviteStatus }, id: \.id) { participant in
                    if let user = participantUsers[participant.userID] {
                        HStack {
                            ParticipantView(user: user, inviteStatus: participant.inviteStatus)
                            Text(user.name)
                                .font(.custom("Poppins-Regular", size: 16))
                            Spacer()
                            Text(participant.inviteStatus)
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("All Participants")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct InviteParticipantView: View {
    var body: some View {
        Button(action: inviteParticipant) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [Color.white, Color.yellow].map { $0.opacity(0.2) }), startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 0.5))
                
                Text("+")
                    .font(.custom("Poppins-Regular", size: 20))
                    .foregroundColor(.black)
            }
        }
    }
    
    private func inviteParticipant() {
        // Empty logic function for inviting a participant
    }
}
