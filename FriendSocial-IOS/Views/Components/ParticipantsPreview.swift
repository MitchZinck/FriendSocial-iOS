import SwiftUI

struct ParticipantsPreview: View {
    let participants: [ActivityParticipant]
    let participantUsers: [Int: User]
    @Binding var selectedEventId: Int?
    @State private var showAllParticipants: Bool = false
    let participantPPSize: CGFloat
    
    var body: some View {
        Button(action: {
            showAllParticipants = true
        }) {
            HStack(spacing: 5) {
                ForEach(participants.prefix(3).indices, id: \.self) { index in
                    if let user = participantUsers[participants[index].userID] {
                        ZStack(alignment: .topTrailing) {
                            Image(user.profilePicture ?? "default_profile")
                                .resizable()
                                .scaledToFill()
                                .frame(width: participantPPSize, height: participantPPSize)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(statusColor(for: participants[index].inviteStatus), lineWidth: 2)
                                )
                            
                            statusIcon(for: participants[index].inviteStatus)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                if participants.count > 3 {
                    Text("+\(participants.count - 3)")
                        .font(.custom(FontNames.poppinsRegular, size: 12))
                        .foregroundColor(.gray)
                        .frame(width: participantPPSize, height: participantPPSize)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .sheet(isPresented: $showAllParticipants) {
            ParticipantsView(participants: participants, participantUsers: participantUsers)
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
    
    private func statusIcon(for status: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
            
            Image(systemName: statusImageName(for: status))
                .resizable()
                .scaledToFit()
                .frame(width: 8, height: 8)
                .foregroundColor(statusColor(for: status))
        }
    }
    
    private func statusImageName(for status: String) -> String {
        switch status.lowercased() {
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
}