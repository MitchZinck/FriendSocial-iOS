import SwiftUI

struct InviteCard: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var isExpanded: Bool = false
    @State private var selectedEventId: Int?
    let invite: Invite
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .center) {
                    let startTime = invite.scheduledAt.formatted(date: .omitted, time: .shortened)
                    let endTime = invite.scheduledAt.addingTimeInterval(TimeInterval(invite.estimatedTime) ?? 0).formatted(date: .omitted, time: .shortened)
                    Text(startTime)
                        .font(.custom(FontNames.poppinsRegular, size: 16))
                    Text(endTime)
                        .font(.custom(FontNames.poppinsRegular, size: 16))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(invite.emoji + " " + invite.event)
                        .font(.custom(FontNames.poppinsMedium, size: 16))
                        .lineLimit(1)
                    
                    Text("📍 " + invite.locationName)
                        .font(.custom(FontNames.poppinsRegular, size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 15) {
                    HStack(alignment: .top) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text(invite.description)
                            .font(.custom(FontNames.poppinsRegular, size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        ParticipantsPreview(participants: invite.participants, participantUsers: invite.participantUsers, selectedEventId: $selectedEventId, participantPPSize: 30)
                        Spacer()
                        Button(action: {
                            Task {
                                await dataManager.respondToInvite(invite: invite, status: "Accepted")
                            }
                        }) {
                            Label("Accept", systemImage: "checkmark")
                                .font(.custom(FontNames.poppinsRegular, size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green)
                                .cornerRadius(15)
                        }
                        Button(action: {
                            Task {
                                await dataManager.respondToInvite(invite: invite, status: "Declined")
                            }
                        }) {
                            Label("Decline", systemImage: "xmark")
                                .font(.custom(FontNames.poppinsRegular, size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.red)
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 5)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
}
