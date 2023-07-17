import SwiftUI

// ContentView 结构体，作为应用界面的主体内容
struct ContentView: View {
    
    // 用于 TabView 的变量
    @State private var selectedTab = 0 // 用来追踪哪个标签被选中
    @State private var tabs = [TabData(id: 0, title: "Tab 1", currentDirectory: FileManager.default.homeDirectoryForCurrentUser.path)] // 存储标签数据的数组
    @State private var newTitle = "" // 在重命名标签时，存储新标题的变量
    @State private var isRenaming = false // 用来判断是否正在重命名标签的布尔值
    
    // 用于管理课程表的变量
    @State private var isEditingCourses = false // 用来判断是否正在编辑课程的布尔值
    @State private var courseNames: [[String]] // 存储每个时间间隔和每个工作日的课程名称的二维数组

    // 初始化函数
    init() {
        if let data = UserDefaults.standard.data(forKey: "courseNames"),
           let loadedCourseNames = try? JSONDecoder().decode([[String]].self, from: data) {
            _courseNames = State(initialValue: loadedCourseNames) // 如果能够成功解码存储的课程名，则使用解码后的课程名
        } else {
            _courseNames = State(initialValue: Array(repeating: Array(repeating: "待定", count: 7), count: 6)) // 否则，创建一个新的课程名列表，初始值为“待定”
        }
    }
    
    // 描述一个时间间隔的结构体，包含一个标识符和一个时间字符串
    struct IntervalState: Identifiable, Codable {
        let id: Int
        var time: String
    }

    // 用于管理时间间隔的变量
    @State private var intervals: [IntervalState] = UserDefaults.standard.object(forKey: "intervals") as? [IntervalState] ?? (0..<6).map { IntervalState(id: $0, time: "10:00-11:00") }
    
    // 总时间间隔数输入的变量
    @State private var totalIntervalsInput: String = UserDefaults.standard.string(forKey: "totalIntervals") ?? "6"
    // 选择工作日的变量
    @State private var weekdays = UserDefaults.standard.array(forKey: "weekdays") as? [Bool] ?? Array(repeating: true, count: 7)
    // 课程表标题的变量
    @State private var title: String = UserDefaults.standard.string(forKey: "title") ?? ""
    // 是否显示设置的变量
    @State private var showSettings = true

