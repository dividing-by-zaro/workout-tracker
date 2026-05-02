import SwiftUI

struct SetSummariesFlow: Layout {
    var horizontalSpacing: CGFloat = 10
    var verticalSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * verticalSpacing
        let naturalWidth = rows.map(\.width).max() ?? 0
        // Fill the proposed width so every row gets the same space-around budget.
        let width = proposal.width ?? naturalWidth
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            // Space-around: equal space around each item, half-gap at each edge.
            let contentWidth = row.items.reduce(0) { $0 + $1.size.width }
            let leftover = max(0, bounds.width - contentWidth)
            let count = max(1, row.items.count)
            let segment = leftover / CGFloat(count * 2)
            var x = bounds.minX + segment
            for item in row.items {
                let proposed = ProposedViewSize(item.size)
                let position = CGPoint(x: x, y: y + (row.baseline - item.baseline))
                subviews[item.index].place(at: position, anchor: .topLeading, proposal: proposed)
                x += item.size.width + 2 * segment
            }
            y += row.height + verticalSpacing
        }
    }

    private struct Item {
        let index: Int
        let size: CGSize
        let baseline: CGFloat
    }

    private struct Row {
        var items: [Item] = []
        var width: CGFloat = 0
        var baseline: CGFloat = 0   // max distance from top of row to text baseline
        var descent: CGFloat = 0    // max distance from baseline to bottom
        var height: CGFloat { baseline + descent }
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let dims = subviews[index].dimensions(in: ProposedViewSize(size))
            let baseline = dims[.firstTextBaseline]
            let descent = size.height - baseline

            let needsSpacing = !rows[rows.count - 1].items.isEmpty
            let projectedWidth = rows[rows.count - 1].width + (needsSpacing ? horizontalSpacing : 0) + size.width
            if projectedWidth > maxWidth, !rows[rows.count - 1].items.isEmpty {
                rows.append(Row())
            }
            var current = rows[rows.count - 1]
            if !current.items.isEmpty { current.width += horizontalSpacing }
            current.items.append(Item(index: index, size: size, baseline: baseline))
            current.width += size.width
            current.baseline = max(current.baseline, baseline)
            current.descent = max(current.descent, descent)
            rows[rows.count - 1] = current
        }
        return rows
    }
}
