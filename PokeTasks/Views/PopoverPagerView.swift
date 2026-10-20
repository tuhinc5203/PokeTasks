import SwiftUI

struct PopoverPagerView: View {
    @ObservedObject var taskListViewModel: TaskListViewModel
    @ObservedObject var petCollectionViewModel: PetCollectionViewModel

    @State private var scrollPosition: Int?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                PetPopoverView(viewModel: taskListViewModel, petCollectionViewModel: petCollectionViewModel)
                    .frame(width: 260)
                    .id(0)
                CollectionPanelView(taskListViewModel: taskListViewModel, petCollectionViewModel: petCollectionViewModel)
                    .frame(width: 260)
                    .id(1)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrollPosition)
        .frame(width: 260, height: 420)
        .onChange(of: petCollectionViewModel.activationTick) { _, _ in
            // Keyed off a dedicated tick rather than activeLineID directly, since tapping a
            // card that's already active (e.g. re-tapping the current pet's own egg) doesn't
            // change activeLineID at all -- but should still slide back to the main screen.
            withAnimation {
                scrollPosition = 0
            }
        }
    }
}
