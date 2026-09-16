import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    readonly property string systemUserName: String(Quickshell.env("USER") || "user")
    readonly property string stateHome: String(Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
    readonly property string statePath: root.stateHome + "/win11-start-menu/state.json"
    readonly property color cardColor: "#f21b1e21"
    readonly property color cardBorderColor: "#5a6b747d"
    readonly property color primaryTextColor: "#f4f6f7"
    readonly property color secondaryTextColor: "#c8d0d4"
    readonly property color mutedTextColor: "#8b969d"
    readonly property color surfaceColor: "#ee282e34"
    readonly property color surfaceHoverColor: "#f03a424b"
    readonly property color inputColor: "#f012161a"
    readonly property color inputBorderColor: "#5f6e78"
    readonly property color inputFocusColor: "#b6c5ff"
    readonly property color itemHoverColor: "#a14b5660"
    readonly property color dividerColor: "#5c676f"
    readonly property color avatarColor: "#d2dcff"
    readonly property color avatarTextColor: "#1b2435"
    readonly property color accentColor: "#b6c5ff"
    readonly property color menuBgColor: "#f22b2b2b"
    readonly property color menuBorderColor: "#5f484848"
    readonly property color menuHoverColor: "#14ffffff"

    property bool menuOpen: false
    property bool menuVisible: false
    property bool allAppsMode: false
    property bool searchMode: false
    property bool powerMenuOpen: false
    property bool contextMenuOpen: false
    property bool stateDirectoryReady: false
    property string activeOutput: ""
    property string query: ""
    property var contextMenuEntry: null
    property var contextMenuActions: []
    property real contextMenuAnchorX: 0
    property real contextMenuAnchorY: 0
    property string dragId: ""
    property var dragOrder: []
    property string ghostIcon: ""
    property string ghostName: ""
    property real ghostX: 0
    property real ghostY: 0

    ListModel {
        id: pinnedModel
    }
    property string profileName: systemUserName
    property string profileGlyph: systemUserName.slice(0, 1).toUpperCase()
    property var applications: []
    property var filteredApplications: []
    property var defaultPinnedIds: []
    property var pinnedIds: []
    property var recentIds: []
    property var quickActions: []
    property var powerActions: []
    property var brightnessMonitors: []
    property var pinnedApplications: []

    function normalized(value) {
        return String(value || "").toLowerCase();
    }

    function refreshApplications() {
        var entries = DesktopEntries.applications.values || [];
        var visibleEntries = [];

        for (var i = 0; i < entries.length; ++i) {
            if (entries[i] && !entries[i].noDisplay) {
                visibleEntries.push(entries[i]);
            }
        }

        visibleEntries.sort(function (left, right) {
            return normalized(left.name).localeCompare(normalized(right.name));
        });
        applications = visibleEntries;
        applyFilter();
        rebuildSelections();
    }

    function applyFilter() {
        var needle = normalized(query).trim();
        if (!needle) {
            filteredApplications = applications;
            return;
        }

        filteredApplications = applications.filter(function (entry) {
            var categories = (entry.categories || []).join(" ");
            var keywords = (entry.keywords || []).join(" ");
            var haystack = [entry.name, entry.genericName, entry.id, categories, keywords].join(" ");
            return normalized(haystack).indexOf(needle) !== -1;
        });
    }

    function clearSearch() {
        query = "";
        searchMode = false;
        allAppsMode = false;
        applyFilter();
    }

    function entryById(id) {
        var entry = DesktopEntries.byId(id);
        return entry && !entry.noDisplay ? entry : null;
    }

    function rebuildSelections() {
        var pinned = [];

        for (var i = 0; i < pinnedIds.length; ++i) {
            var pinnedEntry = entryById(pinnedIds[i]);
            if (pinnedEntry) {
                pinned.push(pinnedEntry);
            }
        }

        pinnedApplications = pinned;

        // keep the pinned grid ListModel in sync (skip while a live drag is in progress)
        if (!dragId) {
            var modelIds = [];
            for (var m = 0; m < pinnedModel.count; ++m) {
                modelIds.push(pinnedModel.get(m).appId);
            }
            if (modelIds.join(",") !== pinnedIds.join(",")) {
                pinnedModel.clear();
                for (var p = 0; p < pinned.length; ++p) {
                    pinnedModel.append({
                        appId: pinned[p].id,
                        name: pinned[p].name,
                        icon: pinned[p].icon || ""
                    });
                }
            }
        }
    }

    function loadDefaults() {
        try {
            var data = JSON.parse(defaultsFile.text());
            defaultPinnedIds = Array.isArray(data.pinned) ? data.pinned : [];
            quickActions = Array.isArray(data.quickActions) ? data.quickActions : [];
            powerActions = Array.isArray(data.powerActions) ? data.powerActions : [];
            if (data.profile) {
                profileName = String(data.profile.name || profileName);
                profileGlyph = String(data.profile.glyph || profileGlyph);
            }
        } catch (error) {
            defaultPinnedIds = [];
            quickActions = [];
            powerActions = [];
        }
    }

    function loadState() {
        var state = null;
        try {
            state = JSON.parse(stateFile.text());
        } catch (error) {
            state = null;
        }

        if (state && state.version === 2 && Array.isArray(state.pinned)) {
            pinnedIds = state.pinned;
            recentIds = Array.isArray(state.recent) ? state.recent : [];
        } else {
            pinnedIds = defaultPinnedIds.slice();
            recentIds = [];
        }
        rebuildSelections();
    }

    function saveState() {
        if (!stateDirectoryReady) {
            return;
        }

        stateFile.setText(JSON.stringify({
            "version": 2,
            "pinned": pinnedIds,
            "recent": recentIds
        }, null, 2));
    }

    function togglePin(id) {
        var next = pinnedIds.slice();
        var index = next.indexOf(id);
        if (index === -1) {
            next.push(id);
        } else {
            next.splice(index, 1);
        }
        pinnedIds = next;
        rebuildSelections();
        saveState();
    }

    function movePinned(id, delta) {
        var next = pinnedIds.slice();
        var index = next.indexOf(id);
        var targetIndex = index + delta;
        if (index < 0 || targetIndex < 0 || targetIndex >= next.length) {
            return;
        }

        var moved = next.splice(index, 1)[0];
        next.splice(targetIndex, 0, moved);
        pinnedIds = next;
        rebuildSelections();
        saveState();
    }

    function movePinnedTo(id, targetId, placeAfter) {
        placeAfter = placeAfter === true;
        if (!id || id === targetId) {
            return;
        }

        var next = pinnedIds.slice();
        var index = next.indexOf(id);
        if (index < 0) {
            return;
        }

        var moved = next.splice(index, 1)[0];

        if (!targetId) {
            next.push(moved);
        } else {
            var targetIndex = next.indexOf(targetId);
            if (targetIndex < 0) {
                next.push(moved);
            } else {
                next.splice(placeAfter ? targetIndex + 1 : targetIndex, 0, moved);
            }
        }

        pinnedIds = next;
        rebuildSelections();
        saveState();
    }

    function movePinnedLive(targetIndex) {
        if (!dragId) {
            return;
        }

        var count = pinnedModel.count;
        if (count === 0) {
            return;
        }
        targetIndex = Math.max(0, Math.min(count - 1, targetIndex));

        var from = -1;
        for (var i = 0; i < count; ++i) {
            if (pinnedModel.get(i).appId === dragId) {
                from = i;
                break;
            }
        }
        if (from < 0 || from === targetIndex) {
            return;
        }

        pinnedModel.move(from, targetIndex, 1);
    }

    function dropPinned() {
        if (!dragId) {
            return;
        }

        var next = [];
        for (var i = 0; i < pinnedModel.count; ++i) {
            next.push(pinnedModel.get(i).appId);
        }

        dragId = "";
        if (next.join(",") !== pinnedIds.join(",")) {
            pinnedIds = next;
            rebuildSelections();
            saveState();
        }
    }

    function runApplication(entry) {
        if (!entry) {
            return;
        }

        var nextRecent = [entry.id];
        for (var i = 0; i < recentIds.length && nextRecent.length < 8; ++i) {
            if (recentIds[i] !== entry.id) {
                nextRecent.push(recentIds[i]);
            }
        }
        recentIds = nextRecent;
        rebuildSelections();
        saveState();
        hideMenu();
        entry.execute();
    }

    function setAppsView(showAll) {
        allAppsMode = showAll;
        searchMode = false;
        powerMenuOpen = false;
        closeContextMenu();
        if (!showAll) {
            clearSearch();
        } else {
            query = "";
            applyFilter();
        }
    }

    function togglePowerMenu() {
        closeContextMenu();
        powerMenuOpen = !powerMenuOpen;
        if (powerMenuOpen) {
            refreshBrightness();
        }
    }

    function closeContextMenu() {
        contextMenuOpen = false;
        contextMenuEntry = null;
        contextMenuActions = [];
    }

    function openContextMenu(entry, anchorX, anchorY) {
        if (!entry) {
            return;
        }

        var isPinned = pinnedIds.indexOf(entry.id) >= 0;
        var actions = [
            { id: "launch", label: "Открыть", glyph: "↗", enabled: true }
        ];

        if (isPinned) {
            actions.push({ id: "unpin", label: "Открепить", glyph: "−", enabled: true });
            actions.push({ id: "move-left", label: "Переместить влево", glyph: "←", enabled: pinnedIds.indexOf(entry.id) > 0 });
            actions.push({ id: "move-right", label: "Переместить вправо", glyph: "→", enabled: pinnedIds.indexOf(entry.id) < pinnedIds.length - 1 });
        } else {
            actions.push({ id: "pin", label: "Закрепить", glyph: "+", enabled: true });
        }

        contextMenuEntry = entry;
        contextMenuActions = actions;

        contextMenuAnchorX = anchorX;
        contextMenuAnchorY = anchorY;
        contextMenuOpen = true;
        powerMenuOpen = false;
    }

    function executeContextAction(actionId) {
        var entry = contextMenuEntry;
        closeContextMenu();
        if (!entry) {
            return;
        }

        if (actionId === "launch") {
            runApplication(entry);
        } else if (actionId === "pin" || actionId === "unpin") {
            togglePin(entry.id);
        } else if (actionId === "move-left") {
            movePinned(entry.id, -1);
        } else if (actionId === "move-right") {
            movePinned(entry.id, 1);
        }
    }

    function executeConfiguredAction(action) {
        if (!action) {
            return;
        }
        if (action.id === "power") {
            togglePowerMenu();
            return;
        }

        var command = Array.isArray(action.command) ? action.command.slice() : [];
        if (command.length === 0) {
            return;
        }
        for (var i = 0; i < command.length; ++i) {
            command[i] = String(command[i]).replace("__USER__", root.systemUserName);
        }
        powerMenuOpen = false;
        closeContextMenu();
        hideMenu();
        Quickshell.execDetached(command);
    }

    function requestFocusedOutput() {
        outputProcess.running = false;
        outputProcess.command = ["niri", "msg", "-j", "focused-output"];
        outputProcess.running = true;
    }

    function showMenu() {
        if (menuOpen) {
            return;
        }
        closeAnimationTimer.stop();
        menuVisible = true;
        powerMenuOpen = false;
        closeContextMenu();
        if (!root.activeOutput && Quickshell.screens.length > 0) {
            root.activeOutput = Quickshell.screens[0].name;
        }
        allAppsMode = false;
        searchMode = false;
        query = "";
        menuOpen = true;
        requestFocusedOutput();
    }

    function hideMenu() {
        if (!menuOpen) {
            return;
        }
        menuOpen = false;
        powerMenuOpen = false;
        closeContextMenu();
        searchMode = false;
        query = "";
        closeAnimationTimer.restart();
    }

    function toggleMenu() {
        if (menuOpen) {
            hideMenu();
        } else {
            showMenu();
        }
    }

    FileView {
        id: defaultsFile
        path: Qt.resolvedUrl("./defaults.json")
        blockLoading: true
    }

    FileView {
        id: stateFile
        path: root.stateDirectoryReady ? root.statePath : ""
        blockLoading: true
        atomicWrites: true
    }

    Process {
        id: stateDirectoryProcess
        command: ["mkdir", "-p", root.stateHome + "/win11-start-menu"]
        running: false

        onExited: function () {
            stateFilePrepareProcess.running = true;
        }
    }

    Process {
        id: stateFilePrepareProcess
        command: ["touch", root.statePath]
        running: false

        onExited: function () {
            root.stateDirectoryReady = true;
            stateFile.reload();
            root.loadState();
            root.saveState();
        }
    }

    Process {
        id: outputProcess
        running: false

        stdout: StdioCollector {
            id: outputCollector
        }

        onExited: function () {
            var outputName = "";
            try {
                var output = JSON.parse(outputCollector.text);
                outputName = String(output.name || "");
            } catch (error) {
                outputName = "";
            }

            if (!outputName && Quickshell.screens.length > 0) {
                outputName = Quickshell.screens[0].name;
            }
            if (outputName) {
                root.activeOutput = outputName;
            }
        }
    }

    Process {
        id: brightnessListProcess
        running: false

        stdout: StdioCollector {
            id: brightnessListCollector
        }

        onExited: function () {
            var monitors = [];
            var lines = String(brightnessListCollector.text || "").split("\n");
            console.log("[brightness] raw list output:", JSON.stringify(brightnessListCollector.text || ""));
            for (var i = 0; i < lines.length; ++i) {
                var parts = lines[i].split(":");
                if (parts.length === 3 && parts[0] && parts[1] !== "") {
                    monitors.push({
                        name: parts[0],
                        value: parseInt(parts[1], 10),
                        max: parseInt(parts[2], 10) || 100
                    });
                }
            }
            console.log("[brightness] parsed monitors:", monitors.length);
            root.brightnessMonitors = monitors;
        }
    }

    Timer {
        id: brightnessSetTimer
        interval: 120
        repeat: false

        property string pendingOutput: ""
        property int pendingValue: -1

        onTriggered: {
            if (pendingOutput && pendingValue >= 0) {
                brightnessSetProcess.command = [
                    "monitor-brightness", "set", pendingOutput, String(pendingValue)
                ];
                brightnessSetProcess.running = true;
            }
        }
    }

    Process {
        id: brightnessSetProcess
        running: false
        command: []
    }

    function refreshBrightness() {
        brightnessListProcess.command = ["monitor-brightness", "list"];
        brightnessListProcess.running = true;
    }

    function setBrightness(output, value) {
        for (var i = 0; i < brightnessMonitors.length; ++i) {
            if (brightnessMonitors[i].name === output) {
                brightnessMonitors[i].value = value;
                break;
            }
        }
        brightnessMonitorsChanged();

        brightnessSetTimer.pendingOutput = output;
        brightnessSetTimer.pendingValue = value;
        brightnessSetTimer.restart();
    }

    function powerOffMonitors() {
        powerMenuOpen = false;
        closeContextMenu();
        hideMenu();
        Qt.callLater(function () {
            Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
        });
    }

    Timer {
        id: closeAnimationTimer
        interval: 190
        repeat: false
        onTriggered: root.menuVisible = false
    }

    IpcHandler {
        target: "start-menu"

        function toggle(): void {
            root.toggleMenu();
        }

        function show(): void {
            root.showMenu();
        }

        function hide(): void {
            root.hideMenu();
        }

        function brightness(): void {
            root.refreshBrightness();
        }
    }

    Connections {
        target: DesktopEntries

        function onApplicationsChanged() {
            root.refreshApplications();
        }
    }

    Component.onCompleted: {
        loadDefaults();
        refreshApplications();
        requestFocusedOutput();
        stateDirectoryProcess.running = true;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData

            screen: modelData
            visible: true
            color: "transparent"
            aboveWindows: true

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.menuOpen && (root.activeOutput === "" || modelData.name === root.activeOutput) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "win11-start-menu"
            mask: Region {
                item: root.menuOpen ? panelContent : null
            }

            function isTargetOutput() {
                return root.menuOpen && (root.activeOutput === "" || modelData.name === root.activeOutput);
            }

            function updateKeyboardFocus() {
                if (isTargetOutput()) {
                    searchField.forceActiveFocus();
                    focusRetryTimer.restart();
                } else {
                    focusRetryTimer.stop();
                }
            }

            Connections {
                target: root

                function onMenuOpenChanged() {
                    panel.updateKeyboardFocus();
                }

                function onActiveOutputChanged() {
                    panel.updateKeyboardFocus();
                }
            }

            Timer {
                id: focusRetryTimer
                interval: 30
                repeat: true

                onTriggered: {
                    if (!panel.isTargetOutput()) {
                        focusRetryTimer.stop();
                        return;
                    }
                    if (searchField.activeFocus) {
                        focusRetryTimer.stop();
                        return;
                    }
                    searchField.forceActiveFocus();
                }
            }

            Item {
                id: panelContent
                anchors.fill: parent

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Escape) {
                        if (root.contextMenuOpen) {
                            root.closeContextMenu();
                        } else if (root.powerMenuOpen) {
                            root.powerMenuOpen = false;
                        } else if (root.query.length > 0) {
                            root.clearSearch();
                            searchField.forceActiveFocus();
                        } else {
                            root.hideMenu();
                        }
                        event.accepted = true;
                        return;
                    }

                    if ((event.modifiers & Qt.ControlModifier) !== 0 && event.key === Qt.Key_L) {
                        searchField.forceActiveFocus();
                        searchField.selectAll();
                        event.accepted = true;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.menuOpen
                    onClicked: root.hideMenu()
                }

                Rectangle {
                    id: menuCard
                    visible: root.menuVisible && (root.activeOutput === "" || modelData.name === root.activeOutput)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 18
                    width: Math.min(920, parent.width - 64)
                    height: Math.min(720, parent.height - 64)
                    radius: 18
                    color: root.cardColor
                    border.width: 1
                    border.color: root.cardBorderColor
                    opacity: root.menuOpen ? 1 : 0
                    scale: root.menuOpen ? 1 : 0.97
                    transformOrigin: Item.Bottom

                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }

                    Behavior on scale {
                        NumberAnimation { duration: 180; easing.type: Easing.OutBack }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: function (mouse) {
                            if (root.contextMenuOpen) {
                                root.closeContextMenu();
                            }
                            mouse.accepted = true;
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 34
                        anchors.rightMargin: 34
                        anchors.topMargin: 28
                        anchors.bottomMargin: 18
                        spacing: 13

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            spacing: 12

                            TextField {
                                id: searchField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                placeholderText: "Поиск приложений, параметров и документов"
                                text: root.query
                                color: root.primaryTextColor
                                placeholderTextColor: root.mutedTextColor
                                font.pixelSize: 15
                                selectByMouse: true
                                leftPadding: 18
                                rightPadding: root.query.length > 0 ? 52 : 18

                                background: Rectangle {
                                    radius: 0
                                    color: root.inputColor
                                    border.width: searchField.activeFocus ? 2 : 1
                                    border.color: searchField.activeFocus ? root.inputFocusColor : root.inputBorderColor
                                }

                                Rectangle {
                                    id: clearSearchButton
                                    visible: root.query.length > 0
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 30
                                    height: 30
                                    radius: 0
                                    color: clearSearchMouse.containsMouse ? root.surfaceHoverColor : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: root.secondaryTextColor
                                        font.pixelSize: 20
                                    }

                                    MouseArea {
                                        id: clearSearchMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            root.clearSearch();
                                            searchField.forceActiveFocus();
                                        }
                                    }

                                    ToolTip.visible: clearSearchMouse.containsMouse
                                    ToolTip.text: "Очистить поиск"
                                }

                                onTextChanged: {
                                    var wasSearchMode = root.searchMode;
                                    root.query = text;
                                    root.searchMode = text.trim().length > 0;
                                    root.applyFilter();
                                    if (root.searchMode) {
                                        root.allAppsMode = true;
                                    } else if (wasSearchMode) {
                                        root.allAppsMode = false;
                                    }
                                }

                                Keys.onReturnPressed: {
                                    if (root.query.trim().length > 0 && root.filteredApplications.length > 0) {
                                        root.runApplication(root.filteredApplications[0]);
                                    }
                                }

                                Keys.onEscapePressed: {
                                    if (root.query.length > 0) {
                                        root.clearSearch();
                                        searchField.forceActiveFocus();
                                    } else {
                                        root.hideMenu();
                                    }
                                    event.accepted = true;
                                }

                                Keys.onDownPressed: {
                                    if (root.filteredApplications.length > 0) {
                                        allAppsList.currentIndex = 0;
                                        allAppsList.forceActiveFocus();
                                        event.accepted = true;
                                    }
                                }

                                Keys.onUpPressed: {
                                    if (root.filteredApplications.length > 0) {
                                        allAppsList.currentIndex = Math.max(0, allAppsList.count - 1);
                                        allAppsList.forceActiveFocus();
                                        allAppsList.positionViewAtEnd();
                                        event.accepted = true;
                                    }
                                }
                            }
                        }

                        StackLayout {
                            id: appStack
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            currentIndex: root.allAppsMode ? 1 : 0

                            Item {
                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 13

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30

                                        Label {
                                            text: "Закреплённое"
                                            color: root.primaryTextColor
                                            font.pixelSize: 17
                                            font.weight: Font.DemiBold
                                        }

                                        Item { Layout.fillWidth: true }
                                    }

                                    GridView {
                                        id: pinnedGrid
                                        Layout.fillWidth: true
                                        implicitHeight: {
                                            var cols = Math.max(4, Math.min(8, Math.floor((menuCard.width - 72) / 112)));
                                            var rows = Math.max(1, Math.ceil(pinnedModel.count / cols));
                                            return rows * 88;
                                        }
                                        cellWidth: Math.floor(width / Math.max(4, Math.min(8, Math.floor((menuCard.width - 72) / 112))))
                                        cellHeight: 88
                                        clip: true
                                        interactive: false
                                        boundsBehavior: Flickable.StopAtBounds

                                        move: Transition {
                                            NumberAnimation { properties: "x,y"; duration: 220; easing.type: Easing.OutCubic }
                                        }
                                        displaced: Transition {
                                            NumberAnimation { properties: "x,y"; duration: 220; easing.type: Easing.OutCubic }
                                        }

                                        model: pinnedModel

                                        delegate: Item {
                                            id: pinnedDelegate
                                            required property string appId
                                            required property string name
                                            required property string icon
                                            required property int index
                                            property var app: entryById(appId)
                                            width: pinnedGrid.cellWidth
                                            height: pinnedGrid.cellHeight
                                            opacity: root.dragId === appId ? 0.3 : 1

                                            Behavior on opacity {
                                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: 2
                                                radius: 9
                                                color: (tileMouse.containsMouse || pinnedDelegate.activeFocus) && root.dragId !== appId ? root.itemHoverColor : "transparent"
                                            }

                                            Column {
                                                anchors.fill: parent
                                                anchors.margins: 7
                                                spacing: 5

                                                Image {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: 44
                                                    height: 44
                                                    source: app ? Quickshell.iconPath(app.icon, "application-x-executable") : ""
                                                    sourceSize.width: 44
                                                    sourceSize.height: 44
                                                    smooth: true
                                                }

                                                Text {
                                                    width: parent.width
                                                    text: pinnedDelegate.name
                                                    color: root.primaryTextColor
                                                    font.pixelSize: 11
                                                    horizontalAlignment: Text.AlignHCenter
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            MouseArea {
                                                id: tileMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                property point pressPos
                                                property bool dragActive: false

                                                onPressed: function (mouse) {
                                                    pressPos = Qt.point(mouse.x, mouse.y);
                                                    dragActive = false;
                                                }

                                                onPositionChanged: function (mouse) {
                                                    if (!pressed || !app) {
                                                        return;
                                                    }

                                                    if (!dragActive) {
                                                        var dx = mouse.x - pressPos.x;
                                                        var dy = mouse.y - pressPos.y;
                                                        if (Math.abs(dx) < 18 && Math.abs(dy) < 18) {
                                                            return;
                                                        }
                                                        dragActive = true;
                                                        root.dragId = app.id;
                                                        root.ghostIcon = Quickshell.iconPath(app.icon, "application-x-executable");
                                                        root.ghostName = app.name;
                                                    }

                                                    var global = tileMouse.mapToItem(menuCard, mouse.x, mouse.y);
                                                    root.ghostX = global.x - pinnedGrid.cellWidth / 2;
                                                    root.ghostY = global.y - pinnedGrid.cellHeight / 2;

                                                    var gridPos = tileMouse.mapToItem(pinnedGrid, mouse.x, mouse.y);
                                                    var cols = Math.max(1, Math.round(pinnedGrid.width / pinnedGrid.cellWidth));
                                                    var col = Math.floor(gridPos.x / pinnedGrid.cellWidth);
                                                    var row = Math.floor(gridPos.y / pinnedGrid.cellHeight);
                                                    col = Math.max(0, Math.min(cols - 1, col));
                                                    row = Math.max(0, row);
                                                    root.movePinnedLive(row * cols + col);
                                                }

                                                onReleased: {
                                                    if (dragActive) {
                                                        root.dropPinned();
                                                    }
                                                }

                                                onCanceled: {
                                                    if (dragActive) {
                                                        root.dropPinned();
                                                    }
                                                    dragActive = false;
                                                }

                                                onClicked: function (mouse) {
                                                    if (dragActive) {
                                                        dragActive = false;
                                                        return;
                                                    }
                                                    if (mouse.button === Qt.RightButton) {
                                                        var point = tileMouse.mapToItem(menuCard, mouse.x, mouse.y);
                                                        root.openContextMenu(app, point.x, point.y);
                                                    } else {
                                                        root.runApplication(app);
                                                    }
                                                }
                                            }

                                            Keys.onReturnPressed: root.runApplication(app)
                                            Keys.onSpacePressed: root.runApplication(app)
                                            Keys.onPressed: function (event) {
                                                if ((event.modifiers & Qt.ControlModifier) !== 0 && event.key === Qt.Key_Left) {
                                                    root.movePinned(app.id, -1);
                                                    event.accepted = true;
                                                    return;
                                                }
                                                if ((event.modifiers & Qt.ControlModifier) !== 0 && event.key === Qt.Key_Right) {
                                                    root.movePinned(app.id, 1);
                                                    event.accepted = true;
                                                    return;
                                                }

                                                var targetIndex = index;
                                                if (event.key === Qt.Key_Left) targetIndex -= 1;
                                                else if (event.key === Qt.Key_Right) targetIndex += 1;
                                                else if (event.key === Qt.Key_Up) targetIndex -= Math.max(1, Math.round(pinnedGrid.width / pinnedGrid.cellWidth));
                                                else if (event.key === Qt.Key_Down) targetIndex += Math.max(1, Math.round(pinnedGrid.width / pinnedGrid.cellWidth));
                                                else return;

                                                if (targetIndex >= 0 && targetIndex < pinnedModel.count) {
                                                    pinnedGrid.currentIndex = targetIndex;
                                                    var target = pinnedGrid.currentItem;
                                                    if (target) target.forceActiveFocus();
                                                    event.accepted = true;
                                                }
                                            }
                                        }
                                    }

                                    Label {
                                        visible: root.pinnedApplications.length === 0
                                        text: "Нет закреплённых приложений. Выберите приложение ниже и нажмите ПКМ."
                                        color: root.mutedTextColor
                                        font.pixelSize: 13
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30

                                        Label {
                                            text: "Приложения"
                                            color: root.primaryTextColor
                                            font.pixelSize: 17
                                            font.weight: Font.DemiBold
                                        }

                                        Item { Layout.fillWidth: true }

                                    }

                                    ListView {
                                        id: applicationsList
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        model: root.applications
                                        spacing: 2

                                        delegate: Item {
                                            required property var modelData
                                            property var app: modelData
                                            width: applicationsList.width
                                            height: 47
                                            focus: true
                                            activeFocusOnTab: true

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 8
                                                color: applicationsMouse.containsMouse || parent.activeFocus ? root.itemHoverColor : "transparent"
                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 11
                                                anchors.rightMargin: 11
                                                spacing: 11

                                                Image {
                                                    Layout.preferredWidth: 30
                                                    Layout.preferredHeight: 30
                                                    source: app ? Quickshell.iconPath(app.icon, "application-x-executable") : ""
                                                    sourceSize.width: 30
                                                    sourceSize.height: 30
                                                    smooth: true
                                                }

                                                Label {
                                                    text: app ? app.name : ""
                                                    color: root.primaryTextColor
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            MouseArea {
                                                id: applicationsMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: function (mouse) {
                                                    if (mouse.button === Qt.RightButton) {
                                                        var point = applicationsMouse.mapToItem(menuCard, mouse.x, mouse.y);
                                                        root.openContextMenu(app, point.x, point.y);
                                                    } else {
                                                        root.runApplication(app);
                                                    }
                                                }
                                            }

                                            Keys.onReturnPressed: root.runApplication(app)
                                            Keys.onSpacePressed: root.runApplication(app)
                                            Keys.onPressed: function (event) {
                                                if (event.key !== Qt.Key_Up && event.key !== Qt.Key_Down) return;
                                                var view = ListView.view;
                                                var delta = event.key === Qt.Key_Down ? 1 : -1;
                                                var targetIndex = Math.max(0, Math.min(view.count - 1, view.currentIndex + delta));
                                                view.currentIndex = targetIndex;
                                                view.positionViewAtIndex(targetIndex, ListView.Contain);
                                                Qt.callLater(function () {
                                                    if (view.currentItem) view.currentItem.forceActiveFocus();
                                                });
                                                event.accepted = true;
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30

                                        Label {
                                            text: root.searchMode ? "Результаты поиска" : "Все приложения"
                                            color: root.primaryTextColor
                                            font.pixelSize: 17
                                            font.weight: Font.DemiBold
                                        }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            Layout.preferredWidth: 106
                                            Layout.preferredHeight: 30
                                            radius: 8
                                            color: backButton.containsMouse ? root.surfaceHoverColor : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.searchMode ? "Очистить" : "‹  Назад"
                                                color: root.secondaryTextColor
                                                font.pixelSize: 13
                                            }

                                            MouseArea {
                                                id: backButton
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: {
                                                    if (root.searchMode) {
                                                        root.clearSearch();
                                                        searchField.forceActiveFocus();
                                                    } else {
                                                        root.setAppsView(false);
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Label {
                                        text: root.searchMode
                                            ? "Найдено: " + root.filteredApplications.length
                                            : "Приложений: " + root.filteredApplications.length
                                        color: root.mutedTextColor
                                        font.pixelSize: 12
                                    }

                                    ListView {
                                        id: allAppsList
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        model: root.filteredApplications
                                        spacing: 3
                                        activeFocusOnTab: true

                                        delegate: Item {
                                            required property var modelData
                                            property var app: modelData
                                            width: allAppsList.width
                                            height: 54
                                            focus: true
                                            activeFocusOnTab: true

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 8
                                                color: allAppMouse.containsMouse || parent.activeFocus ? root.itemHoverColor : "transparent"
                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 12

                                                Image {
                                                    Layout.preferredWidth: 34
                                                    Layout.preferredHeight: 34
                                                    source: app ? Quickshell.iconPath(app.icon, "application-x-executable") : ""
                                                    sourceSize.width: 34
                                                    sourceSize.height: 34
                                                    smooth: true
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 1

                                                    Label {
                                                        text: app ? app.name : ""
                                                        color: root.primaryTextColor
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }

                                                    Label {
                                                        text: app && app.genericName ? app.genericName : app.id
                                                        color: root.mutedTextColor
                                                        font.pixelSize: 11
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }
                                                }

                                                Label {
                                                    text: pinnedIds.indexOf(app.id) >= 0 ? "Закреплено" : ""
                                                    color: root.mutedTextColor
                                                    font.pixelSize: 11
                                                }
                                            }

                                            MouseArea {
                                                id: allAppMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: function (mouse) {
                                                    if (mouse.button === Qt.RightButton) {
                                                        var point = allAppMouse.mapToItem(menuCard, mouse.x, mouse.y);
                                                        root.openContextMenu(app, point.x, point.y);
                                                    } else {
                                                        root.runApplication(app);
                                                    }
                                                }
                                            }

                                            Keys.onReturnPressed: root.runApplication(app)
                                            Keys.onSpacePressed: root.runApplication(app)
                                            Keys.onPressed: function (event) {
                                                if (event.key !== Qt.Key_Up && event.key !== Qt.Key_Down) return;
                                                var view = ListView.view;
                                                var delta = event.key === Qt.Key_Down ? 1 : -1;
                                                var targetIndex = Math.max(0, Math.min(view.count - 1, view.currentIndex + delta));
                                                view.currentIndex = targetIndex;
                                                view.positionViewAtIndex(targetIndex, ListView.Contain);
                                                Qt.callLater(function () {
                                                    if (view.currentItem) view.currentItem.forceActiveFocus();
                                                });
                                                event.accepted = true;
                                            }
                                        }

                                        ScrollBar.vertical: ScrollBar { }
                                    }

                                    Label {
                                        visible: root.filteredApplications.length === 0
                                        text: "Ничего не найдено"
                                        color: root.mutedTextColor
                                        font.pixelSize: 13
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.dividerColor
                        }

                        RowLayout {
                            id: footer
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: 17
                                color: root.avatarColor

                                Text {
                                    anchors.centerIn: parent
                                    text: root.profileGlyph
                                    color: root.avatarTextColor
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }
                            }

                            Label {
                                text: root.profileName
                                color: root.primaryTextColor
                                font.pixelSize: 14
                            }

                            Item { Layout.fillWidth: true }

                            Repeater {
                                model: root.quickActions

                                delegate: Rectangle {
                                    required property var modelData
                                    property var action: modelData
                                    Layout.preferredWidth: 38
                                    Layout.preferredHeight: 38
                                    radius: 9
                                    color: quickActionMouse.containsMouse ? root.surfaceHoverColor : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: action.glyph || "•"
                                        color: root.secondaryTextColor
                                        font.pixelSize: 20
                                    }

                                    MouseArea {
                                        id: quickActionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.executeConfiguredAction(action)
                                    }

                                    ToolTip.visible: quickActionMouse.containsMouse
                                    ToolTip.text: action.label || action.id
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: dragGhost
                        visible: root.dragId !== ""
                        x: root.ghostX
                        y: root.ghostY
                        width: pinnedGrid.cellWidth - 4
                        height: pinnedGrid.cellHeight - 4
                        radius: 9
                        color: root.cardColor
                        border.width: 1
                        border.color: root.accentColor
                        opacity: 0.92
                        z: 20

                        Column {
                            anchors.fill: parent
                            anchors.margins: 7
                            spacing: 5

                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 44
                                height: 44
                                source: root.ghostIcon
                                sourceSize.width: 44
                                sourceSize.height: 44
                                smooth: true
                            }

                            Text {
                                width: parent.width
                                text: root.ghostName
                                color: root.primaryTextColor
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        id: contextMenu
                        visible: root.contextMenuOpen
                        x: Math.max(12, Math.min(parent.width - width - 12, root.contextMenuAnchorX + 10))
                        y: root.contextMenuAnchorY + height + 12 <= parent.height - 12
                            ? root.contextMenuAnchorY + 12
                            : Math.max(12, root.contextMenuAnchorY - height - 12)
                        width: 200
                        height: root.contextMenuActions.length * 32 + 10
                        radius: 8
                        color: root.menuBgColor
                        border.width: 1
                        border.color: root.menuBorderColor
                        z: 10
                        opacity: root.contextMenuOpen ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function (mouse) { mouse.accepted = true; }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 1

                            Repeater {
                                model: root.contextMenuActions

                                delegate: Rectangle {
                                    required property var modelData
                                    property var action: modelData
                                    width: contextMenu.width - 10
                                    height: 30
                                    radius: 4
                                    enabled: action.enabled !== false
                                    opacity: enabled ? 1 : 0.42
                                    color: contextActionMouse.containsMouse ? root.menuHoverColor : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        Label {
                                            text: action.glyph || "•"
                                            color: root.secondaryTextColor
                                            font.pixelSize: 15
                                            horizontalAlignment: Text.AlignHCenter
                                            Layout.preferredWidth: 18
                                        }

                                        Label {
                                            text: action.label || action.id
                                            color: root.primaryTextColor
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                        }
                                    }

                                    MouseArea {
                                        id: contextActionMouse
                                        anchors.fill: parent
                                        enabled: parent.enabled
                                        hoverEnabled: true
                                        onClicked: root.executeContextAction(action.id)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: powerMenu
                        visible: root.powerMenuOpen
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 72
                        width: 260
                        height: {
                            var h = root.powerActions.length * 32 + 10;
                            if (root.brightnessMonitors.length > 0) {
                                h += root.brightnessMonitors.length * 40 + 26;
                            }
                            h += 36; // power-off-monitors button
                            return h;
                        }
                        radius: 8
                        color: root.menuBgColor
                        border.width: 1
                        border.color: root.menuBorderColor
                        z: 5

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function (mouse) { mouse.accepted = true; }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 1

                            Repeater {
                                model: root.powerActions

                                delegate: Rectangle {
                                    required property var modelData
                                    property var action: modelData
                                    width: powerMenu.width - 10
                                    height: 30
                                    radius: 4
                                    color: powerItemMouse.containsMouse ? root.menuHoverColor : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        Label {
                                            text: action.glyph || "•"
                                            color: root.secondaryTextColor
                                            font.pixelSize: 15
                                            horizontalAlignment: Text.AlignHCenter
                                            Layout.preferredWidth: 18
                                        }

                                        Label {
                                            text: action.label || action.id
                                            color: root.primaryTextColor
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                        }
                                    }

                                    MouseArea {
                                        id: powerItemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.executeConfiguredAction(action)
                                    }
                                }
                            }

                            Rectangle {
                                visible: root.brightnessMonitors.length > 0
                                width: powerMenu.width - 10
                                height: 1
                                color: root.menuBorderColor
                            }

                            Repeater {
                                model: root.brightnessMonitors

                                delegate: Item {
                                    required property var modelData
                                    property var monitor: modelData
                                    visible: true
                                    width: powerMenu.width - 10
                                    height: 40

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 2

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Label {
                                                text: monitor.name
                                                color: root.secondaryTextColor
                                                font.pixelSize: 11
                                                Layout.fillWidth: true
                                            }

                                            Label {
                                                text: monitor.value + "%"
                                                color: root.secondaryTextColor
                                                font.pixelSize: 11
                                            }
                                        }

                                        Slider {
                                            id: brightnessSlider
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 18
                                            from: 0
                                            to: monitor.max
                                            value: monitor.value
                                            wheelEnabled: true

                                            background: Rectangle {
                                                x: brightnessSlider.leftPadding
                                                y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                                width: brightnessSlider.availableWidth
                                                height: 4
                                                radius: 2
                                                color: root.menuBorderColor

                                                Rectangle {
                                                    width: brightnessSlider.visualPosition * parent.width
                                                    height: parent.height
                                                    radius: 2
                                                    color: root.accentColor
                                                }
                                            }

                                            handle: Rectangle {
                                                x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                                                y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                                width: 12
                                                height: 12
                                                radius: 6
                                                color: root.accentColor
                                            }

                                            onMoved: root.setBrightness(monitor.name, Math.round(value))
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: powerMenu.width - 10
                                height: 30
                                radius: 4
                                color: powerOffMouse.containsMouse ? root.menuHoverColor : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    Label {
                                        text: "◍"
                                        color: root.secondaryTextColor
                                        font.pixelSize: 15
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.preferredWidth: 18
                                    }

                                    Label {
                                        text: "Выключить экраны"
                                        color: root.primaryTextColor
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    id: powerOffMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.powerOffMonitors()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
