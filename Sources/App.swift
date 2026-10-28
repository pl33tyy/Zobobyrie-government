import SwiftUI
import UIKit

// MARK: - App

@main
struct LumenApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Models

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isMine: Bool
    let time: String
}

struct Chat: Identifiable {
    let id = UUID()
    let name: String
    var last: String
    let time: String
    var unread: Int
    let colors: [Color]
    var messages: [Message]
}

private func msg(_ text: String, _ mine: Bool, _ time: String) -> Message {
    Message(text: text, isMine: mine, time: time)
}

extension Chat {
    static var samples: [Chat] {
        let alisa: [Message] = [
            msg("Привет! Как выходные?", false, "08:30"),
            msg("Огонь, ездили на море 🌊", true, "08:35"),
            msg("Скинула фото с поездки 📸", false, "08:41")
        ]
        let max: [Message] = [
            msg("Ты видел новый релиз?", false, "07:58"),
            msg("Ещё нет, сейчас гляну", true, "08:02"),
            msg("Созвонимся вечером?", false, "08:15")
        ]
        let team: [Message] = [
            msg("Завтра дедлайн по бете 🚀", false, "Вчера"),
            msg("Я почти закончил интерфейс", true, "Вчера"),
            msg("Отлично, ждём сборку", false, "Вчера")
        ]
        let mom: [Message] = [
            msg("Не забудь позвонить бабушке", false, "Вчера"),
            msg("Хорошо, позвоню вечером ❤️", true, "Вчера")
        ]
        let dima: [Message] = [
            msg("Го в субботу на пробежку?", true, "Пн"),
            msg("Го, в 9 у парка", false, "Пн")
        ]
        return [
            Chat(name: "Алиса", last: "Скинула фото с поездки 📸", time: "08:41", unread: 2, colors: [.pink, .orange], messages: alisa),
            Chat(name: "Макс", last: "Созвонимся вечером?", time: "08:15", unread: 1, colors: [.blue, .cyan], messages: max),
            Chat(name: "Команда Lumen", last: "Отлично, ждём сборку", time: "Вчера", unread: 0, colors: [.purple, .indigo], messages: team),
            Chat(name: "Мама", last: "Хорошо, позвоню вечером ❤️", time: "Вчера", unread: 0, colors: [.orange, .red], messages: mom),
            Chat(name: "Дима", last: "Го, в 9 у парка", time: "Пн", unread: 0, colors: [.green, .teal], messages: dima)
        ]
    }
}

// MARK: - Store

final class Store: ObservableObject {
    @Published var chats: [Chat] = Chat.samples

    static func now() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }

    func markRead(_ id: UUID) {
        guard let i = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[i].unread = 0
    }

    func send(_ text: String, to id: UUID) {
        guard let i = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[i].messages.append(Message(text: text, isMine: true, time: Store.now()))
        chats[i].last = text

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in
            guard let self = self,
                  let j = self.chats.firstIndex(where: { $0.id == id }) else { return }
            let replies = ["Звучит отлично 🔥", "Окей, договорились", "Ха-ха, это сильно 😄", "Давай позже обсудим", "Согласен!"]
            let reply = replies.randomElement() ?? "Окей"
            self.chats[j].messages.append(Message(text: reply, isMine: false, time: Store.now()))
            self.chats[j].last = reply
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}

// MARK: - Glass helpers

extension View {
    /// Liquid Glass on iOS 26 (when built with Xcode 26), frosted material otherwise.
    @ViewBuilder
    func glass<S: Shape>(_ shape: S) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.frostedGlass(shape)
        }
        #else
        self.frostedGlass(shape)
        #endif
    }

    func frostedGlass<S: Shape>(_ shape: S) -> some View {
        self
            .background(.ultraThinMaterial, in: shape)
            .overlay(
                shape.stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.06), Color.white.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 8)
    }

    func card(_ radius: CGFloat = 22) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

// MARK: - Backdrop

struct Backdrop: View {
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.09)
            Circle().fill(Color.purple.opacity(0.55)).frame(width: 320, height: 320)
                .blur(radius: 90).offset(x: -120, y: -260)
            Circle().fill(Color.blue.opacity(0.50)).frame(width: 300, height: 300)
                .blur(radius: 90).offset(x: 150, y: 60)
            Circle().fill(Color.pink.opacity(0.40)).frame(width: 280, height: 280)
                .blur(radius: 90).offset(x: -110, y: 330)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Tabs

enum Tab: Int, CaseIterable {
    case chats, calls, people, profile

    var title: String {
        switch self {
        case .chats: return "Чаты"
        case .calls: return "Звонки"
        case .people: return "Люди"
        case .profile: return "Профиль"
        }
    }