    // body 属性，用来描述界面的具体内容
    var body: some View {
        VStack {
            // 一个 TabView，里面的标签可以由用户自定义
            TabView(selection: $selectedTab) {
                ForEach(tabs.indices, id: \.self) { index in
                    FileBrowserView(tabData: $tabs[index])
                        .tabItem {
                            Text(tabs[index].title)
                        }
                        .tag(index)
                }
            }

            // 一系列按钮，用于管理标签
            HStack {
                Button("添加标签页") {
                    let newTab = TabData(id: tabs.count, title: "Tab \(tabs.count + 1)", currentDirectory: FileManager.default.homeDirectoryForCurrentUser.path)
                    tabs.append(newTab)
                    saveTabs()
                }

                Button("删除当前标签页") {
                    if tabs.count > 1 {
                        UserDefaults.standard.set(tabs[selectedTab].currentDirectory, forKey: "tab\(tabs[selectedTab].id)")
                        tabs.remove(at: selectedTab)
                        if selectedTab >= tabs.count {
                            selectedTab = tabs.count - 1
                        }
                    }
                    saveTabs()
                }

                Button("重命名当前标签页") {
                    newTitle = tabs[selectedTab].title
                    isRenaming = true
                }

                if isRenaming {
                    TextField("新的标题", text: $newTitle, onCommit: {
                        tabs[selectedTab].title = newTitle
                        newTitle = ""
                        isRenaming = false
                    })
                }
            }

            Divider()

            if showSettings {
                // HStack 用于在水平方向上堆叠视图
                HStack {
                    // 创建一个按钮，按钮的文本取决于课程是否正在编辑，如果是，按钮文本为“保存课程”，否则为“修改课程”
                    Button(isEditingCourses ? "保存课程" : "修改课程") {
                        // 点击按钮时，将 isEditingCourses 翻转，如果在编辑模式，点击后进入非编辑模式，并保存课程名
                        self.isEditingCourses.toggle()
                        if !isEditingCourses {
                            saveCourseNames()
                        }
                    }

                    // 文本显示“时间间隔总数”
                    Text("时间间隔总数：")
                    // 创建一个文本框，用于接收用户输入的时间间隔总数
                    TextField("请输入总数", text: $totalIntervalsInput, onCommit: {
                        // 当用户输入完成按下回车后，更新时间间隔
                        updateIntervals()
                    })
                        .frame(width: 100)  // 设置 TextField 的宽度为 100

                    // 文本显示“选择工作日”
                    Text("选择工作日：")
                    // 创建一个水平堆叠视图，包含七个开关，分别表示一周内的七天
                    HStack {
                        ForEach(0..<7, id: \.self) { index in
                            // 创建一个开关，用于选择工作日
                            Toggle(isOn: Binding(
                                get: { self.weekdays[index] },
                                set: { newValue in
                                    self.weekdays[index] = newValue
                                    self.saveWeekdays()
                                }
                            )) {
                                // 开关的标题为“周x”
                                Text("周\(index + 1)")
                            }
                        }
                    }

                    // 文本显示“标题”
                    Text("标题：")
                    // 创建一个文本框，用于接收用户输入的标题
                    TextField("请输入标题", text: $title, onCommit: {
                        // 当用户输入完成按下回车后，保存标题
                        saveTitle()
                    })
                        .frame(width: 200)  // 设置 TextField 的宽度为 200
                }
            }

            // 动态课程表
            VStack {
                // 课程表的标题
                Text(title)
                    .font(.title)
                HStack {
                    // 显示“时间”字样
                    Text("时间")
                        .frame(width: 100)
                        .padding()
                        .border(Color.gray)
                        .background(Color.gray.opacity(0.5))
                    // 对于每个工作日，显示“周x”
                    ForEach(weekdays.indices.filter { weekdays[$0] }, id: \.self) { index in
                        Text("周\(index + 1)")
                            .frame(width: 100, alignment: .center)  // 固定宽度
                            .padding()
                            .border(Color.black, width: 0.5)
                            .background(Color.gray.opacity(0.5))
                    }
                }
                // 对于每个时间间隔，创建一个水平堆叠视图
                ForEach(intervals) { interval in
                    HStack {
                        // 创建一个文本框，用于显示和修改时间间隔
                        TextField("时间间隔", text: Binding<String>(
                            get: { interval.time },
                            set: { newValue in
                                if let index = intervals.firstIndex(where: { $0.id == interval.id }) {
                                    intervals[index].time = newValue
                                }
                            }
                        ))
                        .frame(width: 100)
                        .border(Color.gray)
                        .padding()
                        // 对于每个工作日，创建一个文本框或文本视图，用于显示和修改课程名称
                        ForEach(weekdays.indices.filter { weekdays[$0] }, id: \.self) { index in
                            if isEditingCourses {
                                // 确保我们不访问超出范围的索引
                                if interval.id < courseNames.count {
                                    TextField("课程名称", text: $courseNames[interval.id][index])
                                        .frame(width: 100, alignment: .center)  // 固定宽度
                                        .padding()
                                        .border(Color.black, width: 0.5)
                                        .background(Color.gray.opacity(0.2))
                                }
                            } else {
                                // 确保我们不访问超出范围的索引
                                if interval.id < courseNames.count {
                                    Text(courseNames[interval.id][index])
                                        .frame(width: 100, alignment: .center)  // 固定宽度
                                        .padding()
                                        .border(Color.black, width: 0.5)
                                        .background(Color.gray.opacity(0.2))
                                }
                            }
                        }
                    }
                }
            }

            // 创建一个按钮，点击后显示或隐藏设置
            Button(action: {
                self.showSettings.toggle()
            }) {
                Text(showSettings ? "隐藏设置" : "显示设置")
            }
        }
        // 当视图显示时，加载数据；当视图消失时，保存数据
        .onAppear {
            loadTabs()  // 加载 tab 数据
            loadIntervals()  // 加载时间间隔数据
            loadTitle()  // 加载标题数据
            loadWeekdays()  // 加载工作日数据
            loadCourseNames()  // 加载课程名称数据
            // 如果时间间隔的数量和课程名称的数量不一致，则调整课程名称
            // 这段代码已经被注释掉，可以根据需要恢复或忽略
            //if intervals.count != courseNames.count {
            //    adjustCourseNames()
            //}
        }
        .onDisappear {
            saveTabs()  // 保存 tab 数据
            saveIntervals()  // 保存时间间隔数据
            saveTitle()  // 保存标题数据
            saveWeekdays()  // 保存工作日数据
        }
    }

