#include "trainconnection.h"

#include <QQmlApplicationEngine>
#include <QDateTime>
#include <QDebug>
#include <QString>
#include <QDesktopServices>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStringList>
#include <QStandardPaths>
#include <QUrl>

#include <iostream>
#include <vector>

TrainConnection::TrainConnection(QObject *parent)
    : QObject(parent)
    , m_start()
    , m_destination()
{
    m_departureDate = QDate::currentDate();
    m_departureTime = QTime::currentTime();
    
    m_manager.setAllowInsecureBackends(false);
    m_manager.setBackendsEnabledByDefault(false);
    
    qmlRegisterSingletonInstance<KPublicTransport::Manager>("org.puremaps", 1, 0, "Manager", &m_manager);
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
    req.setBackendIds(m_manager.enabledBackends());

    std::cout << "IsValid: " << req.isValid() << std::endl;

    const QStringList backendIDs = req.backendIds();
    for (int i = 0; i < backendIDs.size(); ++i)
        std::cout << "BackendID: " << backendIDs.at(i).toLocal8Bit().constData() << std::endl;
    
    // std::vector<QJsonObject> jsonObjects;
    // KPublicTransport::LocationReply *reply = manager.queryLocation(req);

    // std::cout << "ErrorString: " << reply->errorString().toStdString() << std::endl;

    // const std::vector<KPublicTransport::Location> &resultsArray = reply->result();

    // std::cout << "ResultArray Size: " << resultsArray.size() << std::endl;

    // for (auto result: resultsArray) {
    //     jsonObjects.push_back(KPublicTransport::Location::toJson(result));
    // }

    // for (auto json: jsonObjects) {
    //     std::cout << "Json" << std::endl;
    //     QStringList strList = json.keys();
    //     for (int i = 0; i < strList.size(); ++i)
    //         std::cout << strList.at(i).toLocal8Bit().constData() << std::endl;
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

void TrainConnection::setBackendEnable(const QString &identifier, bool enabeld)
{
    m_manager.setBackendEnabled(identifier, enabeld);
}