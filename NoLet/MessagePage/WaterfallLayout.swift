//
//  WaterfallLayout.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//

//  Description:
//    瀑布流布局引擎 — 新卡片始终放到当前最短列下方

//  History:
//    Created by Neo on 2026/7/24.

import SwiftUI

// MARK: - ScrollOffset PreferenceKey

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - WaterfallLayout
struct WaterfallLayout: Layout {
    /// 列数
    let columns: Int
    /// 水平间距
    let horizontalSpacing: CGFloat
    /// 垂直间距
    let verticalSpacing: CGFloat

    // MARK: - Cache

    struct Cache {
        var columnHeights: [CGFloat]
        var columnAssignments: [Int]
        var childSizes: [CGSize]
        var lastProposedWidth: CGFloat
        var lastColumnCount: Int
        var lastChildCount: Int
    }

    func makeCache(subviews: Subviews) -> Cache {
        let colCount = max(1, columns)
        return Cache(
            columnHeights: Array(repeating: 0, count: colCount),
            columnAssignments: [],
            childSizes: [],
            lastProposedWidth: 0,
            lastColumnCount: colCount,
            lastChildCount: 0
        )
    }

    // MARK: - 最短列算法

    /// 返回高度最小的列的索引
    private func shortestColumnIndex(heights: [CGFloat]) -> Int {
        var minHeight = CGFloat.greatestFiniteMagnitude
        var minIndex = 0
        for (i, h) in heights.enumerated() {
            if h < minHeight {
                minHeight = h
                minIndex = i
            }
        }
        return minIndex
    }

    // MARK: - Layout Protocol

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let colCount = max(1, columns)
        guard let containerWidth = proposal.width, containerWidth > 0, !subviews.isEmpty else {
            return .zero
        }

        let needsRecalc =
            cache.lastColumnCount != colCount
            || abs(cache.lastProposedWidth - containerWidth) > 1
            || cache.lastChildCount != subviews.count

        guard needsRecalc else {
            let maxHeight = cache.columnHeights.max() ?? 0
            return CGSize(
                width: containerWidth,
                height: max(maxHeight - verticalSpacing, 0)
            )
        }

        let columnWidth =
            (containerWidth - horizontalSpacing * CGFloat(colCount - 1)) / CGFloat(colCount)

        cache.columnHeights = Array(repeating: 0, count: colCount)
        cache.childSizes = Array(repeating: .zero, count: subviews.count)
        cache.columnAssignments = Array(repeating: 0, count: subviews.count)
        cache.lastProposedWidth = containerWidth
        cache.lastColumnCount = colCount
        cache.lastChildCount = subviews.count

        let colProposal = ProposedViewSize(width: columnWidth, height: nil)

        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(colProposal)
            let col = shortestColumnIndex(heights: cache.columnHeights)
            cache.columnAssignments[i] = col
            cache.childSizes[i] = size
            cache.columnHeights[col] += size.height + verticalSpacing
        }

        let maxHeight = cache.columnHeights.max() ?? 0
        return CGSize(
            width: containerWidth,
            height: max(maxHeight - verticalSpacing, 0)
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let colCount = max(1, columns)
        let columnWidth =
            (bounds.width - horizontalSpacing * CGFloat(colCount - 1)) / CGFloat(colCount)

        let xOffsets = (0..<colCount).map { idx in
            bounds.minX + (columnWidth + horizontalSpacing) * CGFloat(idx)
        }
        var columnYOffsets = Array(repeating: bounds.minY, count: colCount)

        for (i, subview) in subviews.enumerated() {
            guard i < cache.columnAssignments.count,
                  i < cache.childSizes.count
            else { continue }

            let col = cache.columnAssignments[i]
            let size = cache.childSizes[i]
            guard col < columnYOffsets.count, col < xOffsets.count else { continue }

            let point = CGPoint(x: xOffsets[col], y: columnYOffsets[col])
            subview.place(
                at: point,
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            columnYOffsets[col] += size.height + verticalSpacing
        }
    }
}
