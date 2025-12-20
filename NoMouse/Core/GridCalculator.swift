import Foundation
import CoreGraphics
import AppKit

/// Calculates grid positions for two-letter navigation
/// Dynamically adapts to any screen resolution
struct GridCalculator {
    
    /// Number of columns (A-Z = 26)
    let columns: Int = 26
    
    /// Number of rows (A-Z = 26)
    let rows: Int = 26
    
    /// Screen bounds to calculate grid for
    let screenBounds: CGRect
    
    /// Cell width in pixels
    var cellWidth: CGFloat {
        screenBounds.width / CGFloat(columns)
    }
    
    /// Cell height in pixels
    var cellHeight: CGFloat {
        screenBounds.height / CGFloat(rows)
    }
    
    // MARK: - Grid Labels
    
    /// All grid labels from AA to ZZ
    var allLabels: [String] {
        var labels: [String] = []
        for row in 0..<rows {
            for col in 0..<columns {
                let label = labelFor(row: row, column: col)
                labels.append(label)
            }
        }
        return labels
    }
    
    /// Get the label for a specific grid cell
    /// - Parameters:
    ///   - row: Row index (0 = top)
    ///   - column: Column index (0 = left)
    /// - Returns: Two-letter label (e.g., "AA", "AB", etc.)
    func labelFor(row: Int, column: Int) -> String {
        let firstChar = Character(UnicodeScalar(65 + row)!)   // A-Z for rows
        let secondChar = Character(UnicodeScalar(65 + column)!) // A-Z for columns
        return String([firstChar, secondChar])
    }
    
    // MARK: - Position Calculation
    
    /// Convert a two-letter label to screen coordinates (center of cell)
    /// - Parameter label: Two-letter label (e.g., "AB")
    /// - Returns: Center point of the cell, or nil if invalid label
    func positionFor(label: String) -> CGPoint? {
        guard label.count == 2 else { return nil }
        
        let chars = Array(label.uppercased())
        guard let firstChar = chars.first,
              let secondChar = chars.last,
              let rowIndex = charToIndex(firstChar),
              let colIndex = charToIndex(secondChar),
              rowIndex < rows,
              colIndex < columns else {
            return nil
        }
        
        // Calculate center of cell
        let x = screenBounds.minX + (CGFloat(colIndex) + 0.5) * cellWidth
        let y = screenBounds.minY + (CGFloat(rowIndex) + 0.5) * cellHeight
        
        return CGPoint(x: x, y: y)
    }
    
    /// Get all cells that start with a specific letter (for highlighting)
    /// - Parameter firstLetter: The first letter of the two-letter code
    /// - Returns: Array of (label, position) tuples
    func cellsStartingWith(_ firstLetter: Character) -> [(label: String, position: CGPoint, frame: CGRect)] {
        guard let rowIndex = charToIndex(firstLetter) else { return [] }
        
        var cells: [(String, CGPoint, CGRect)] = []
        for col in 0..<columns {
            let label = labelFor(row: rowIndex, column: col)
            if let pos = positionFor(label: label) {
                let frame = cellFrame(row: rowIndex, column: col)
                cells.append((label, pos, frame))
            }
        }
        return cells
    }
    
    /// Get the frame (rect) of a cell
    func cellFrame(row: Int, column: Int) -> CGRect {
        let x = screenBounds.minX + CGFloat(column) * cellWidth
        let y = screenBounds.minY + CGFloat(row) * cellHeight
        return CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
    }
    
    /// Get the frame for a label
    func frameFor(label: String) -> CGRect? {
        guard label.count == 2 else { return nil }
        
        let chars = Array(label.uppercased())
        guard let rowIndex = charToIndex(chars[0]),
              let colIndex = charToIndex(chars[1]) else {
            return nil
        }
        
        return cellFrame(row: rowIndex, column: colIndex)
    }
    
    // MARK: - Private
    
    private func charToIndex(_ char: Character) -> Int? {
        guard let ascii = char.asciiValue else { return nil }
        let index = Int(ascii) - 65  // A = 0, B = 1, etc.
        guard index >= 0 && index < 26 else { return nil }
        return index
    }
}

// MARK: - Debug Helpers

extension GridCalculator {
    /// Print grid info for debugging
    func debugInfo() {
        print("""
        [GridCalculator] 
          Screen: \(screenBounds)
          Grid: \(columns)x\(rows) = \(columns * rows) cells
          Cell size: \(String(format: "%.1f", cellWidth))x\(String(format: "%.1f", cellHeight)) pixels
        """)
    }
    
    /// Create a sub-grid calculator for refinement within a specific cell
    /// - Parameter cellBounds: The bounds of the cell to subdivide
    /// - Returns: A new GridCalculator that works within the cell bounds
    static func subGrid(for cellBounds: CGRect) -> GridCalculator {
        return GridCalculator(screenBounds: cellBounds)
    }
}

// MARK: - Single Letter Grid (for refinement)

/// A simpler 26-position grid for quick refinement with single letter input
/// Uses a 6x5 layout (26 letters: 5 rows of 5, plus 1 extra in last row)
struct SingleLetterGrid {
    let bounds: CGRect
    
    /// Grid layout: 6 columns x 5 rows = 30 cells, but we only use A-Z (26)
    private let columns: Int = 6
    private let rows: Int = 5
    
    var cellWidth: CGFloat {
        bounds.width / CGFloat(columns)
    }
    
    var cellHeight: CGFloat {
        bounds.height / CGFloat(rows)
    }
    
    /// Get position for a single letter (A-Z)
    func positionFor(letter: Character) -> CGPoint? {
        guard let ascii = letter.uppercased().first?.asciiValue else { return nil }
        let index = Int(ascii) - 65  // A = 0, B = 1, etc.
        guard index >= 0 && index < 26 else { return nil }
        
        let row = index / columns
        let col = index % columns
        
        let x = bounds.minX + (CGFloat(col) + 0.5) * cellWidth
        let y = bounds.minY + (CGFloat(row) + 0.5) * cellHeight
        
        return CGPoint(x: x, y: y)
    }
    
    /// Get all letters with their positions
    func allPositions() -> [(letter: Character, position: CGPoint)] {
        var result: [(Character, CGPoint)] = []
        for i in 0..<26 {
            let letter = Character(UnicodeScalar(65 + i)!)
            if let pos = positionFor(letter: letter) {
                result.append((letter, pos))
            }
        }
        return result
    }
    
    /// Get frame for a letter
    func frameFor(letter: Character) -> CGRect? {
        guard let ascii = letter.uppercased().first?.asciiValue else { return nil }
        let index = Int(ascii) - 65
        guard index >= 0 && index < 26 else { return nil }
        
        let row = index / columns
        let col = index % columns
        
        let x = bounds.minX + CGFloat(col) * cellWidth
        let y = bounds.minY + CGFloat(row) * cellHeight
        
        return CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
    }
}
