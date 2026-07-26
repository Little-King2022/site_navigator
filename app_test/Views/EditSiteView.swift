//
//  EditSiteView.swift
//  app_test
//

import SwiftUI
import SwiftData
import PhotosUI

/// Edits a `Site` that already exists. Works on a local draft (plain
/// `@State` mirrors of the model's fields) and only writes back to `site`
/// when the user taps Save, so Cancel is a true no-op.
struct EditSiteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let site: Site

    @State private var name: String
    @State private var openMode: OpenMode
    @State private var isFavorite: Bool
    @State private var iconData: Data?
    @State private var isNameCustomized: Bool
    @State private var isIconCustomized: Bool

    @State private var isFetching = false
    @State private var fetchTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var isPresentingDeleteConfirm = false
    @State private var photoPickerItem: PhotosPickerItem?

    init(site: Site) {
        self.site = site
        _name = State(initialValue: site.name)
        _openMode = State(initialValue: site.openMode)
        _isFavorite = State(initialValue: site.isFavorite)
        _iconData = State(initialValue: site.iconData)
        _isNameCustomized = State(initialValue: site.isNameCustomized)
        _isIconCustomized = State(initialValue: site.isIconCustomized)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("站点信息") {
                    HStack(spacing: 12) {
                        SiteIconView(iconData: iconData, name: name, size: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("名称", text: $name)
                                .onChange(of: name) {
                                    isNameCustomized = true
                                }
                            Text(site.host)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    PhotosPicker("从相册选择图标", selection: $photoPickerItem, matching: .images)

                    Button("重新获取名称和图标", action: refetch)
                        .disabled(isFetching)

                    if isFetching {
                        HStack {
                            ProgressView()
                            Text("正在获取…")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("打开方式") {
                    Picker("打开方式", selection: $openMode) {
                        ForEach(OpenMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("加入收藏", isOn: $isFavorite)
                }

                Section {
                    Button("删除站点", role: .destructive) {
                        isPresentingDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("编辑站点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog(
                "确定要删除这个站点吗？",
                isPresented: $isPresentingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("删除", role: .destructive, action: deleteAndDismiss)
                Button("取消", role: .cancel) {}
            }
            .onChange(of: photoPickerItem) {
                loadPickedPhoto()
            }
        }
        .onDisappear { fetchTask?.cancel() }
    }

    /// Re-runs the same title/favicon scraper used when adding a site.
    /// Respects manual customization: a field the user already edited by
    /// hand is left untouched instead of being silently overwritten.
    private func refetch() {
        guard let url = WebsiteMetadataFetcher.normalizeURL(site.urlString) else {
            errorMessage = "无效的网址"
            return
        }
        errorMessage = nil
        isFetching = true
        fetchTask?.cancel()
        fetchTask = Task {
            let metadata = await WebsiteMetadataFetcher.fetchMetadata(for: url)
            guard !Task.isCancelled else { return }
            if !isNameCustomized, let title = metadata.title, !title.isEmpty {
                name = title
            }
            if !isIconCustomized, let data = metadata.iconData {
                iconData = data
            }
            isFetching = false
        }
    }

    private func loadPickedPhoto() {
        guard let item = photoPickerItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let processed = ImageProcessing.resizedAndCompressed(data) {
                iconData = processed
                isIconCustomized = true
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        site.name = trimmedName.isEmpty ? site.name : trimmedName
        site.openMode = openMode
        site.isFavorite = isFavorite
        site.iconData = iconData
        site.isNameCustomized = isNameCustomized
        site.isIconCustomized = isIconCustomized
        dismiss()
    }

    private func deleteAndDismiss() {
        modelContext.delete(site)
        dismiss()
    }
}