    // 从 UserDefaults 加载标题数据
    func loadTitle() {
        title = UserDefaults.standard.string(forKey: "title") ?? ""
    }

    // 将标题数据保存到 UserDefaults
    func saveTitle() {
        UserDefaults.standard.set(title, forKey: "title")
    }

    // 如果课程名称的数量和时间间隔的数量不一致，调整课程名称的数量
    func adjustCourseNames() {
        // 如果课程名称的数量小于时间间隔的数量，添加缺少的课程名称
        if courseNames.count < intervals.count {
            let diff = intervals.count - courseNames.count
            courseNames.append(contentsOf: Array(repeating: Array(repeating: "待定", count: 7), count: diff))
        // 如果课程名称的数量大于时间间隔的数量，删除多余的课程名称
        } else if courseNames.count > intervals.count {
            courseNames = Array(courseNames.prefix(intervals.count))
        }
    }

    // 更新时间间隔
    func updateIntervals() {
        if let newValue = Int(totalIntervalsInput) {
            // 如果用户输入的时间间隔数量大于当前的时间间隔数量，添加缺少的时间间隔和课程名称
            if newValue > intervals.count {
                intervals.append(contentsOf: (intervals.count..<newValue).map { IntervalState(id: $0, time: "10:00-11:00") })
                courseNames.append(contentsOf: (courseNames.count..<newValue).map { _ in Array(repeating: "待定", count: 7) })
            // 如果用户输入的时间间隔数量小于当前的时间间隔数量，删除多余的时间间隔和课程名称
            } else if newValue < intervals.count {
                intervals = Array(intervals.prefix(newValue))
                courseNames = Array(courseNames.prefix(newValue))
            }
            // 将用户输入的时间间隔数量保存到 UserDefaults
            UserDefaults.standard.set(totalIntervalsInput, forKey: "totalIntervals")
            saveCourseNames()  // 保存课程名称
        }
    }

    // 从 UserDefaults 加载 tab 数据
    func loadTabs() {
        if let savedTabsData = UserDefaults.standard.data(forKey: "tabs") {
            let decoder = JSONDecoder()
            if let loadedTabs = try? decoder.decode([TabData].self, from: savedTabsData) {
                self.tabs = loadedTabs
            }
        }
    }

    // 将 tab 数据保存到 UserDefaults
    func saveTabs() {
        let encoder = JSONEncoder()
        if let encodedTabs = try? encoder.encode(tabs) {
            UserDefaults.standard.set(encodedTabs, forKey: "tabs")
        }
    }

    // 从 UserDefaults 加载时间间隔数据
    func loadIntervals() {
        if let savedIntervalsData = UserDefaults.standard.data(forKey: "intervals") {
            let decoder = JSONDecoder()
            if let loadedIntervals = try? decoder.decode([IntervalState].self, from: savedIntervalsData) {
                self.intervals = loadedIntervals
            }
        }
    }

    // 将时间间隔数据保存到 UserDefaults
    func saveIntervals() {
        let encoder = JSONEncoder()
        if let encodedIntervals = try? encoder.encode(intervals) {
            UserDefaults.standard.set(encodedIntervals, forKey: "intervals")
        }
    }

    // 将课程名称保存到 UserDefaults
    func saveCourseNames() {
        if let data = try? JSONEncoder().encode(courseNames) {
            UserDefaults.standard.set(data, forKey: "courseNames")
        }
    }

