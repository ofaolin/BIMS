import Foundation

// MARK: - Utility Functions
func clearScreen() {
    print("\u{1B}[2J\u{1B}[H", terminator: "")
    print("\u{1B}[3J", terminator: "")
    fflush(stdout)
}

func waitForKeyPress() {
    print("\nPress Enter to return to main menu...")
    _ = readLine()
}

func getInput(prompt: String, allowEmpty: Bool = false) -> String? {
    print(prompt)
    guard let input = readLine() else { return nil }

    if input.lowercased() == "q" {
        return nil
    }

    if !allowEmpty && input.isEmpty {
        return nil
    }

    return input
}

// MARK: - Book Structure
struct Book: Codable, Comparable {
    var title: String
    var author: String
    var isbn: String
    var isRead: Bool

    static func < (lhs: Book, rhs: Book) -> Bool {
        return lhs.author.lowercased() < rhs.author.lowercased()
    }
}

// MARK: - Book Inventory Management
class BookInventory {
    private var books: [Book] = []
    private let saveFile: String

    init() {
        // Get the current working directory
        let currentDirectory = FileManager.default.currentDirectoryPath
        saveFile = (currentDirectory as NSString).appendingPathComponent("bookInventory.json")
        loadInventory()

        // Print the save location for debugging
        print("Save file location: \(saveFile)")
    }

