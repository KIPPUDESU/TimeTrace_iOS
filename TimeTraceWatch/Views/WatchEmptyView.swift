import SwiftUI

struct WatchEmptyView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.secondary)
            Text(WL("watch_sync_hint"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WatchEmptyView()
}
