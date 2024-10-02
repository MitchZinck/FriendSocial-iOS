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
                // Get first 3 participants, ordered by invite status: Accepted, Pending, Declined
                ForEach(participants.sorted(by: { 
                    let order = ["accepted", "pending", "declined"]
                    let index1 = order.firstIndex(of: $0.inviteStatus.lowercased()) ?? order.count
                    let index2 = order.firstIndex(of: $1.inviteStatus.lowercased()) ?? order.count
                    return index1 < index2
                }).prefix(3), id: \.userID) { participant in
                    if let user = participantUsers[participant.userID] {
                        ZStack(alignment: .topTrailing) {
                            Image(user.profilePicture ?? "default_profile")
                                .resizable()
                                .scaledToFill()
                                .frame(width: participantPPSize, height: participantPPSize)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(statusColor(for: participant.inviteStatus), lineWidth: 2)
                                )
                            
                            statusIcon(for: participant.inviteStatus)
                                .offset(x: 2, y: -2)
                        }
                    }
                }

                if participants.count > 3 {
                    Text("+\(participants.count - 3)")
                        .font(.custom(FontNames.poppinsRegular, size: 12))
                        .foregroundColor(.gray)
                        .frame(width: participantPPSize * 0.7, height: participantPPSize * 0.7)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
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