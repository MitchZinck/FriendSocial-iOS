import SwiftUI

struct ParticipantsView: View {
    let participants: [ActivityParticipant]
    let participantUsers: [Int: User]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(participants, id: \.id) { participant in
                    if let user = participantUsers[participant.userID] {
                        HStack {
                            ZStack(alignment: .topTrailing) {
                                Image(user.profilePicture ?? "default_profile")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(statusColor(for: participant.inviteStatus), lineWidth: 2)
                                    )
                                
                                statusIcon(for: participant.inviteStatus)
                                    .offset(x: 3, y: -3)
                            }
                            Text(user.name)
                                .font(.custom(FontNames.poppinsRegular, size: 16))
                        }
                    }
                }
            }
            .navigationTitle("Participants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
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
                .frame(width: 16, height: 16)
            
            Image(systemName: statusImageName(for: status))
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
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