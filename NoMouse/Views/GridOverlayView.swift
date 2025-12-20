import SwiftUI

/// SwiftUI view that renders the grid overlay
struct GridOverlayView: View {
    let gridCalculator: GridCalculator
    let highlightedRow: Int?
    let refinementBounds: CGRect?  // If set, show sub-grid only in this area
    
    // Grid appearance
    private let gridLineColor = Color.white.opacity(0.15)
    private let labelColor = Color.white.opacity(0.7)
    private let highlightColor = Color.cyan.opacity(0.3)
    private let refinementBgColor = Color.black.opacity(0.7)
    private let refinementBorderColor = Color.cyan.opacity(0.8)
    private let labelFont = Font.system(size: 10, weight: .medium, design: .monospaced)
    private let refinementLabelFont = Font.system(size: 8, weight: .bold, design: .monospaced)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let refinement = refinementBounds {
                    // Refinement mode - dim background, show sub-grid in cell
                    refinementModeView(refinement: refinement, size: geometry.size)
                } else {
                    // Full grid mode
                    fullGridView(size: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Full Grid Mode
    
    @ViewBuilder
    private func fullGridView(size: CGSize) -> some View {
        // Semi-transparent background
        Color.black.opacity(0.3)
        
        // Grid lines and labels
        Canvas { context, size in
            drawGrid(context: context, size: size, calculator: gridCalculator, fontSize: 10)
        }
        
        // Highlighted row overlay
        if let row = highlightedRow {
            highlightedRowOverlay(row: row)
        }
    }
    
    // MARK: - Refinement Mode
    
    @ViewBuilder
    private func refinementModeView(refinement: CGRect, size: CGSize) -> some View {
        // Dark background with cutout for refinement area
        Color.black.opacity(0.6)
        
        // Highlight the refinement cell
        Rectangle()
            .fill(Color.black.opacity(0.2))
            .frame(width: refinement.width, height: refinement.height)
            .border(refinementBorderColor, width: 2)
            .position(x: refinement.midX, y: refinement.midY)
        
        // Sub-grid inside the cell
        Canvas { context, _ in
            drawSubGrid(context: context, bounds: refinement)
        }
        
        // Instructions
        VStack {
            Spacer()
            HStack {
                Text("🎯 Refinement Mode")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                Text("• Type 2 letters for precision")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                Text("• ESC to exit")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8))
            .cornerRadius(8)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Drawing
    
    private func drawGrid(context: GraphicsContext, size: CGSize, calculator: GridCalculator, fontSize: CGFloat) {
        let cellWidth = size.width / CGFloat(calculator.columns)
        let cellHeight = size.height / CGFloat(calculator.rows)
        
        // Draw vertical lines
        for col in 0...calculator.columns {
            let x = CGFloat(col) * cellWidth
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(gridLineColor), lineWidth: 0.5)
        }
        
        // Draw horizontal lines
        for row in 0...calculator.rows {
            let y = CGFloat(row) * cellHeight
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(gridLineColor), lineWidth: 0.5)
        }
        
        // Draw labels
        for row in 0..<calculator.rows {
            for col in 0..<calculator.columns {
                let label = calculator.labelFor(row: row, column: col)
                let x = (CGFloat(col) + 0.5) * cellWidth
                let y = (CGFloat(row) + 0.5) * cellHeight
                
                // Create attributed string
                let text = Text(label)
                    .font(.system(size: fontSize, weight: .medium, design: .monospaced))
                    .foregroundColor(labelColor)
                
                // Resolve and draw text
                let resolved = context.resolve(text)
                let textSize = resolved.measure(in: CGSize(width: cellWidth, height: cellHeight))
                let textOrigin = CGPoint(
                    x: x - textSize.width / 2,
                    y: y - textSize.height / 2
                )
                context.draw(resolved, at: textOrigin, anchor: .topLeading)
            }
        }
    }
    
    private func drawSubGrid(context: GraphicsContext, bounds: CGRect) {
        let grid = SingleLetterGrid(bounds: bounds)
        
        // Draw grid lines
        for col in 0...6 {
            let x = bounds.minX + CGFloat(col) * grid.cellWidth
            var path = Path()
            path.move(to: CGPoint(x: x, y: bounds.minY))
            path.addLine(to: CGPoint(x: x, y: bounds.maxY))
            context.stroke(path, with: .color(Color.cyan.opacity(0.5)), lineWidth: 1)
        }
        
        for row in 0...5 {
            let y = bounds.minY + CGFloat(row) * grid.cellHeight
            var path = Path()
            path.move(to: CGPoint(x: bounds.minX, y: y))
            path.addLine(to: CGPoint(x: bounds.maxX, y: y))
            context.stroke(path, with: .color(Color.cyan.opacity(0.5)), lineWidth: 1)
        }
        
        // Draw all 26 letter labels
        for (letter, pos) in grid.allPositions() {
            let text = Text(String(letter))
                .font(.system(size: min(grid.cellWidth, grid.cellHeight) * 0.5, weight: .bold, design: .monospaced))
                .foregroundColor(Color.cyan)
            
            let resolved = context.resolve(text)
            let textSize = resolved.measure(in: CGSize(width: grid.cellWidth, height: grid.cellHeight))
            let textOrigin = CGPoint(
                x: pos.x - textSize.width / 2,
                y: pos.y - textSize.height / 2
            )
            context.draw(resolved, at: textOrigin, anchor: .topLeading)
        }
    }
    
    @ViewBuilder
    private func highlightedRowOverlay(row: Int) -> some View {
        let cellHeight = gridCalculator.cellHeight
        let yPosition = CGFloat(row) * cellHeight
        
        Rectangle()
            .fill(highlightColor)
            .frame(height: cellHeight)
            .position(x: gridCalculator.screenBounds.width / 2, 
                      y: yPosition + cellHeight / 2)
    }
}
