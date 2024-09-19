import SwiftUI

struct EmojiPicker: View {
    @Binding var selectedEmoji: String
    @State private var isPresented = false
    
    let emojis = ["😊", "🎉", "🏋️‍♂️", "🍔", "🎮", "📚", "🎨", "🎵", "🏖️", "🍿", "⚽️", "🏀", "🎳",
    "🏓", "🎸", "🍻", "🍕", "🎬", "🚴‍♀️", "🏊‍♂️", "🧗‍♀️", "🏄‍♂️", "🏂", "🎭", "🎤", "🎹", "🎯", "🎲", 
    "🍳", "🍖", "🍣", "🍩", "☕️", "🍹", "🌄", "🏕️", "🏰", "🎢", "🛶", "🚗", "✈️", "🚂", 
    "🖼️", "📷", "🎧", "🕹️", "🧩", "🃏", "🎰", "🌈"]
    
    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            Text(selectedEmoji)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(Color.white)
                .clipShape(Circle())
        }
        .sheet(isPresented: $isPresented) {
            VStack {
                Text("Select an Emoji")
                    .font(.headline)
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                            isPresented = false
                        }) {
                            Text(emoji)
                                .font(.system(size: 30))
                        }
                    }
                }
                .padding()
            }
        }
    }
}
