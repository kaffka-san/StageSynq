import Foundation

enum PredefinedPlaylists {
    static let lucieBila: Playlist = {
        let songs: [Song] = [
            Song(name: "Znameni", durationMinutes: 3, durationSeconds: 48, order: 0),
            Song(name: "Nechci se dat", durationMinutes: 2, durationSeconds: 56, order: 1),
            Song(name: "Kompas", durationMinutes: 3, durationSeconds: 57, order: 2),
            Song(name: "Mam rada", durationMinutes: 3, durationSeconds: 40, order: 3),
            Song(name: "Utek", durationMinutes: 4, durationSeconds: 9, order: 4),
            Song(name: "Miluji te", durationMinutes: 5, durationSeconds: 31, order: 5),
            Song(name: "SMS", durationMinutes: 3, durationSeconds: 16, order: 6),
            Song(name: "Tygrice", durationMinutes: 3, durationSeconds: 32, order: 7),
            Song(name: "Miluju", durationMinutes: 3, durationSeconds: 40, order: 8),
            Song(name: "Voda", durationMinutes: 3, durationSeconds: 43, order: 9),
            Song(name: "Most pres minulost", durationMinutes: 4, durationSeconds: 18, order: 10),
            Song(name: "Amen", durationMinutes: 3, durationSeconds: 47, order: 11),
            Song(name: "Protoze", durationMinutes: 3, durationSeconds: 10, order: 12),
            Song(name: "Tata", durationMinutes: 3, durationSeconds: 59, order: 13),
            Song(name: "Mama", durationMinutes: 2, durationSeconds: 44, order: 14),
            Song(name: "Neverim", durationMinutes: 5, durationSeconds: 13, order: 15),
            Song(name: "Dekuju ti", durationMinutes: 4, durationSeconds: 9, order: 16),
            Song(name: "Ruzovy bryle", durationMinutes: 3, durationSeconds: 43, order: 17),
            Song(name: "Piskovec", durationMinutes: 2, durationSeconds: 55, order: 18),
            Song(name: "Amor Magor", durationMinutes: 2, durationSeconds: 9, order: 19),
            Song(name: "Zpivas mi requiem", durationMinutes: 2, durationSeconds: 44, order: 20),
            Song(name: "Hana Zana a Laska je laska", durationMinutes: 8, durationSeconds: 26, order: 21),
            Song(name: "Dobry kafe", durationMinutes: 3, durationSeconds: 46, order: 22),
            Song(name: "Obycejna holka", durationMinutes: 3, durationSeconds: 19, order: 23),
            Song(name: "Bratr Jan", durationMinutes: 4, durationSeconds: 14, order: 24),
            Song(name: "Jsi muj pan", durationMinutes: 3, durationSeconds: 8, order: 25)
        ]
        return Playlist(name: "Lucie Bila", songs: songs)
    }()

    static let all: [Playlist] = [
        lucieBila
    ]
}
