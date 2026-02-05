# Product Requirements Document (Reverse Engineered)

**Application**: Mube
**Version**: 1.0.0+1 (as of analysis)
**Status**: MVP / Production-Ready

## 1. Executive Summary
Mube is a social platform and utility network designed for the music ecosystem. It connects musicians, bands, studios, and event contractors, facilitating hiring, collaboration, and discovery. The app combines "LinkedIn-style" professional networking with "Tinder-style" matching (MatchPoint) for finding musical partners.

## 2. User User Personas
The application supports 4 distinct profile types, each with specific data fields and capabilities:

### 2.1 Professional (`profissional`)
*   **Who**: Individual musicians, singers, DJs, rodies, tech crew.
*   **Key Data**: Artistic Name, Instruments, Genres, Roles (e.g., Drummer, Sound Tech), Media Portfolio.
*   **Apps Goals**: Find bands to join, get gigs, showcase talent.

### 2.2 Band (`banda`)
*   **Who**: Musical groups, bands, orchestras.
*   **Key Data**: Band Name, Genres, current Members (linked users), Press Kit.
*   **Apps Goals**: Find replacement members, book studios, get booked for events.

### 2.3 Studio (`estudio`)
*   **Who**: Recording, rehearsal, and mixing studios.
*   **Key Data**: Services offered (Recording, Rehearsal), Equipment list, Location, Pricing/Availability (implied).
*   **Apps Goals**: Attract clients (bands/musicians) for sessions.

### 2.4 Contractor (`contratante`)
*   **Who**: Venue owners, event organizers, wedding planners.
*   **Key Data**: Organization name, Location, Event types.
*   **Apps Goals**: Discover and book talent for events.

## 3. Core Features & Functional Requirements

### 3.1 Authentication & Onboarding
*   **Login**: Email/Password and potentially Social Login (Google/Apple - infra dependencies).
*   **Registration**: Multi-step wizard.
    *   Step 1: Account Creation (Email/Pass).
    *   Step 2: Profile Type Selection (Crucial branching point).
    *   Step 3: Profile Completion (Dynamic form based on Type).
*   **Account Recovery**: Password reset flow.

### 3.2 Main Feed
*   **Content**: Algorithmically sorted list of Cards.
*   **Types**:
    *   **Artists**: Discovery of new musicians.
    *   **Opportunities**: Job posts or "Looking for" ads (implied by feed structure).
*   **Interaction**: Like, Connect/Follow (implied).

### 3.3 MatchPoint (The "Matching" Engine)
*   **Concept**: Location-based discovery of musical partners.
*   **Capabilities**:
    *   **Radar**: Find users within a specific radius (Geohash based).
    *   **Filters**: Intent (Serious vs Hobby), Genres, Roles.
    *   **Swiping/Action**: Send "Connect" request.

### 3.4 Chat & Messaging
*   **Direct Messaging**: 1-on-1 conversations between users.
*   **MatchPoint Integration**: Successful matches likely auto-create a conversation.
*   **Media Support**: Sending text, potentially images/audio.

### 3.5 Profile & Portfolio
*   **Public Profile**: Viewable by others. Shows Bio, Stats, Gallery.
*   **Edit Profile**: Comprehensive form to update professional details.
*   **Media Gallery**:
    *   **Photos**: Up to 6 images.
    *   **Videos**: Up to 3 videos (Youtube links or upload).
    *   **Management**: DND reordering, Delete, Add.

### 3.6 Social Networking
*   **Connections**: "Invites" system to manage friend requests/band invites.
*   **Favorites**: Save interesting profiles for later.
*   **Blocking**: Privacy control to block unwanted users.

### 3.7 Tools & Utilities
*   **Guitar Tuner**: Built-in chromatic tuner tool for musicians (Feature flag: `active`).
*   **Developer Tools**: Internal menu for debugging/logging.

### 3.8 Settings & Privacy
*   **Addresses**: Manage saved locations (for Discovery).
*   **Privacy**: Ghost Mode (hide visibility), Account Deactivation.
*   **Support**: Ticket creation system for help.
*   **Legal**: Terms of Use and Privacy Policy viewers.

## 4. Navigation Structure
*   **Bottom Navigation Bar** (Main Shell):
    *   Feed
    *   Search
    *   MatchPoint
    *   Chat
    *   Settings
*   **Top Level Routes**: Profile Edit, Public Profile, Splash, Onboarding.

## 5. Non-Functional Requirements
*   **Performance**: Cached images (`cached_network_image`), List virtualization.
*   **Offline Mode**: Basic support checking (connectivity).
*   **Security**: Auth Guards on routes, Firebase Security Rules (Backend).
