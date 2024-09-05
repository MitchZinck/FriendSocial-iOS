import SwiftUI

struct ActivityCard: View {
    let activity: Activity
    let scheduledActivity: ScheduledActivity
    let location: Location?
    let participants: [ActivityParticipant]
    let participantUsers: [Int: User]
    let onCancel: (ScheduledActivity) -> Void
    let onReschedule: (ScheduledActivity) -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text(activity.name)
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(formattedDate(scheduledActivity.scheduledAt))
                            .font(.subheadline)
                    }
                    
                    if let location = location {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text(location.name)
                                .font(.subheadline)
                        }
                        HStack {
                            Image(systemName: "location")
                            Text("\(location.address), \(location.city), \(location.state) \(location.zipCode)")
                                .font(.subheadline)
                        }
                    } else {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text("Unknown")
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(participantUsers.values).sorted { $0.id == 3 ? true : $1.id == 3 ? false : $0.id < $1.id }, id: \.id) { user in
                        if let user = participantUsers[user.id] {
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(user.id == 3 ? .green : .blue)
                                Text(user.id == 3 ? "You" : user.name)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .padding()
            }
            
            HStack {
                Button(action: { onCancel(scheduledActivity) }) {
                    Text("Cancel")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                
                Spacer()
                
                Button(action: { onReschedule(scheduledActivity) }) {
                    Text("Reschedule")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
            }
            .padding()
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}