    // 从 UserDefaults 加载课程名称
    func loadCourseNames() {
        if let data = UserDefaults.standard.data(forKey: "courseNames"),
           let loadedCourseNames = try? JSONDecoder().decode([[String]].self, from: data) {
            courseNames = loadedCourseNames
        }
    }

    // 从 UserDefaults 加载工作日数据
    func loadWeekdays() {
        weekdays = UserDefaults.standard.array(forKey: "weekdays") as? [Bool] ?? Array(repeating: true, count: 7)
    }

    // 将工作日数据保存到 UserDefaults
    func saveWeekdays() {
        UserDefaults.standard.set(weekdays, forKey: "weekdays")
    }
       }

struct FileBrowserView: View {
    @Binding var tabData: TabData // 当前标签页的数据。

    @State private var searchText = "" // 搜索框内的文字。
    @State private var files: [URL] = [] // 当前目录下的文件和目录列表。
    @State private var currentDirectory: URL // 当前的目录。
    @State private var searchResults: [URL] = [] // 搜索结果列表。
    @State private var previousDirectories: [URL] = [] // 访问过的目录路径的历史记录。
    @State private var inputPath = "" // 输入的路径。
    
    init(tabData: Binding<TabData>) {
        _tabData = tabData
        _currentDirectory = State(initialValue: FileManager.default.homeDirectoryForCurrentUser) // 初始目录设为用户的主目录。
        _previousDirectories = State(initialValue: []) // 现在，我们初始化一个空的数组
    }



    var body: some View {
        VStack {
            // 文件搜索和路径输入区域
            HStack {
                // “返回上一级”按钮
                if !previousDirectories.isEmpty {
                    Button("返回上一级") {
                        if let lastDirectory = previousDirectories.last {
                            currentDirectory = lastDirectory
                            previousDirectories.removeLast()
                            loadFiles() // 加载当前目录下的文件和目录列表。
                        }
                    }
                    .padding()
                }



                // 文件搜索和路径输入框
                TextField("Search or input path", text: $inputPath)
                    .padding()
                    .onChange(of: inputPath, perform: { value in
                        // 如果输入的是绝对路径，则尝试打开对应的目录。
                        // 如果输入的不是绝对路径，则将输入的文字视为搜索关键字。
                        if value.hasPrefix("/") {
                            let url = URL(fileURLWithPath: value)
                            if FileManager.default.fileExists(atPath: url.path) {
                                previousDirectories.append(currentDirectory)
                                currentDirectory = url
                                loadFiles()
                            }
                        } else {
                            searchText = value
                            searchFiles() // 搜索当前目录及其子目录下的文件和目录。
                        }
                    })

                // 如果有搜索结果，显示一个下拉菜单供用户选择。
                if !searchResults.isEmpty {
                    Menu {
                        ForEach(searchResults, id: \.self) { url in
                            Button(action: {
                                previousDirectories.append(currentDirectory)
                                currentDirectory = url.deletingLastPathComponent()
                                loadFiles()
                            }) {
                                Text(url.lastPathComponent)
                            }
                        }
                    } label: {
                        Image(systemName: "arrowtriangle.down.circle")
                            .font(.title)
                    }
                }

                // “选择目录”按钮，点击后打开一个目录选择对话框。
                Button("选择目录") {
                    let openPanel = NSOpenPanel()
                    openPanel.canChooseFiles = false
                    openPanel.canChooseDirectories = true
                    openPanel.allowsMultipleSelection = false
                    if openPanel.runModal() == .OK {
                        if let url = openPanel.url {
                            previousDirectories.removeAll() // 添加这一行来清空数组
                            currentDirectory = url
                            loadFiles()
                        }
                    }
                }
                .padding()



                // “刷新”按钮，点击后刷新当前目录下的文件和目录列表。
                Button("刷新") {
                    loadFiles()
                }
                .padding()
            }
            DirectoryPathView(path: currentDirectory.path)
                    .padding(.bottom, 10)
            // 文件和目录列表区域
            List(files, id: \.self) { url in
                Text(url.lastPathComponent)
                    .foregroundColor(url.hasDirectoryPath ? .blue : .red) // 目录的名字显示为蓝色，文件的名字显示为红色。
                    .onTapGesture(count: 2) { // 双击后，如果是目录则进入，如果是文件则尝试打开。
                        if url.hasDirectoryPath {
                            previousDirectories.append(currentDirectory)
                            currentDirectory = url
                            loadFiles()
                        } else {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .contextMenu { // 右键单击后显示的上下文菜单。
                        Button(action: {
                            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                        }) {
                            Text("Show in Finder")
                        }

                        Button(action: {
                            do {
                                try FileManager.default.removeItem(at: url)
                                loadFiles()
                            } catch {
                                print("Failed to delete file: \(error)")
                            }
                        }) {
                            Text("Delete")
                        }
                    }
            }
            .onDrop(of: [.fileURL], delegate: self)
        }
        .onAppear {
            currentDirectory = URL(fileURLWithPath: tabData.currentDirectory)
            loadFiles() // 视图出现时，加载当前目录下的文件和目录列表。
        }
    }

    // 从当前目录加载文件和目录列表。
    private func loadFiles() {
        do {
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isHiddenKey]
            let urls = try FileManager.default.contentsOfDirectory(at: currentDirectory, includingPropertiesForKeys: resourceKeys)

            files = urls.filter { url in
                do {
                    let resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))
                    return resourceValues.isHidden != true
                } catch {
                    return false
                }
            }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })

            tabData.currentDirectory = currentDirectory.path
            UserDefaults.standard.set(tabData.currentDirectory, forKey: "tab\(tabData.id)")
        } catch {
            print("Failed to load files: \(error)")
        }
    }

    // 搜索当前目录及其子目录下的文件和目录。
    private func searchFiles() {
        if searchText.isEmpty {
            searchResults = []
        } else {
            let enumerator = FileManager.default.enumerator(at: currentDirectory, includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey])

            var results: [URL] = []
            while let url = enumerator?.nextObject() as? URL {
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .isHiddenKey])
                    if resourceValues.isHidden != true && url.lastPathComponent.contains(searchText) {
                        results.append(url)
                    }
                } catch {
                    continue
                }
            }
            searchResults = results
        }
    }
}

