//
//  ContentView.swift
//  CodingChallengeB
//
//  Created by Diogo Nunes on 17/06/2026.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationViewWrapper {
            EmojisGridView(viewModel: EmojisViewModel(repository: EmojiRepository(remoteSource: EmojisAPI(session: URLSession.shared), localSource: modelContext)))
            #if os(macOS)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            #endif
                .toolbar {
                    #if os(iOS)
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                    #endif
                }
        }
    }
}

private struct NavigationViewWrapper<Content: View>: View {
    let content: () -> Content

    var body: some View {
        #if os(macOS)
            NavigationSplitView {
                content()
            } detail: {
                Text("Select an item")
            }
        #else
            content()
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [EmojiEntity.self], inMemory: true)
}
