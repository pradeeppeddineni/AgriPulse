import SwiftUI

struct CategoryBadge: View {
    let category: EventCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.systemImage)
                .font(.system(size: 10))
            Text(category.label)
                .font(.system(size: 10, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.15))
        .foregroundStyle(category.color)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(category.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CommodityPill: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AgriPulseTheme.border.opacity(0.4), lineWidth: 1)
            )
    }
}
