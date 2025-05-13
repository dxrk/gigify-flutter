# Gigify: CMSC436 Group Project

**Course:** CMSC436 - Mobile Application Development  
**Platform:** Flutter (Dart) — Focused on Android Development  
**Group Members:**

- Luke Walker
- Ben Talesnik
- Pranav Bolla
- Owen Davitz
- Scott Dobo

## Project Overview

This repository contains our group project for CMSC436 at the University of Maryland. The goal of this project is to design and implement an innovative mobile application—the "gigify"—that leverages the unique capabilities of mobile devices. Our app is built using the Flutter framework, with a primary focus on Android development.

## App Description

Gigify is an app designed to enhance the concert experience for its users. It provides personal event recommendations and helps guide social planning by fostering a social environment, allowing users to connect with friends, express interest or satisfaction in an event through a 'like' feature, and coordinate attendance plans within friends through in-app messaging. Additionally, users receive notifications regarding upcoming concerts and events from their favorite artists, as well as events that their social networks are planning or are interested in.

## Minimal Goals

- Spotify and Ticketmaster/BandsInTown API interaction
- Recommend concerts that match based on bands/genres
- Gives Concert recommendations based on bands/genres
- Use location data to pull nearby concert recommendations

## Stretch Goals

- Connect with other people with similar music and concert tastes, and assign a "compatibility score".cd
- Social media type feed with images from concerts
  - Images also may be posted under an artists page or venue page so other consumers can see what a past event was like.
- Personalizable Sprite for profiles
  - User is given specialized clothing/art for going to concerts
- Featured concerts
  - Concerts recommended to all users

## Project Timeline

**Milestone 1:**

- Personal profile tab with dummy data (top genres/artists)
- Recommended nearby concert tabs with dummy data (headliner, venue, price, date, time, distance)
- Discover tab with all nearby concerts

**Milestone 2:**

- Spotify integration (user login, pull top artists/genres)
- User settings panel (e.g., max distance for concert search)

**Milestone 3:**

- Ticketmaster integration (pull and sort nearby concerts)
- Combine Spotify and concert data for recommendations

**Final Submission:**

- At least one stretch goal completed
- Paperwork and video demonstration finished

## Key Features

- **Built with Flutter:** Cross-platform development using Dart, with Android as the main target.
- **Collaborative Effort:** Developed as a team project, emphasizing group collaboration and agile development practices.
- **Mobile-First:** The app takes advantage of mobile device features such as sensors, camera, location, and more.
- **Beyond the Classroom:** Implements features and technologies that go beyond the standard CMSC436 curriculum.

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/dxrk/gigify-flutter.git
   cd gigify-flutter
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Create a `.env` file:**

   ```bash
   touch .env
   ```

   Add the following variables to the `.env` file:

   ```bash
      SPOTIFY_CLIENT_ID=your_spotify_client_id
      SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
      SPOTIFY_REDIRECT_URI=nextbigthing://callback
      TICKETMASTER_API_KEY=your_ticketmaster_api_key
   ```

4. **Run the app (Android):**
   ```bash
   flutter run
   ```

## Project Structure

- `lib/` — Main source code (organized by features, services, models, and utilities)
- `README.md` — Project documentation (this file)
- `Final-Report.pdf` — Final project report
- `Video-Tutorial.mp4` — Demo video

## Deliverables

- **Project Proposal**
- **Milestone Reports**
- **Final Report** (see `Final-Report.pdf`)
- **Demonstration Video** (see `Video-Tutorial.mp4`)
- **Working Flutter Project**

## Requirements

- Flutter SDK (see [flutter.dev](https://flutter.dev/docs/get-started/install))
- Android Studio or compatible IDE
- Android device or emulator for testing

## Acknowledgments

This project is part of the CMSC436 curriculum and follows the guidelines and requirements set forth by the course instructors.
