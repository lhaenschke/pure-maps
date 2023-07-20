

#include "trainconnection.h"

#include <QQmlApplicationEngine>
#include <QDateTime>
#include <QDebug>
#include <QDesktopServices>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QUrl>

#include <iostream>

TrainConnection::TrainConnection(QObject *parent)
    : QObject(parent)
    , m_start()
    , m_destination()
{
    m_departureDate = QDate::currentDate();
    m_departureTime = QTime::currentTime();
    
    manager.setAllowInsecureBackends(true);
    manager.setBackendsEnabledByDefault(false);

    qmlRegisterSingletonInstance<KPublicTransport::Manager>("org.puremaps", 1, 0, "Manager", &manager);
}

void TrainConnection::setStart(const KPublicTransport::Location &start)
{
    m_start = start;
    Q_EMIT startChanged();
}

KPublicTransport::Location TrainConnection::start() const
{
    return m_start;
}

void TrainConnection::setDestination(const KPublicTransport::Location &destination)
{
    m_destination = destination;
    Q_EMIT destinationChanged();
}

KPublicTransport::Location TrainConnection::destination() const
{
    return m_destination;
}

KPublicTransport::JourneyRequest TrainConnection::createJourneyRequest()
{
    KPublicTransport::JourneyRequest req;
    req.setFrom(m_start);
    req.setTo(m_destination);
    req.setDownloadAssets(true);

    QDateTime depTime(m_departureDate, m_departureTime);
    req.setDepartureTime(depTime);

    return req;
}

QDate TrainConnection::departureDate() const
{
    return m_departureDate;
}

void TrainConnection::setDepartureDate(const QDate &date)
{
    if (m_departureDate != date) {
        m_departureDate = date;
        Q_EMIT departureDateChanged();
    }
}

QTime TrainConnection::departureTime() const
{
    return m_departureTime;
}

void TrainConnection::setDepartureTime(const QTime &time)
{
    if (m_departureTime != time) {
        m_departureTime = time;
        Q_EMIT departureTimeChanged();
    }
}

KPublicTransport::LocationRequest TrainConnection::createLocationRequest(const QString &name)
{
    KPublicTransport::LocationRequest req;
    req.setName(name);

    std::vector<QJsonObject> jsonObjects;
    // std::vector<KPublicTransport::Location> resultArray = manager.queryLocation(&req);
    KPublicTransport::LocationReply reply = manager.queryLocation(req);

    // for (auto &result: resultArray) {
    //     jsonObjects.push_back(KPublicTransport::Location::toJson(result));
    // }

    // for (auto json: jsonObjects) {
    //     std::cout << json.keys() << "\n";
    // }

    return req;
}

KPublicTransport::StopoverRequest TrainConnection::createStopoverRequest()
{
    KPublicTransport::StopoverRequest req;
    req.setStop(m_start);
    QDateTime depTime(m_departureDate, m_departureTime);
    req.setDateTime(depTime);
    return req;
}

void TrainConnection::showOnMap(KPublicTransport::Location location)
{
    if (!location.hasCoordinate())
        return;
    QUrl url(QLatin1String("geo:") + QString::number(location.latitude()) + QLatin1Char(',') + QString::number(location.longitude()));
    QDesktopServices::openUrl(url);
}
