import SwiftUI

/// The shared Window group, plus the window choice only the desktop has.
struct BrowserPlatformAppearanceSettingsSection: View {
    var space: BrowserSpaceAppearance?
    var showsPreview = false

    @AppStorage(SpacePageMotionPreference.key)
    private var animatesSpacePages = SpacePageMotionPreference.defaultValue

    var body: some View {
        let motion = CrestSettingValue($animatesSpacePages, default: SpacePageMotionPreference.defaultValue)

        return BrowserWindowAppearanceGroup(
            space: space,
            showsPreview: showsPreview,
            extraSettings: [
                motion.resettable("Animate pages when switching Spaces")
            ]
        ) {
            CrestSettingRow(
                "Animate pages when switching Spaces",
                setting: motion.resettable("Animate pages when switching Spaces")
            ) {
                Toggle("Animate pages when switching Spaces", isOn: motion.binding)
                    .labelsHidden()
                    .accessibilityIdentifier("animate-space-pages")
            }
        }
    }
}
