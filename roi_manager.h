#ifndef ROIMANAGER_H
#define ROIMANAGER_H

#include <QObject>
#include <QPointF>
#include <QString>
#include <QVariantList>

class RoiManager : public QObject
{
    Q_OBJECT

public:
    explicit RoiManager(QObject *parent = nullptr);

public slots:
    Q_INVOKABLE void saveRoiToFile(qreal x, qreal y, qreal width, qreal height, int videoWidth, int videoHeight);

signals:
};

#endif // ROIMANAGER_H
