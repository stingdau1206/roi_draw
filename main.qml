import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15

ApplicationWindow {
    id: root
    width: 1500
    height: 900
    visible: true
    title: "RTSP Stream and ROI Tool"

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        // Hàng 1: Input và nút Play
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            TextField {
                id: rtspInput
                Layout.fillWidth: true
                placeholderText: "Nhập link RTSP tại đây (ví dụ: rtsp://...)"
                text: "rtsp://admin:Admin123@172.22.156.91:554/Streaming/Channels/101" // Link mẫu để test
            }

            Button {
                id: playButton
                text: "Play"
                onClicked: {
                    mediaPlayer.source = rtspInput.text
                    mediaPlayer.play()
                }
            }
        }

        // Vùng hiển thị video và vẽ ROI
        Item {
            id: videoContainer
            width: 1280
            height: 720
            Layout.fillHeight: true
            clip: true // Quan trọng: để ROI không bị vẽ ra ngoài vùng này

            // Biến trạng thái để quản lý việc vẽ ROI, tham chiếu theo videoContainer
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

            // Hình chữ nhật để hiển thị ROI
            Rectangle {
                id: roiRect
                x: 0
                y: 0
                width: 0
                height: 0
                color: "transparent"
                border.color: "limegreen" // Màu xanh lá cây
                border.width: 2
                visible: false // Ban đầu ẩn đi
            }

            // Vùng tương tác chuột để vẽ ROI
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                enabled: videoContainer.isDrawingMode // Chỉ bật khi ở chế độ vẽ
                cursorShape: videoContainer.isDrawingMode ? Qt.CrossCursor : Qt.ArrowCursor

                onPressed: (mouse) => {
                    // Bắt đầu vẽ: lưu vị trí, làm cho hình chữ nhật hiển thị
                    videoContainer.startDragPos = Qt.point(mouse.x, mouse.y)
                    roiRect.x = mouse.x
                    roiRect.y = mouse.y
                    roiRect.width = 0
                    roiRect.height = 0
                    roiRect.visible = true
                }

                onPositionChanged: (mouse) => {
                    if (!pressed) return; // Chỉ xử lý khi đang nhấn chuột

                    // Cập nhật kích thước và vị trí của ROI khi kéo chuột
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
                    // Kết thúc vẽ, tắt chế độ vẽ để tránh vẽ nhầm
                    videoContainer.isDrawingMode = false
                    createRoiButton.enabled = true // Bật lại nút "Create ROI"
                }
            }
        }

        // Hàng 2: Các nút điều khiển ROI
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            spacing: 20

            Button {
                id: createRoiButton
                text: "Create ROI"
                onClicked: {
                    // Bật chế độ vẽ và vô hiệu hóa nút này để tránh click lại
                    videoContainer.isDrawingMode = true
                    createRoiButton.enabled = false
                }
            }

            Button {
                id: saveButton
                text: "Save ROI"
                enabled: roiRect.visible && roiRect.width > 0 && roiRect.height > 0
                onClicked: {
                    // --- THAY ĐỔI QUAN TRỌNG TẠI ĐÂY ---
                    // Gọi hàm C++ và truyền thêm kích thước của videoOutput
                    // để chuẩn hóa tọa độ.
                    roiManager.saveRoiToFile(
                        roiRect.x,
                        roiRect.y,
                        roiRect.width,
                        roiRect.height,
                        videoOutput.width,  // Chiều rộng của vùng hiển thị video
                        videoOutput.height  // Chiều cao của vùng hiển thị video
                    )
                    statusLabel.text = "Đã lưu ROI vào file 'roi_coordinates.json' trên Desktop."
                }
            }

            Button {
                id: clearButton
                text: "Clear ROI"
                enabled: roiRect.visible
                onClicked: {
                    // Ẩn hình chữ nhật và reset trạng thái
                    roiRect.visible = false
                    roiRect.width = 0
                    roiRect.height = 0
                    videoContainer.isDrawingMode = false
                    createRoiButton.enabled = true
                    statusLabel.text = "Đã xóa ROI."
                }
            }
        }

        // Label để hiển thị trạng thái
        Label {
            id: statusLabel
            Layout.alignment: Qt.AlignHCenter
            text: "Chào mừng!"
        }
    }
}