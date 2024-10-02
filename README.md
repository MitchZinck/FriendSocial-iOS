# FriendSocial-IOS

FriendSocial-IOS is an iOS application built with SwiftUI that allows users to connect with friends, schedule activities, and manage social events. This app is designed to make it easier for friends to coordinate their free time and plan activities together.

## Features

- View and manage upcoming activities
- Schedule new activities with friends
- See which friends are free at a given time
- Receive activity suggestions
- Manage user profile and preferences

## Requirements

- iOS 17.5+
- Xcode 15.0+
- Swift 5.0+

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/FriendSocial-IOS.git
   ```
2. Open the project in Xcode:
   ```
   cd FriendSocial-IOS
   open FriendSocial-IOS.xcodeproj
   ```
3. Build and run the project in Xcode.

## Project Structure

The project follows a standard iOS app structure:

- `Models/`: Data models for the application
- `Views/`: SwiftUI views for the user interface
- `Managers/`: Business logic and data management
- `Services/`: API and network-related services
- `Utilities/`: Helper functions and extensions

## Backend

The backend for this application is built with GoLang and is located in a separate repository called FriendSocial. Make sure to set up and run the backend server before using this iOS app.

## Custom Fonts

This project uses custom fonts (Poppins and Inter). The fonts are included in the project and configured in the Info.plist file.

## Key Components

- `ContentView`: The main view of the application
- `HomeView`: The home screen showing upcoming activities and friend availability
- `ScheduleActivityView`: View for scheduling new activities
- `ActivitiesView`: List of all activities
- `DataManager`: Manages the application's data and state