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
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: scheduledActivity.scheduledAt)
        let estimatedTimeInterval = TimeInterval(activity.estimatedTime) ?? 0
        let end = formatter.string(from: scheduledActivity.scheduledAt.addingTimeInterval(estimatedTimeInterval))
        printFonts()
        return "\(start) - \(end)"
    }

    private func printFonts() {
        for family in UIFont.familyNames {
            print("Font family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("Font name: \(name)")
            }
        }
    }

    func unicodeToEmoji(_ unicodeString: String) -> String? {
        // Remove the "U+" prefix and parse the hex value
        let hexString = unicodeString.replacingOccurrences(of: "U+", with: "")
        
        // Convert the hex string to an integer
        if let codePoint = UInt32(hexString, radix: 16), let scalar = Unicode.Scalar(codePoint) {
            // Create a string from the Unicode scalar
            return String(scalar)
        }
        
        return nil
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
                        LocationView(location: location)
                    }
                    ParticipantsView(participantUsers: participantUsers)
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
    let location: Location?
    var body: some View {
        Group {
            if let location = location {
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
            } else {
                Text("Unknown")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func openMaps() {
        guard let location = location else { return }
        let coordinates = "\(location.latitude),\(location.longitude)"
        let googleMapsURL = URL(string: "comgooglemaps://?q=\(coordinates)")
        let appleMapsURL = URL(string: "http://maps.apple.com/?ll=\(coordinates)")
        
        if let url = googleMapsURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = appleMapsURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

struct ParticipantsView: View {
    let participantUsers: [Int: User]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(sortedParticipants.prefix(3), id: \.id) { user in
                    ParticipantView(user: user)
                }
                
                if sortedParticipants.count > 3 {
                    AdditionalParticipantsView(count: sortedParticipants.count - 3)
                }
                
                InviteParticipantView()
            }
        }
    }
    
    private var sortedParticipants: [User] {
        participantUsers.values.sorted { $0.id == 3 ? true : $1.id == 3 ? false : $0.id < $1.id }
    }
}

struct ParticipantView: View {
    let user: User
    
    var body: some View {
        ZStack {
            if let profilePicture = user.profilePicture {
                Image(profilePicture)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(String(user.name.prefix(1)))
                    .font(.custom("Poppins-Bold", size: 16))
                    .foregroundColor(.gray)
            }
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
                .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 0.5)) // Updated this line
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
struct InviteParticipantView: View {
    var body: some View {
        Button(action: inviteParticipant) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [Color.white, Color.yellow].map { $0.opacity(0.2) }), startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 0.5)) // Updated this line
                
                Text("+")
                    .font(.custom("Poppins-Regular", size: 20))
                    .foregroundColor(.black)
            }
        }
    }
    
    private func inviteParticipant() {
        // Empty logic function for inviting a participant
        // You can implement the invitation logic here in the future
    }
}
