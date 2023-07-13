#include "trainconnections.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDesktopServices>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QUrl>

TrainConnections::TrainConnections(QObject *parent)
    : QObject(parent)
    , m_start()
    , m_destination()
{
    m_departureDate = QDate::currentDate();
    m_departureTime = QTime::currentTime();
}

void TrainConnections::test()
{
    qWarning() << "Hello from CPP!!";
}

void TrainConnections::setStart(const KPublicTransport::Location &start)
{
    m_start = start;
    Q_EMIT startChanged();
}

KPublicTransport::Location TrainConnections::start() const
{
    return m_start;
}

void TrainConnections::setDestination(const KPublicTransport::Location &destination)
{
    m_destination = destination;
    Q_EMIT destinationChanged();
}

KPublicTransport::Location TrainConnections::destination() const
{
    return m_destination;
}

KPublicTransport::JourneyRequest TrainConnections::createJourneyRequest()
{
    KPublicTransport::JourneyRequest req;
    req.setFrom(m_start);
    req.setTo(m_destination);
    req.setDownloadAssets(true);

    QDateTime depTime(m_departureDate, m_departureTime);
    req.setDepartureTime(depTime);

    return req;
}

QDate TrainConnections::departureDate() const
{
    return m_departureDate;
}

void TrainConnections::setDepartureDate(const QDate &date)
{
    if (m_departureDate != date) {
        m_departureDate = date;
        Q_EMIT departureDateChanged();
    }
}

QTime TrainConnections::departureTime() const
{
    return m_departureTime;
}

void TrainConnections::setDepartureTime(const QTime &time)
{
    if (m_departureTime != time) {
        m_departureTime = time;
        Q_EMIT departureTimeChanged();
    }
}

KPublicTransport::LocationRequest TrainConnections::createLocationRequest(const QString &name)
{
    KPublicTransport::LocationRequest req;
    req.setName(name);

    return req;
}

KPublicTransport::StopoverRequest TrainConnections::createStopoverRequest()
{
    KPublicTransport::StopoverRequest req;
    req.setStop(m_start);
    QDateTime depTime(m_departureDate, m_departureTime);
    req.setDateTime(depTime);
    return req;
}

void TrainConnections::showOnMap(KPublicTransport::Location location)
{
    if (!location.hasCoordinate())
        return;
    QUrl url(QLatin1String("geo:") + QString::number(location.latitude()) + QLatin1Char(',') + QString::number(location.longitude()));
    QDesktopServices::openUrl(url);
}