    var icon: String {
        switch self {
        case .chats: return "bubble.left.and.bubble.right.fill"
        case .calls: return "phone.fill"
        case .people: return "person.2.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

/// Bottom bar: put a finger on it and slide — the glass "lens" follows the finger,
/// the tab switches on the way, and the lens snaps to the chosen tab on release.
struct GlassTabBar: View {
    @Binding var selection: Tab
    @State private var dragX: CGFloat? = nil

    private let barHeight: CGFloat = 68
    private let pad: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let count = CGFloat(Tab.allCases.count)
            let w = (geo.size.width - pad * 2) / count
            let innerH = barHeight - pad * 2
            let restX = CGFloat(selection.rawValue) * w
            let lensX: CGFloat = dragX.map { min(max($0 - w / 2, 0), w * (count - 1)) } ?? restX
            let dragging = dragX != nil

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(dragging ? 0.26 : 0.14))
                    .overlay(Capsule().stroke(Color.white.opacity(dragging ? 0.55 : 0.3), lineWidth: 1))
                    .shadow(color: Color.white.opacity(dragging ? 0.25 : 0), radius: 12)
                    .frame(width: w, height: innerH)
                    .scaleEffect(dragging ? 1.16 : 1)
                    .offset(x: lensX)

                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.rawValue) { tab in
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(tab == selection ? Color.white : Color.white.opacity(0.55))
                        .scaleEffect(tab == selection && dragging ? 1.1 : 1)
                        .frame(width: w, height: innerH)
                    }
                }
            }
            .padding(pad)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = value.location.x - pad
                        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.75)) {
                            dragX = x
                        }
                        let idx = min(max(Int(x / w), 0), Tab.allCases.count - 1)
                        if let t = Tab(rawValue: idx), t != selection {
                            selection = t
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.7)) {
                            dragX = nil
                        }
                    }
            )
            .animation(.easeOut(duration: 0.15), value: selection)
        }
        .frame(height: barHeight)
    }
}

// MARK: - Root

struct RootView: View {
    @StateObject private var store = Store()
    @State private var tab: Tab = .chats
    @State private var openChat: UUID? = nil

    var body: some View {
        ZStack {
            Backdrop()

            ZStack {
                switch tab {
                case .chats: ChatListView(open: $openChat).transition(.opacity)
                case .calls: CallsView().transition(.opacity)
                case .people: PeopleView(open: $openChat).transition(.opacity)
                case .profile: ProfileView().transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: tab)

            if openChat == nil {
                VStack {
                    Spacer()
                    GlassTabBar(selection: $tab)
                        .glass(Capsule())
                        .padding(.horizontal, 24)
                        .padding(.bottom, 6)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let id = openChat {
                ChatView(chatID: id, close: { openChat = nil })
                    .transition(.move(edge: .trailing))
            }
        }
        .environmentObject(store)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: openChat)
    }
}

// MARK: - Shared pieces

struct Avatar: View {
    let name: String
    let colors: [Color]
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(String(name.prefix(1)))
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
}

struct ScreenHeader: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            Spacer()
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .glass(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - Chats

struct ChatListView: View {
    @EnvironmentObject var store: Store
    @Binding var open: UUID?
    @State private var query = ""

    var filtered: [Chat] {
        query.isEmpty ? store.chats : store.chats.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenHeader(title: "Чаты", icon: "square.and.pencil")

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.white.opacity(0.6))
                    TextField("Поиск", text: $query)
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .glass(Capsule())
                .padding(.horizontal, 16)

                LazyVStack(spacing: 10) {
                    ForEach(filtered) { chat in
                        Button {
                            Haptic.soft()
                            open = chat.id
                        } label: {
                            ChatRow(chat: chat)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .contentMargins(.bottom, 110, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

enum Haptic {
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
}

struct ChatRow: View {
    let chat: Chat

    var body: some View {
        HStack(spacing: 12) {
            Avatar(name: chat.name, colors: chat.colors)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.name)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text(chat.time)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                HStack {
                    Text(chat.last)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if chat.unread > 0 {
                        Text("\(chat.unread)")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 7)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(
                                Capsule().fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                            )
                    }
                }
            }
        }
        .foregroundStyle(Color.white)
        .padding(12)
        .card()
    }
}

// MARK: - Conversation

struct ChatView: View {
    @EnvironmentObject var store: Store
    let chatID: UUID
    let close: () -> Void
    @State private var text = ""

    var chat: Chat? { store.chats.first { $0.id == chatID } }
    var canSend: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        ZStack {
            Backdrop()
            if let chat = chat {
                VStack(spacing: 0) {
                    header(chat)
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(chat.messages) { m in
                                    Bubble(message: m).id(m.id)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onAppear {
                            if let id = chat.messages.last?.id { proxy.scrollTo(id, anchor: .bottom) }
                        }
                        .onChange(of: chat.messages.count) {
                            if let id = chat.messages.last?.id {
                                withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(id, anchor: .bottom) }
                            }
                        }
                    }
                    inputBar
                }
            }
        }
        .onAppear { store.markRead(chatID) }
        .simultaneousGesture(
            DragGesture().onEnded { v in
                if v.startLocation.x < 40 && v.translation.width > 90 { close() }
            }
        )
    }

    func header(_ chat: Chat) -> some View {
        HStack(spacing: 12) {
            Button(action: close) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .glass(Circle())
            }
            Avatar(name: chat.name, colors: chat.colors, size: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(chat.name).font(.system(size: 17, weight: .semibold))
                Text("в сети").font(.system(size: 12)).foregroundStyle(Color.green)
            }
            Spacer()
            Image(systemName: "phone.fill")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .glass(Circle())
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Сообщение", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glass(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )
            }
            .opacity(canSend ? 1 : 0.4)
            .disabled(!canSend)
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    func send() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        text = ""
        Haptic.soft()
        store.send(t, to: chatID)
    }
}

struct Bubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isMine { Spacer(minLength: 50) }
            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 3) {
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white)
                Text(message.time)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(bubbleFill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
            )
            if !message.isMine { Spacer(minLength: 50) }
        }
    }

    var bubbleFill: AnyShapeStyle {
        if message.isMine {
            return AnyShapeStyle(
                LinearGradient(colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.85)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        } else {
            return AnyShapeStyle(Color.white.opacity(0.10))
        }
    }
}

