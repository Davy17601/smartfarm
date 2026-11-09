import SwiftUI

/// One trailing swipe action — an icon/label button revealed by dragging a
/// `SwipeActionsRow` left.
struct SwipeAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}

/// Wraps row `content` so dragging it left reveals 1-2 trailing action
/// buttons (tap one to run it; release without passing the threshold snaps
/// back). SwiftUI's own `.swipeActions()` needs iOS 15, which this app's
/// iOS 14 target can't use, so this reimplements the reveal interaction by
/// hand with a `DragGesture` + offset — used by the Notifications tab's
/// rows for "ធ្វើរួច" / "លុប".
struct SwipeActionsRow<Content: View>: View {
    let actions: [SwipeAction]
    @ViewBuilder let content: () -> Content

    /// The snapped-to offset (0 = closed, `-revealWidth` = open).
    @State private var baseOffset: CGFloat = 0
    @GestureState private var dragTranslation: CGFloat = 0

    private let actionWidth: CGFloat = 76
    private var revealWidth: CGFloat { actionWidth * CGFloat(actions.count) }

    private var liveOffset: CGFloat {
        min(0, max(baseOffset + dragTranslation, -revealWidth))
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                ForEach(actions) { actionButton($0) }
            }

            content()
                .offset(x: liveOffset)
                // `simultaneousGesture` (not `.gesture`) so a mostly-vertical
                // drag still reaches the parent `ScrollView` instead of this
                // row claiming every drag as its own horizontal swipe, and so
                // `content()`'s own tap (open the editor) still works.
                .simultaneousGesture(dragGesture)
                .overlay(closeCatcher.offset(x: liveOffset))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// Invisible full-size tap target shown only while a row is revealed, so
    /// tapping the (now-shifted) row content closes it instead of opening
    /// the editor underneath.
    @ViewBuilder
    private var closeCatcher: some View {
        if baseOffset != 0 {
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) { baseOffset = 0 }
                }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .updating($dragTranslation) { value, state, _ in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                state = value.translation.width
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let projected = baseOffset + value.translation.width
                withAnimation(.easeOut(duration: 0.2)) {
                    baseOffset = projected < -40 ? -revealWidth : 0
                }
            }
    }

    private func actionButton(_ action: SwipeAction) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { baseOffset = 0 }
            action.action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: action.icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(action.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(width: actionWidth)
            .frame(maxHeight: .infinity)
            .background(action.color)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SwipeActionsRow_Previews: PreviewProvider {
    static var previews: some View {
        SwipeActionsRow(actions: [
            SwipeAction(title: "ធ្វើរួច", icon: "checkmark", color: .green) {},
            SwipeAction(title: "លុប", icon: "trash", color: .red) {}
        ]) {
            Text("ស្រោចទឹក")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)
        }
        .frame(height: 76)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
