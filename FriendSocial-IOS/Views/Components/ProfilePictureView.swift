import SwiftUI

struct ProfilePictureView: View {
    let user: User?
    let size: CGFloat
    @Binding var isProfileMenuOpen: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            profileButton
            
            if isProfileMenuOpen {
                ProfileDropdownMenu(isProfileMenuOpen: $isProfileMenuOpen)
                    .offset(y: size + 10)
                    .zIndex(1)
                    .transition(.opacity)
                    .animation(.easeInOut, value: isProfileMenuOpen)
            }
        }
        .onDisappear {
            isProfileMenuOpen = false // Close dropdown when view disappears
        }
    }

    private var profileButton: some View {
        Button(action: {
            withAnimation {
                isProfileMenuOpen.toggle()
            }
        }) {
            profileImage
                .frame(width: size, height: size)
                .clipShape(Circle())
                .shadow(radius: 3)
        }
    }

    private var profileImage: some View {
        Group {
            if let profilePictureName = user?.profilePicture {
                Image(profilePictureName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Text(user?.name.prefix(1).uppercased() ?? "")
                            .font(.system(size: size * 0.4, weight: .bold))
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}

struct ProfileDropdownMenu: View {
    @Binding var isProfileMenuOpen: Bool
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            dropdownOption(text: "Activities")
            dropdownOption(text: "Free Time")
            dropdownOption(text: "Settings")
            dropdownOption(text: "Logout", action: logoutAction)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .frame(width: 150)
        .zIndex(1)
        .offset(x: -75) // Center the dropdown under the profile picture
    }

    private func dropdownOption(text: String, action: (() -> Void)? = nil) -> some View {
        Button(action: {
            isProfileMenuOpen = false
            action?()
        }) {
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .padding(.vertical, 5)
        }
    }

    private func logoutAction() {
        print("Logged out")
    }
}