extension FileBrowserView: DropDelegate {
    // 验证拖放的内容是否为文件URL，如果是，则返回 true，表示可以接受该拖放。
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.fileURL])
    }

    // 处理拖放的文件。
    func performDrop(info: DropInfo) -> Bool {
        if let itemProvider = info.itemProviders(for: [.fileURL]).first {
            itemProvider.loadItem(forTypeIdentifier: String(kUTTypeFileURL), options: nil) { (item, error) in
                DispatchQueue.main.async {
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        do {
                            // 计算文件复制到当前目录后的新URL。
                            let destination = currentDirectory.appendingPathComponent(url.lastPathComponent)
                            // 将文件复制到当前目录。
                            try FileManager.default.copyItem(at: url, to: destination)
                            // 刷新文件列表。
                            loadFiles()
                        } catch {
                            print("Failed to copy file: \(error)")
                        }
                    }
                }
            }
            return true
        } else {
            return false
        }
    }
}


struct TabData: Identifiable, Codable {
    var id: Int // 标签页的唯一标识符。
    var title: String // 标签页的标题。
    var currentDirectory: String // 当前显示的目录的路径。
}

struct DirectoryPathView: View {
    let path: String

    var body: some View {
        HStack {
            Image(systemName: "folder")
            Text(path)
        }
        .contextMenu {
            Button(action: {
                let pasteboard = NSPasteboard.general
                pasteboard.declareTypes([.string], owner: nil)
                pasteboard.setString(path, forType: .string)
            }) {
                Text("Copy Path")
                Image(systemName: "doc.on.doc")
            }
            Button(action: {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
            }) {
                Text("Show in Finder")
                Image(systemName: "eye")
            }
        }
    }
}
