import SwiftUI

/// The desktop's Reset All: the shared choices, plus Space page motion and the
/// Dock icon.
struct BrowserPlatformLookAndFeelResetSection: View {
    @AppStorage(SpacePageMotionPreference.key)
    private var animatesSpacePages = SpacePageMotionPreference.defaultValue

    var body: some View {
        BrowserLookAndFeelResetFooter {
            animatesSpacePages = SpacePageMotionPreference.defaultValue
            _ = BrowserMacDockTile.shared.select("")
        }
    }
}
