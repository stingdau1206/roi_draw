import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    visible: true
    visibility: Window.Maximized

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        // Hàng 1: Input và các nút điều khiển
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            TextField {
                id: rtspInput
                Layout.fillWidth: true
                placeholderText: "Nhập link RTSP hoặc API snapshot tại đây"
                text: "rtsp://admin:Admin123@172.22.156.91:554/Streaming/Channels/101" // Link mẫu để test
            }

            Button {
                id: playButton
                text: "Play"
                onClicked: {
                    imageOutput.visible = false
                    videoOutput.visible = true
                    mediaPlayer.source = rtspInput.text
                    mediaPlayer.play()
                }
            }

            Button {
                id: captureButton
                text: "Capture"
                onClicked: {
                    mediaPlayer.stop()
                    videoOutput.visible = false
                    imageOutput.source = rtspInput.text
                    imageOutput.visible = true
                }
            }
        }

        // Vùng chính: Video và bảng tọa độ
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Vùng hiển thị video và vẽ ROI
            Item {
                id: videoContainer
                Layout.preferredWidth: parseInt(sourceWidthInput.text);
                Layout.preferredHeight: parseInt(sourceHeightInput.text);
                clip: true

                property bool isDrawingMode: false
                property point startDragPos: Qt.point(0, 0)

                MediaPlayer {
                    id: mediaPlayer
                    autoPlay: false
                }

                VideoOutput {
                    id: videoOutput
                    anchors.fill: parent
                    source: mediaPlayer
                }

                Image {
                    id: imageOutput
                    anchors.fill: parent
                    source: ""
                    visible: false
                    fillMode: Image.PreserveAspectFit
                }

                // MouseArea để hiển thị tọa độ con trỏ
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: (mouse) => {
                        coordinateLabel.text = "X: " + mouse.x.toFixed(0) + ", Y: " + mouse.y.toFixed(0)
                    }
                    onExited: {
                        coordinateLabel.text = ""
                    }
                }

                Rectangle {
                    id: roiRect
                    x: 0
                    y: 0
                    width: 0
                    height: 0
                    color: "transparent"
                    border.color: "limegreen"
                    border.width: 2
                    visible: false
                    property point startDragPos: Qt.point(0, 0)

                    MouseArea {
                        anchors.fill: parent
                        drag.target: parent
                        cursorShape: Qt.SizeAllCursor
                        enabled: parent.visible && !videoContainer.isDrawingMode

                        onPressed: (mouse) => {
                            parent.startDragPos = Qt.point(mouse.x, mouse.y)
                        }

                        onPositionChanged: (mouse) => {
                            if (!pressed) return;
                            var dx = mouse.x - parent.startDragPos.x
                            var dy = mouse.y - parent.startDragPos.y
                            parent.x += dx
                            parent.y += dy
                        }
                    }
                }

                // MouseArea để vẽ ROI bằng cách kéo thả
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    enabled: videoContainer.isDrawingMode
                    cursorShape: videoContainer.isDrawingMode ? Qt.CrossCursor : Qt.ArrowCursor

                    onPressed: (mouse) => {
                        videoContainer.startDragPos = Qt.point(mouse.x, mouse.y)
                        roiRect.x = mouse.x
                        roiRect.y = mouse.y
                        roiRect.width = 0
                        roiRect.height = 0
                        roiRect.visible = true
                    }

                    onPositionChanged: (mouse) => {
                        if (!pressed) return;
                        var newX = Math.min(mouse.x, videoContainer.startDragPos.x)
                        var newY = Math.min(mouse.y, videoContainer.startDragPos.y)
                        var newWidth = Math.abs(mouse.x - videoContainer.startDragPos.x)
                        var newHeight = Math.abs(mouse.y - videoContainer.startDragPos.y)
                        roiRect.x = newX
                        roiRect.y = newY
                        roiRect.width = newWidth
                        roiRect.height = newHeight
                    }

                    onReleased: (mouse) => {
                        videoContainer.isDrawingMode = false
                        createRoiButton.enabled = true
                    }
                }
            }

            // Vùng hiển thị tọa độ ROI và nút Copy
            ColumnLayout {
                Layout.fillHeight: true
                Layout.preferredWidth: 240 // Tăng chiều rộng một chút
                spacing: 5

                TextArea {
                    id: coordinatesDisplay
                    Layout.fillWidth: true
                    Layout.fillHeight: true // Để TextArea chiếm hết không gian còn lại
                    readOnly: true
                    font.family: "Courier"
                    font.pointSize: 10
                    wrapMode: "NoWrap"
                    selectByMouse: true // Đảm bảo có thể chọn text bằng chuột
                    text: ""
                }

                Button {
                    text: "Copy All"
                    Layout.fillWidth: true
                    enabled: coordinatesDisplay.text.length > 0
                    onClicked: {
                        coordinatesDisplay.selectAll()
                        coordinatesDisplay.copy()
                        statusLabel.text = "Đã sao chép tọa độ vào clipboard."
                    }
                }
            }
        }

        // Hàng 2: Các nút điều khiển ROI và kích thước
        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            columns: 6
            rowSpacing: 5
            columnSpacing: 10

            // Dòng 1: Kích thước nguồn và các nút điều khiển chính
            Label { text: "Source Width:"; verticalAlignment: Text.AlignVCenter }
            TextField {
                id: sourceWidthInput
                text: "1280"
                Layout.preferredWidth: 80
                validator: IntValidator { bottom: 1 }
            }

            Button {
                id: createRoiButton
                text: "Create ROI (Drag)"
                onClicked: {
                    videoContainer.isDrawingMode = true
                    createRoiButton.enabled = false
                }
            }
            Button {
                id: showCoordinatesButton
                text: "Show Coordinates"
                enabled: roiRect.visible && roiRect.width > 0 && roiRect.height > 0
                onClicked: {
                    var sourceWidth = parseInt(sourceWidthInput.text);
                    var sourceHeight = parseInt(sourceHeightInput.text);

                    if (isNaN(sourceWidth) || isNaN(sourceHeight) || sourceWidth <= 0 || sourceHeight <= 0) {
                        statusLabel.text = "Lỗi: Kích thước nguồn không hợp lệ.";
                        return;
                    }

                    var topLeft = [roiRect.x / sourceWidth, roiRect.y / sourceHeight];
                    var topRight = [(roiRect.x + roiRect.width) / sourceWidth, roiRect.y / sourceHeight];
                    var bottomRight = [(roiRect.x + roiRect.width) / sourceWidth, (roiRect.y + roiRect.height) / sourceHeight];
                    var bottomLeft = [roiRect.x / sourceWidth, (roiRect.y + roiRect.height) / sourceHeight];

                    var roiData = {
                        "rois": [
                            topLeft,
                            topRight,
                            bottomRight,
                            bottomLeft
                        ]
                    };

                    var jsonString = JSON.stringify(roiData, null, 4);

                    coordinatesDisplay.text = jsonString;
                    statusLabel.text = "Đã hiển thị tọa độ ROI dưới dạng JSON.";
                }
            }
            Label { text: "" } // Spacer
            Label { text: "" } // Spacer


            Label { text: "Source Height:"; verticalAlignment: Text.AlignVCenter }
            TextField {
                id: sourceHeightInput
                text: "720"
                Layout.preferredWidth: 80
                validator: IntValidator { bottom: 1 }
            }

            Button {
                id: clearButton
                text: "Clear ROI"
                enabled: roiRect.visible
                onClicked: {
                    roiRect.visible = false
                    roiRect.width = 0
                    roiRect.height = 0
                    videoContainer.isDrawingMode = false
                    createRoiButton.enabled = true
                    coordinatesDisplay.text = ""
                    roiXInput.text = ""
                    roiYInput.text = ""
                    roiWInput.text = ""
                    roiHInput.text = ""
                    statusLabel.text = "Đã xóa ROI."
                }
            }
             Label { text: "" } // Spacer
             Label { text: "" } // Spacer
             Label { text: "" } // Spacer


            // Dòng 2: Nhập tọa độ thủ công
            Label { text: "X:" }
            TextField { id: roiXInput; placeholderText: "x"; validator: IntValidator{} }

            Label { text: "Y:" }
            TextField { id: roiYInput; placeholderText: "y"; validator: IntValidator{} }

            Label { text: "W:" }
            TextField { id: roiWInput; placeholderText: "width"; validator: IntValidator{ bottom: 1 } }

            Label { text: "H:" }
            TextField { id: roiHInput; placeholderText: "height"; validator: IntValidator{ bottom: 1 } }

            Button {
                text: "Draw from Input"
                Layout.columnSpan: 2 // Nút này chiếm 2 cột
                onClicked: {
                    var x = parseInt(roiXInput.text)
                    var y = parseInt(roiYInput.text)
                    var w = parseInt(roiWInput.text)
                    var h = parseInt(roiHInput.text)

                    if (isNaN(x) || isNaN(y) || isNaN(w) || isNaN(h) || w <= 0 || h <= 0) {
                        statusLabel.text = "Lỗi: Giá trị nhập vào không hợp lệ."
                        return
                    }

                    var maxWidth = videoContainer.width;
                    var maxHeight = videoContainer.height;
                    roiRect.x = Math.max(0, Math.min(x, maxWidth));
                    roiRect.y = Math.max(0, Math.min(y, maxHeight));
                    roiRect.width = Math.min(w, maxWidth - roiRect.x);
                    roiRect.height = Math.min(h, maxHeight - roiRect.y);

                    roiRect.visible = true
                    createRoiButton.enabled = true
                    videoContainer.isDrawingMode = false
                    statusLabel.text = "Đã vẽ ROI từ giá trị nhập vào."
                }
            }
        }

        // Hàng 3: Label để hiển thị trạng thái và tọa độ
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Label {
                id: statusLabel
                text: "Chào mừng!"
            }
            Label {
                id: coordinateLabel
                font.bold: true
                Layout.leftMargin: 20
                text: ""
            }
        }
    }
}