    private func loadInventory() {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: saveFile)),
            let loadedBooks = try? JSONDecoder().decode([Book].self, from: data)
        {
            books = loadedBooks
        }
    }

    private func saveInventory() {
        if let data = try? JSONEncoder().encode(books) {
            try? data.write(to: URL(fileURLWithPath: saveFile))
        }
    }

    func addBook(title: String, author: String, isbn: String, isRead: Bool) {
        guard !books.contains(where: { $0.isbn == isbn }) else {
            clearScreen()
            print("Error: Book with ISBN \(isbn) already exists")
            return
        }

        let book = Book(title: title, author: author, isbn: isbn, isRead: isRead)
        books.append(book)
        saveInventory()

        clearScreen()
        print("Book Added Successfully")
        print("====================")
        printBook(book)
    }

    func removeBook(isbn: String) {
        let initialCount = books.count
        books.removeAll { $0.isbn == isbn }
        saveInventory()

        clearScreen()
        if initialCount != books.count {
            print("Book Removed Successfully")
            print("======================")
        } else {
            print("No Book Found with ISBN: \(isbn)")
            print("===========================")
        }
    }

    func toggleReadStatus(isbn: String) {
        clearScreen()
        if let index = books.firstIndex(where: { $0.isbn == isbn }) {
            books[index].isRead.toggle()
            saveInventory()

            print("Read Status Updated")
            print("=================")
            printBook(books[index])
        } else {
            print("No Book Found with ISBN: \(isbn)")
            print("===========================")
        }
    }

    private func printBook(_ book: Book) {
        print("\nTitle: \(book.title)")
        print("Author: \(book.author)")
        print("ISBN: \(book.isbn)")
        print("Status: \(book.isRead ? "Read" : "Unread")")
        print("------------------------")
    }

    func listBooks() {
        clearScreen()
        let sortedBooks = books.sorted()

        if sortedBooks.isEmpty {
            print("No Books in Inventory")
            print("===================")
            return
        }

        print("Current Inventory")
        print("================")
        print()
        for book in sortedBooks {
            printBook(book)
        }
    }

    func showStatistics() {
        clearScreen()
        let totalBooks = books.count
        let readBooks = books.filter { $0.isRead }.count
        let unreadBooks = totalBooks - readBooks

        var authorCounts: [String: Int] = [:]
        for book in books {
            authorCounts[book.author, default: 0] += 1
        }

        let topAuthors = authorCounts.sorted { $0.value > $1.value }
            .prefix(5)

        let readPercentage = totalBooks > 0 ? Double(readBooks) / Double(totalBooks) * 100 : 0

        print("Collection Statistics")
        print("====================")
        print()
        print("Total Books: \(totalBooks)")
        print("Read Books: \(readBooks) (\(String(format: "%.1f", readPercentage))%)")
        print("Unread Books: \(unreadBooks)")
        print()
        print("Top 5 Authors")
        print("============")

        if topAuthors.isEmpty {
            print("No authors in collection")
        } else {
            for (index, author) in topAuthors.enumerated() {
                print("\(index + 1). \(author.key) (\(author.value) books)")
            }
        }
        // Print the save location for information purposes
        print()
        print("Save File Location")
        print("==================")
        print(saveFile)
    }

    func searchByISBN(_ isbn: String) {
        clearScreen()
        if let book = books.first(where: { $0.isbn.lowercased() == isbn.lowercased() }) {
            print("Book Found")
            print("==========")
            printBook(book)
        } else {
            print("No Book Found")
            print("=============")
            print("ISBN: \(isbn)")
        }
    }

    func searchByTitleOrAuthor(_ searchTerm: String) {
        clearScreen()
        let searchTerm = searchTerm.lowercased()
        let matchingBooks = books.filter {
            $0.title.lowercased().contains(searchTerm)
                || $0.author.lowercased().contains(searchTerm)
        }.sorted()

        if matchingBooks.isEmpty {
            print("No Books Found")
            print("=============")
            print("Search term: \(searchTerm)")
            return
        }

        print("Search Results")
        print("==============")
        print("Found \(matchingBooks.count) matching books:")
        print()
        for book in matchingBooks {
            printBook(book)
        }
    }

    func exportToCSV(filename: String) {
        let sortedBooks = books.sorted()
        var csvString = "Title,Author,ISBN,Read Status\n"

        for book in sortedBooks {
            let escapedTitle = "\"\(book.title.replacingOccurrences(of: "\"", with: "\"\""))\""
            let escapedAuthor = "\"\(book.author.replacingOccurrences(of: "\"", with: "\"\""))\""
            let readStatus = book.isRead ? "Read" : "Unread"
            csvString += "\(escapedTitle),\(escapedAuthor),\(book.isbn),\(readStatus)\n"
        }

        do {
            try csvString.write(
                to: URL(fileURLWithPath: filename), atomically: true, encoding: .utf8)
            clearScreen()
            print("Export Successful")
            print("================")
            print("File: \(filename)")
        } catch {
            clearScreen()
            print("Export Failed")
            print("=============")
            print("Error: \(error.localizedDescription)")
        }
    }

    func importFromCSV(filename: String) {
        clearScreen()
        do {
            let csvContent = try String(contentsOfFile: filename, encoding: .utf8)
            let rows = csvContent.components(separatedBy: .newlines)

            let dataRows = rows.dropFirst().filter { !$0.isEmpty }
            var importCount = 0
            var skipCount = 0

            for row in dataRows {
                var fields: [String] = []
                var currentField = ""
                var insideQuotes = false

                for char in row {
                    if char == "\"" {
                        insideQuotes.toggle()
                    } else if char == "," && !insideQuotes {
                        fields.append(currentField)
                        currentField = ""
                    } else {
                        currentField.append(char)
                    }
                }
                fields.append(currentField)

                fields = fields.map { field in
                    field.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                }

                guard fields.count >= 4,
                    !fields[0].isEmpty,
                    !fields[1].isEmpty,
                    !fields[2].isEmpty
                else {
                    skipCount += 1
                    continue
                }

                let title = fields[0]
                let author = fields[1]
                let isbn = fields[2]
                let isRead = fields[3].lowercased() == "read"

                if !books.contains(where: { $0.isbn == isbn }) {
                    addBook(title: title, author: author, isbn: isbn, isRead: isRead)
                    importCount += 1
                } else {
                    skipCount += 1
                }
            }

            print("Import Summary")
            print("=============")
            print()
            print("Successfully imported: \(importCount) books")
            print("Skipped: \(skipCount) books")
            print("(Invalid format or duplicate ISBN)")
        } catch {
            print("Import Failed")
            print("=============")
            print("Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Menu Functions
func displayMenu() {
    clearScreen()
    print("Book Inventory Management System")
    print("==============================")
    print()
    print("1. Add Book")
    print("2. Remove Book")
    print("3. Toggle Read Status")
    print("4. List Books")
    print("5. Export to CSV")
    print("6. Import from CSV")
    print("7. Search by ISBN")
    print("8. Search by Title/Author")
    print("9. Show Statistics")
    print("10. Exit")
    print()
    print("Enter your choice (1-10): ", terminator: "")
}

// MARK: - Main Program
func runProgram() {
    let inventory = BookInventory()

    while true {
        displayMenu()

        guard let choice = readLine() else { continue }

        switch choice {
        case "1":
            clearScreen()
            print("Add New Book")
            print("===========")
            print()
            print("(Press 'q' or Enter to return to main menu)")
            print()

            guard let title = getInput(prompt: "Enter title: ") else { continue }
            guard let author = getInput(prompt: "Enter author (LAST, FIRST): ") else { continue }
            guard let isbn = getInput(prompt: "Enter ISBN: ") else { continue }

            guard let readStatus = getInput(prompt: "Have you read this book? (y/n): ") else {
                continue
            }
            let isRead = readStatus.lowercased().starts(with: "y")

            inventory.addBook(title: title, author: author, isbn: isbn, isRead: isRead)
            waitForKeyPress()

        case "2":
            clearScreen()
            print("Remove Book")
            print("===========")
            print()
            print("(Press 'q' or Enter to return to main menu)")
            print()

            guard let isbn = getInput(prompt: "Enter ISBN to remove: ") else { continue }
            inventory.removeBook(isbn: isbn)
            waitForKeyPress()

        case "3":
            clearScreen()
            print("Toggle Read Status")
            print("=================")
            print()
            print("(Press 'q' or Enter to return to main menu)")
            print()

            guard let isbn = getInput(prompt: "Enter ISBN to toggle: ") else { continue }
            inventory.toggleReadStatus(isbn: isbn)
            waitForKeyPress()

        case "4":
            inventory.listBooks()
            waitForKeyPress()

        case "5":
            clearScreen()
            print("Export to CSV")
            print("============")
            print()
            print("(Press 'q' or Enter to return to main menu)")
            print()

            guard
                let filename = getInput(prompt: "Enter filename for export (e.g., inventory.csv): ")
            else { continue }
            inventory.exportToCSV(filename: filename)
            waitForKeyPress()

        case "6":
            clearScreen()
            print("Import from CSV")
            print("==============")
            print()
            print("(Press 'q' or Enter to return to main menu)")
            print()

            guard let filename = getInput(prompt: "Enter CSV filename to import: ") else {
                continue
            }
            inventory.importFromCSV(filename: filename)
            waitForKeyPress()

        case "7":
            clearScreen()
            print("Search by ISBN")
            print("=============")
            print()
            print("(Press 'q' or Enter to return to main menu)")
            print()

            guard let isbn = getInput(prompt: "Enter ISBN to search: ") else { continue }
            inventory.searchByISBN(isbn)
            waitForKeyPress()

        case "8":
            clearScreen()
            print("Search by Title/Author")
            print("====================")
            print()
            print("(Press 'q' or Enter to return to main menu)")
            print()

            guard let searchTerm = getInput(prompt: "Enter search term: ") else { continue }
            inventory.searchByTitleOrAuthor(searchTerm)
            waitForKeyPress()

        case "9":
            inventory.showStatistics()
            waitForKeyPress()

        case "10":
            clearScreen()
            print("Thank you for using the Book Inventory Management System!")
            print("================================================")
            print()
            print("Goodbye!")
            return

        default:
            clearScreen()
            print("Invalid Selection")
            print("================")
            waitForKeyPress()
        }
    }
}

// MARK: - Program Entry Point
runProgram()
