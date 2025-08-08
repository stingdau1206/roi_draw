#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "roi_manager.h"

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    int streamWidth = 640;
    int streamHeight = 360;

    if (argc >= 3) {
        streamWidth = QString(argv[1]).toInt();
        streamHeight = QString(argv[2]).toInt();
    }

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // 1. Tạo một instance của RoiManager
    RoiManager roiManager;

    // 2. Đăng ký instance này như một context property.
    //    Điều này cho phép QML truy cập nó bằng tên "roiManager".
    engine.rootContext()->setContextProperty("roiManager", &roiManager);
    engine.rootContext()->setContextProperty("streamWidth", streamWidth);
    engine.rootContext()->setContextProperty("streamHeight", streamHeight);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
