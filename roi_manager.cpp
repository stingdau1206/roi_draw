#include "roi_manager.h"
#include <QFile>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QImage> // Thêm include để xử lý ảnh
#include <QUrl>   // Thêm include để xử lý URL từ QML

RoiManager::RoiManager(QObject *parent) : QObject(parent)
{
}

void RoiManager::saveRoiToFile(qreal x, qreal y, qreal width, qreal height, int videoWidth, int videoHeight)
{
    // Tìm vị trí Desktop để lưu file
    QString desktopPath = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    if (desktopPath.isEmpty()) {
        qWarning() << "Không thể tìm thấy thư mục Desktop. Đang lưu vào thư mục hiện tại.";
        desktopPath = ".";
    }

    // Đổi tên file thành .json
    QString filePath = desktopPath + "/roi_coordinates.json";

    // Kiểm tra để tránh chia cho 0
    if (videoWidth <= 0 || videoHeight <= 0) {
        qWarning() << "Kích thước video không hợp lệ. Không thể chuẩn hóa tọa độ.";
        return;
    }

    // 1. Tính toán và chuẩn hóa tọa độ 4 điểm góc
    QPointF topLeft(x / videoWidth, y / videoHeight);
    QPointF topRight((x + width) / videoWidth, y / videoHeight);
    QPointF bottomRight((x + width) / videoWidth, (y + height) / videoHeight);
    QPointF bottomLeft(x / videoWidth, (y + height) / videoHeight);

    // 2. Tạo cấu trúc JSON với thứ tự điểm đã được sửa lại
    QJsonArray roisArray;
    roisArray.append(QJsonArray{topLeft.x(), topLeft.y()});         // 1. Top-Left
    roisArray.append(QJsonArray{topRight.x(), topRight.y()});       // 2. Top-Right
    roisArray.append(QJsonArray{bottomRight.x(), bottomRight.y()}); // 3. Bottom-Right
    roisArray.append(QJsonArray{bottomLeft.x(), bottomLeft.y()});   // 4. Bottom-Left

    // Tạo đối tượng JSON chính
    QJsonObject mainObject;
    mainObject["rois"] = roisArray;

    QJsonDocument jsonDoc(mainObject);

    // 3. Ghi file JSON
    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly))
    {
        // Ghi file với định dạng thụt vào để dễ đọc
        file.write(jsonDoc.toJson(QJsonDocument::Indented));
        file.close();
        qInfo() << "Đã lưu ROI JSON thành công vào:" << filePath;
    }
    else
    {
        qWarning() << "Không thể mở file để ghi:" << file.errorString();
    }
}