// MARK: - Calls

struct CallItem: Identifiable {
    let id = UUID()
    let name: String
    let colors: [Color]
    let info: String
    let when: String
    let missed: Bool
}

struct CallsView: View {
    let calls: [CallItem] = [
        CallItem(name: "Алиса", colors: [.pink, .orange], info: "Входящий, 4 мин", when: "Сегодня", missed: false),
        CallItem(name: "Макс", colors: [.blue, .cyan], info: "Пропущенный", when: "Сегодня", missed: true),
        CallItem(name: "Мама", colors: [.orange, .red], info: "Исходящий, 12 мин", when: "Вчера", missed: false),
        CallItem(name: "Дима", colors: [.green, .teal], info: "Пропущенный", when: "Пн", missed: true),
        CallItem(name: "Команда Lumen", colors: [.purple, .indigo], info: "Видеозвонок, 36 мин", when: "Пн", missed: false)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenHeader(title: "Звонки", icon: "phone.badge.plus")
                LazyVStack(spacing: 10) {
                    ForEach(calls) { c in
                        HStack(spacing: 12) {
                            Avatar(name: c.name, colors: c.colors, size: 46)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(c.name).font(.system(size: 16, weight: .semibold))
                                Text(c.info)
                                    .font(.system(size: 13))
                                    .foregroundStyle(c.missed ? Color.red : Color.white.opacity(0.6))
                            }
                            Spacer()
                            Text(c.when)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Image(systemName: "phone.fill")
                                .foregroundStyle(Color.green)
                        }
                        .foregroundStyle(Color.white)
                        .padding(12)
                        .card()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .contentMargins(.bottom, 110, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

// MARK: - People

struct PeopleView: View {
    @EnvironmentObject var store: Store
    @Binding var open: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ScreenHeader(title: "Люди", icon: "person.badge.plus")
                LazyVStack(spacing: 10) {
                    ForEach(store.chats) { chat in
                        HStack(spacing: 12) {
                            Avatar(name: chat.name, colors: chat.colors, size: 46)
                            Text(chat.name).font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Button {
                                Haptic.soft()
                                open = chat.id
                            } label: {
                                Text("Написать")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.14), in: Capsule())
                            }
                        }
                        .foregroundStyle(Color.white)
                        .padding(12)
                        .card()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .contentMargins(.bottom, 110, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

// MARK: - Profile

struct ProfileView: View {
    @State private var notifications = true
    @State private var readReceipts = true
    @State private var privateMode = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenHeader(title: "Профиль")

                VStack(spacing: 8) {
                    Avatar(name: "Я", colors: [.purple, .blue], size: 96)
                    Text("Мой профиль")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                    Text("Lumen Beta 0.1")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .padding(.vertical, 8)

                VStack(spacing: 0) {
                    row("Уведомления", "bell.fill", $notifications)
                    Divider().overlay(Color.white.opacity(0.1))
                    row("Отчёты о прочтении", "checkmark.circle.fill", $readReceipts)
                    Divider().overlay(Color.white.opacity(0.1))
                    row("Скрытый режим", "eye.slash.fill", $privateMode)
                }
                .padding(.horizontal, 16)
                .card()
                .padding(.horizontal, 16)
            }
        }
        .contentMargins(.bottom, 110, for: .scrollContent)
        .scrollIndicators(.hidden)
    }

    func row(_ title: String, _ icon: String, _ value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            Label(title, systemImage: icon)
                .foregroundStyle(Color.white)
        }
        .tint(Color.purple)
        .padding(.vertical, 12)
    }
}
