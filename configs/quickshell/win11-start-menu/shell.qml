import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    readonly property string userName: String(Quickshell.env("USER") || "User")
    readonly property string stateHome: String(Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
    readonly property string statePath: root.stateHome + "/win11-start-menu/state.json"
    readonly property color cardColor: "#f01f211f"
    readonly property color cardBorderColor: "#59605f5a"
    readonly property color primaryTextColor: "#f3f3ef"
    readonly property color secondaryTextColor: "#c3c5be"
    readonly property color mutedTextColor: "#9da19a"
    readonly property color surfaceColor: "#322f2caa"
    readonly property color surfaceHoverColor: "#514d47cc"
    readonly property color inputColor: "#252724e8"
    readonly property color inputBorderColor: "#5a5d57"
    readonly property color inputFocusColor: "#bdbfb8"
    readonly property color itemHoverColor: "#4c5049aa"
    readonly property color recentColor: "#383a36aa"
    readonly property color dividerColor: "#585b54"
    readonly property color avatarColor: "#d7d8d1"
    readonly property color avatarTextColor: "#353832"
    property bool menuOpen: false
    property bool menuVisible: false
    property bool allAppsMode: false
    property bool stateDirectoryReady: false
    property string activeOutput: ""
    property string query: ""
    property var applications: []
    property var filteredApplications: []
    property var defaultPinnedIds: []
    property var pinnedIds: []
    property var recentIds: []
    property var pinnedApplications: []
    property var recentApplications: []

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

    function rebuildSelections() {
        var pinned = [];
        var recent = [];

        for (var i = 0; i < pinnedIds.length; ++i) {
            var pinnedEntry = DesktopEntries.byId(pinnedIds[i]);
            if (pinnedEntry && !pinnedEntry.noDisplay) {
                pinned.push(pinnedEntry);
            }
        }

        for (var j = 0; j < recentIds.length; ++j) {
            var recentEntry = DesktopEntries.byId(recentIds[j]);
            if (recentEntry && !recentEntry.noDisplay) {
                recent.push(recentEntry);
            }
        }

        pinnedApplications = pinned;
        recentApplications = recent;
    }

    function loadDefaults() {
        try {
            var data = JSON.parse(defaultsFile.text());
            defaultPinnedIds = Array.isArray(data.pinned) ? data.pinned : [];
        } catch (error) {
            defaultPinnedIds = [];
        }
    }

    function loadState() {
        var state = null;
        try {
            state = JSON.parse(stateFile.text());
        } catch (error) {
            state = null;
        }

        if (state && state.version === 1 && Array.isArray(state.pinned)) {
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
            "version": 1,
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
        // Show on the last known screen immediately; refresh the focused
        // output asynchronously so the first frame is never blocked.
        if (!root.activeOutput && Quickshell.screens.length > 0) {
            root.activeOutput = Quickshell.screens[0].name;
        }
        allAppsMode = false;
        query = "";
        menuOpen = true;
        requestFocusedOutput();
    }

    function hideMenu() {
        if (!menuOpen) {
            return;
        }
        menuOpen = false;
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

    function lockSession() {
        hideMenu();
        Quickshell.execDetached(["loginctl", "lock-session"]);
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
            // Keep the window object alive for instant animation. Its input
            // region is explicitly emptied while the menu is hidden.
            visible: true
            color: "transparent"
            focusable: root.menuOpen && (root.activeOutput === "" || modelData.name === root.activeOutput)
            aboveWindows: true

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            // Keep the layer surface ready so opening does not wait for a
            // compositor remap. The mask limits pointer input to the card.
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.menuOpen && (root.activeOutput === "" || modelData.name === root.activeOutput) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "win11-start-menu"
            mask: Region {
                item: root.menuVisible ? menuCard : null
            }

            onFocusableChanged: {
                if (focusable) {
                    Qt.callLater(function () {
                        searchField.forceActiveFocus();
                    });
                }
            }

            Item {
                id: panelContent
                anchors.fill: parent
                focus: panel.visible

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Escape) {
                        root.hideMenu();
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
                    width: Math.min(960, parent.width - 48)
                    height: Math.min(760, parent.height - 72)
                    radius: 18
                    color: root.cardColor
                    border.width: 1
                    border.color: root.cardBorderColor
                    opacity: root.menuOpen ? 1 : 0
                    scale: root.menuOpen ? 1 : 0.96
                    transformOrigin: Item.Bottom

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutBack
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: function (mouse) {
                            mouse.accepted = true;
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 28
                        spacing: 16

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: root.allAppsMode ? "All apps" : "Pinned"
                                color: root.primaryTextColor
                                font.pixelSize: 23
                                font.weight: Font.DemiBold
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                visible: !root.allAppsMode
                                Layout.preferredWidth: 108
                                Layout.preferredHeight: 34
                                radius: 9
                                color: allAppsMouse.containsMouse ? root.surfaceHoverColor : root.surfaceColor

                                Text {
                                    anchors.centerIn: parent
                                    text: "All apps  >"
                                    color: root.secondaryTextColor
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: allAppsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.allAppsMode = true
                                }
                            }

                            Rectangle {
                                visible: root.allAppsMode
                                Layout.preferredWidth: 108
                                Layout.preferredHeight: 34
                                radius: 9
                                color: backMouse.containsMouse ? root.surfaceHoverColor : root.surfaceColor

                                Text {
                                    anchors.centerIn: parent
                                    text: "<  Back"
                                    color: root.secondaryTextColor
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: backMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.allAppsMode = false
                                }
                            }
                        }

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            placeholderText: "Search apps, settings, and files"
                            text: root.query
                            color: root.primaryTextColor
                            placeholderTextColor: root.mutedTextColor
                            font.pixelSize: 15
                            selectByMouse: true

                            background: Rectangle {
                                radius: 10
                                color: root.inputColor
                                border.width: searchField.activeFocus ? 2 : 1
                                border.color: searchField.activeFocus ? root.inputFocusColor : root.inputBorderColor
                            }

                            onTextChanged: {
                                root.query = text;
                                root.applyFilter();
                                if (text.length > 0) {
                                    root.allAppsMode = true;
                                }
                            }
                        }

                        StackLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            currentIndex: root.allAppsMode ? 1 : 0

                            Item {
                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    GridLayout {
                                        id: pinnedGrid
                                        Layout.fillWidth: true
                                        columns: 6
                                        rowSpacing: 6
                                        columnSpacing: 8

                                        Repeater {
                                            id: pinnedRepeater
                                            model: root.pinnedApplications

                                            delegate: Item {
                                                required property var modelData
                                                required property int index
                                                property var app: modelData
                                                property int tileIndex: index
                                                Layout.preferredWidth: 124
                                                Layout.preferredHeight: 104
                                                Layout.fillWidth: true
                                                focus: true
                                                activeFocusOnTab: true

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 10
                                                    color: tileMouse.containsMouse || parent.activeFocus ? root.itemHoverColor : "transparent"
                                                }

                                                Column {
                                                    anchors.fill: parent
                                                    anchors.margins: 7
                                                    spacing: 5

                                                    Image {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        width: 48
                                                        height: 48
                                                        source: app ? Quickshell.iconPath(app.icon, "application-x-executable") : ""
                                                        sourceSize.width: 48
                                                        sourceSize.height: 48
                                                        smooth: true
                                                    }

                                                    Text {
                                                        width: parent.width
                                                        text: app ? app.name : ""
                                                        color: root.primaryTextColor
                                                        font.pixelSize: 12
                                                        horizontalAlignment: Text.AlignHCenter
                                                        elide: Text.ElideRight
                                                    }
                                                }

                                                MouseArea {
                                                    id: tileMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                    onClicked: function (mouse) {
                                                        if (mouse.button === Qt.RightButton) {
                                                            root.togglePin(app.id);
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

                                                    var targetIndex = tileIndex;
                                                    if (event.key === Qt.Key_Left) {
                                                        targetIndex -= 1;
                                                    } else if (event.key === Qt.Key_Right) {
                                                        targetIndex += 1;
                                                    } else if (event.key === Qt.Key_Up) {
                                                        targetIndex -= 6;
                                                    } else if (event.key === Qt.Key_Down) {
                                                        targetIndex += 6;
                                                    } else {
                                                        return;
                                                    }

                                                    if (targetIndex >= 0 && targetIndex < pinnedRepeater.count) {
                                                        var target = pinnedRepeater.itemAt(targetIndex);
                                                        if (target) {
                                                            target.forceActiveFocus();
                                                        }
                                                        event.accepted = true;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Label {
                                        visible: root.pinnedApplications.length === 0
                                        text: "No pinned apps"
                                        color: root.mutedTextColor
                                        font.pixelSize: 13
                                    }

                                    Label {
                                        text: "Recommended"
                                        color: root.primaryTextColor
                                        font.pixelSize: 18
                                        font.weight: Font.DemiBold
                                        Layout.topMargin: 7
                                    }

                                    GridLayout {
                                        id: recommendedGrid
                                        Layout.fillWidth: true
                                        columns: 2
                                        columnSpacing: 12
                                        rowSpacing: 7

                                        Repeater {
                                            model: root.recentApplications

                                            delegate: Item {
                                                required property var modelData
                                                property var app: modelData
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 62

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 9
                                                    color: recentMouse.containsMouse ? root.itemHoverColor : root.recentColor
                                                }

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 8
                                                    spacing: 10

                                                    Image {
                                                        Layout.preferredWidth: 38
                                                        Layout.preferredHeight: 38
                                                        source: app ? Quickshell.iconPath(app.icon, "application-x-executable") : ""
                                                        sourceSize.width: 38
                                                        sourceSize.height: 38
                                                        smooth: true
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 2
                                                        Label {
                                                            text: app ? app.name : ""
                                                            color: root.primaryTextColor
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }
                                                        Label {
                                                            text: "Recently used"
                                                            color: root.mutedTextColor
                                                            font.pixelSize: 11
                                                        }
                                                    }
                                                }

                                                MouseArea {
                                                    id: recentMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: root.runApplication(app)
                                                }
                                            }
                                        }
                                    }

                                    Label {
                                        visible: root.recentApplications.length === 0
                                        text: "No recent apps"
                                        color: root.mutedTextColor
                                        font.pixelSize: 13
                                    }
                                }
                            }

                            Item {
                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 8

                                    Label {
                                        text: root.filteredApplications.length + " apps"
                                        color: root.mutedTextColor
                                        font.pixelSize: 12
                                    }

                                    ListView {
                                        id: allAppsList
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        model: root.filteredApplications
                                        spacing: 4
                                        activeFocusOnTab: true

                                        delegate: Item {
                                            required property var modelData
                                            property var app: modelData
                                            width: allAppsList.width
                                            height: 58
                                            focus: true
                                            activeFocusOnTab: true

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 9
                                                color: allAppMouse.containsMouse || parent.activeFocus ? root.itemHoverColor : "transparent"
                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 12

                                                Image {
                                                    Layout.preferredWidth: 36
                                                    Layout.preferredHeight: 36
                                                    source: app ? Quickshell.iconPath(app.icon, "application-x-executable") : ""
                                                    sourceSize.width: 36
                                                    sourceSize.height: 36
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
                                            }

                                            MouseArea {
                                                id: allAppMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: function (mouse) {
                                                    if (mouse.button === Qt.RightButton) {
                                                        root.togglePin(app.id);
                                                    } else {
                                                        root.runApplication(app);
                                                    }
                                                }
                                            }

                                            Keys.onReturnPressed: root.runApplication(app)
                                            Keys.onSpacePressed: root.runApplication(app)
                                            Keys.onPressed: function (event) {
                                                if (event.key !== Qt.Key_Up && event.key !== Qt.Key_Down) {
                                                    return;
                                                }

                                                var view = ListView.view;
                                                var delta = event.key === Qt.Key_Down ? 1 : -1;
                                                var targetIndex = Math.max(0, Math.min(view.count - 1, view.currentIndex + delta));
                                                view.currentIndex = targetIndex;
                                                view.positionViewAtIndex(targetIndex, ListView.Contain);
                                                Qt.callLater(function () {
                                                    if (view.currentItem) {
                                                        view.currentItem.forceActiveFocus();
                                                    }
                                                });
                                                event.accepted = true;
                                            }
                                        }

                                        ScrollBar.vertical: ScrollBar { }
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
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: 17
                                color: root.avatarColor
                                Text {
                                    anchors.centerIn: parent
                                    text: root.userName.slice(0, 1).toUpperCase()
                                    color: root.avatarTextColor
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                }
                            }

                            Label {
                                text: root.userName
                                color: root.primaryTextColor
                                font.pixelSize: 14
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: 82
                                Layout.preferredHeight: 34
                                radius: 9
                                color: lockMouse.containsMouse ? root.surfaceHoverColor : root.surfaceColor
                                Text {
                                    anchors.centerIn: parent
                                    text: "Lock"
                                    color: root.secondaryTextColor
                                    font.pixelSize: 13
                                }
                                MouseArea {
                                    id: lockMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.lockSession()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
