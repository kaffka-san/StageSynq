# Feature Description — Song Playlist Timer iOS App

## Overview

The app is a simple iPhone-only utility for people working in the event business who need to track the duration of songs in a playlist and clearly see when the currently selected song will end.

Users can create multiple playlists. Each playlist contains any number of songs. For every song, the user enters:
- song name
- song length in minutes and seconds

The app does not play audio files. It works only as a timer/countdown tool for manually tracked songs.

The main goal is to let the user quickly start a countdown for a selected song, pause it, reset it, and clearly see how much time remains until the song ends.

---

## Target Users

People working in event business, for example:
- DJs
- event coordinators
- performers
- production staff
- presenters managing timed music segments

They need a reliable and simple countdown view for songs during live events.

---

## Core Value

The app helps users:
- organize songs into playlists
- track song duration manually
- see exact remaining time for the current song
- know when a song ends
- quickly control countdown during live event situations

---

## Scope

### Platform
- iPhone only

### Persistence
- All playlists and songs are persisted locally on device
- Data must remain available after app restart

### Timer Behavior
- User manually starts a song timer
- User can pause the timer
- User can reset the timer
- When the timer reaches zero, it stops
- App does **not** automatically continue to the next song
- App should continue countdown correctly when in background

### Feedback
- Device should vibrate when the song countdown ends

---

## Functional Requirements

## 1. Playlist Management

User can:
- create a new playlist
- view all playlists
- rename a playlist
- delete a playlist
- open a playlist detail

### Playlist fields
- `id`
- `name`
- `songs`
- `createdAt`
- `updatedAt`

### Validation
- playlist name is required
- playlist name can be edited later

---

## 2. Song Management

Inside a playlist, user can:
- add a new song
- edit an existing song
- delete a song
- reorder songs within playlist

### Song fields
- `id`
- `name`
- `durationMinutes`
- `durationSeconds`
- `order`

### Validation
- song name is required
- duration must be greater than 0
- seconds must be in range `0...59`
- minutes must be `>= 0`

### Notes
- user enters duration manually
- app does not import songs from Apple Music or other audio libraries

---

## 3. Playlist Detail Screen

Playlist detail shows:
- playlist name
- list of songs in order
- each song row with:
  - song name
  - formatted duration (`mm:ss`)
- ability to tap song to open edit
- ability to reorder songs
- ability to select one song for countdown

The playlist detail acts as the main working screen for event use.

---

## 4. Song Countdown / Timer

For a selected song, user can:
- start countdown
- pause countdown
- resume countdown
- reset countdown to original duration

### Timer display
Show:
- song name
- original duration
- current remaining time in large format
- clear state indicator:
  - ready
  - running
  - paused
  - finished

### Timer behavior
- countdown is based on the selected song duration
- when timer reaches zero:
  - timer stops
  - state changes to finished
  - device vibrates
- app does not auto-play next song
- only current song countdown is displayed
- no total playlist countdown is needed

### Background behavior
- timer must continue correctly when app goes to background
- countdown accuracy should be based on timestamps, not only active in-memory ticking
- when app returns to foreground, remaining time must be recalculated correctly

---

## 5. Persistence

The app must persist:
- playlists
- songs
- song order inside playlist

Optional persistence for better UX:
- last opened playlist
- last selected song
- timer state if app is terminated while countdown is active

### Recommended MVP persistence
- store playlists and songs locally
- restore data on next launch

---

## User Stories

### Playlist creation
- As a user, I want to create a playlist so I can prepare songs for an event.
- As a user, I want to rename or delete a playlist so I can keep my playlists organized.

### Song management
- As a user, I want to add songs with custom names and durations so I can prepare timing in advance.
- As a user, I want to edit a song later so I can fix mistakes or update duration.
- As a user, I want to reorder songs so they match the real event sequence.

### Timer usage
- As a user, I want to start a countdown for a selected song so I know how much time is left.
- As a user, I want to pause and resume the countdown so I can handle interruptions during an event.
- As a user, I want to reset the countdown so I can start the song timing again from the beginning.
- As a user, I want the phone to vibrate when the timer ends so I notice the song is finished.

### Reliability
- As a user, I want my playlists to stay saved after restarting the app.
- As a user, I want the countdown to remain correct even if the app goes to background.

---

## Main User Flow

## Flow 1 — Create playlist
1. User opens app
2. User sees list of playlists
3. User taps "Create Playlist"
4. User enters playlist name
5. Playlist is saved
6. User is navigated to playlist detail

## Flow 2 — Add songs
1. User opens playlist
2. User taps "Add Song"
3. User enters:
   - song name
   - minutes
   - seconds
4. User saves song
5. Song appears in playlist list

## Flow 3 — Edit song
1. User taps existing song
2. Edit screen opens
3. User updates name and/or duration
4. User saves changes
5. Playlist updates immediately

## Flow 4 — Reorder songs
1. User enters reorder mode or uses drag-and-drop
2. User moves songs into desired order
3. New order is saved automatically

## Flow 5 — Run timer
1. User selects a song in playlist
2. Countdown view shows selected song
3. User taps Play
4. Countdown starts
5. User may Pause
6. User may Resume
7. User may Reset
8. When time reaches zero, timer stops and phone vibrates

---

## Screens

## 1. Playlist List Screen
Purpose:
- show all playlists
- create new playlist
- delete or rename playlist

Suggested content:
- screen title
- list of playlists
- create button
- empty state when no playlists exist

## 2. Playlist Detail Screen
Purpose:
- manage songs in one playlist
- select a song for timing
- reorder songs

Suggested content:
- playlist name
- add song button
- list of songs with durations
- reorder interaction
- tap row to edit song
- tap row or dedicated control to load selected song into timer

## 3. Song Add/Edit Screen
Purpose:
- create or edit song

Suggested fields:
- song name text field
- minutes input
- seconds input
- save button
- validation messages

## 4. Timer Screen / Timer Section
Purpose:
- display current selected song countdown and controls

Suggested content:
- selected song name
- remaining time in large text
- play/pause button
- reset button
- status label

This can be either:
- a dedicated timer screen
- or a timer section embedded in playlist detail

---

## State Management Requirements

The timer feature should support these states:
- `idle` — no song selected
- `ready` — song selected, not started
- `running`
- `paused`
- `finished`

### Required transitions
- idle -> ready
- ready -> running
- running -> paused
- paused -> running
- running -> finished
- paused -> ready via reset
- finished -> ready via reset
- selecting another song replaces current timer state with new selected song in ready state

---

## Data Model Example

```swift
struct Playlist: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var songs: [Song]
    let createdAt: Date
    var updatedAt: Date
}

struct Song: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var durationSecondsTotal: Int
    var order: Int
}