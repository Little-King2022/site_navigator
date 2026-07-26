//
//  AddSiteView.swift
//  site_navigator
//

import SwiftUI
import SwiftData

/// Sheet: type a URL, auto-fetch its title/favicon, edit the name before
/// saving. The icon itself isn't manually replaceable here — that lives in
/// `EditSiteView` (via a re-fetch button and a `PhotosPicker`) after the site
/// already exists.
struct AddSiteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var urlInput: String
    @State private var name = ""
    @State private var fetchedTitle: String?
    @State private var iconData: Data?
    @State private var openMode: OpenMode = .inApp
    @State private var isFavorite = false
    @State private var isFetching = false
    @State private var hasFetched = false
    @State private var fetchTask: Task<Void, Never>?
    @State private var errorMessage: String?

    /// Pre-fills the URL field (e.g. from a clipboard-detected link) and
    /// triggers an immediate fetch once the sheet appears.
    init(initialURLString: String? = nil) {
        _urlInput = State(initialValue: initialURLString ?? "")
    }

    private var normalizedURL: URL? {
        WebsiteMetadataFetcher.normalizeURL(urlInput)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("网址") {
                    TextField("example.com", text: $urlInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .onSubmit(fetchMetadata)
                        .onChange(of: urlInput) {
                            hasFetched = false
                        }

                    if isFetching {
                        HStack {
                            ProgressView()
                            Text("正在获取网站信息…")
                                .foregroundStyle(.secondary)
                        }
                    } else if normalizedURL != nil, !hasFetched {
                        Button("获取名称和图标", action: fetchMetadata)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if hasFetched {
                    Section("站点信息") {
                        HStack(spacing: 12) {
                            SiteIconView(iconData: iconData, name: name, size: 44)
                            TextField("名称", text: $name)
                        }
                        Button("重新获取", action: fetchMetadata)
                            .disabled(isFetching)
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
                }
            }
            .navigationTitle("添加站点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(normalizedURL == nil || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            if !urlInput.isEmpty, !hasFetched, !isFetching {
                fetchMetadata()
            }
        }
        .onDisappear { fetchTask?.cancel() }
    }

    private func fetchMetadata() {
        guard let url = normalizedURL else {
            errorMessage = "请输入有效的网址"
            return
        }
        errorMessage = nil
        isFetching = true
        fetchTask?.cancel()
        fetchTask = Task {
            let metadata = await WebsiteMetadataFetcher.fetchMetadata(for: url)
            guard !Task.isCancelled else { return }
            fetchedTitle = metadata.title
            if let title = metadata.title, !title.isEmpty {
                name = title
            } else if name.isEmpty {
                name = url.host ?? urlInput
            }
            iconData = metadata.iconData
            hasFetched = true
            isFetching = false
        }
    }

    private func save() {
        guard let url = normalizedURL else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? (url.host ?? url.absoluteString) : trimmedName

        let site = Site(urlString: url.absoluteString, name: finalName, openMode: openMode)
        site.isNameCustomized = finalName != (fetchedTitle ?? "")
        site.iconData = iconData
        site.isFavorite = isFavorite
        modelContext.insert(site)
        dismiss()
    }
}

#Preview {
    AddSiteView()
        .modelContainer(for: Site.self, inMemory: true)
}
