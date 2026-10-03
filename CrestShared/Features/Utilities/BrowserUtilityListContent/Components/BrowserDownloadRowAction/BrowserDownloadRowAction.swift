import Foundation
import SwiftUI

struct BrowserDownloadRowAction: View {
    let item: DownloadState
    let destinations: [BrowserUtilityDownloadDestination]
    let perform: (BrowserUtilityDownloadAction) -> Void

    /// Engine capabilities offer pause or recovery beside the phase's action.
    var body: some View {
        if item.canPause {
            actionButton(.pause) { perform(.pause(item.id)) }
        } else if item.canResume {
            actionButton(.resume) { perform(.resume(item.id)) }
        }
        let action = item.phase.primaryAction
        switch action.kind {
        case .retry:
            actionButton(action) { perform(.retry(item.id)) }
        case .cancel:
            actionButton(action) { perform(.cancel(item.id)) }
        case .open:
            BrowserDownloadFinishedAction(
                itemID: item.id,
                action: action,
                destinations: destinations,
                perform: perform
            )
        case .remove:
            actionButton(action) { perform(.clear(item.id)) }
        case .pause:
            actionButton(action) { perform(.pause(item.id)) }
        case .resume:
            actionButton(action) { perform(.resume(item.id)) }
        }
    }

    private func actionButton(
        _ action: DownloadRowAction,
        perform: @escaping () -> Void
    ) -> some View {
        Button(
            action.title,
            systemImage: action.symbol,
            role: action.isDestructive ? .destructive : nil,
            action: perform
        )
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .frame(
            width: BrowserUtilitySwitcherLayout.buttonSize,
            height: BrowserUtilitySwitcherLayout.buttonSize
        )
    }
}

#if DEBUG
    #Preview("Download actions") {
        VStack {
            BrowserDownloadRowAction(
                item: BrowserUtilityListPreviewFixture.activeDownload, destinations: [], perform: { _ in })
            BrowserDownloadRowAction(
                item: BrowserUtilityListPreviewFixture.failedDownload, destinations: [], perform: { _ in })
            BrowserDownloadRowAction(
                item: BrowserUtilityListPreviewFixture.finishedDownload, destinations: [], perform: { _ in })
        }.padding()
    }
#endif
