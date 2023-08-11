/*
 * This file is part of Pure Maps.
 *
 * SPDX-FileCopyrightText: 2023 lhaenschke https://github.com/lhaenschke
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 */

#include "trainconnection.h"

#include <QQmlApplicationEngine>
#include <QDateTime>
#include <QDebug>
#include <QDesktopServices>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QStringList>
#include <QStandardPaths>
#include <QUrl>

#include <iostream>
#include <vector>

#include<thread> // for std::thread
using std::this_thread::sleep_for; 
using std::chrono::seconds;

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

void TrainConnection::setBackendEnable(const QString &identifier, bool enabeld)
{
    m_manager.setBackendEnabled(identifier, enabeld);
}

void TrainConnection::setStartLocation(float lat, float lon, const QString &name)
{
    KPublicTransport::LocationRequest req;
    req.setBackendIds(m_manager.enabledBackends());
    req.setCoordinate(lat, lon);
    req.setName(name);

    for (auto result: m_manager.queryLocation(req)->result()) {
        setStart(result);
        break;
    }
}

QString TrainConnection::convertLocationToJsonString(const KPublicTransport::Location &location)
{
    return QJsonDocument(KPublicTransport::Location::toJson(location)).toJson(QJsonDocument::Compact);
}

KPublicTransport::Location TrainConnection::convertJsonStringToLocation(const QString &jsonString)
{
    return KPublicTransport::Location::fromJson(QJsonDocument::fromJson(jsonString.toUtf8()).object());
}

// QString TrainConnection::getJsonLocationFromCoorAndName(float lat, float lon, const QString &name)
// {
//     KPublicTransport::LocationRequest req;
//     req.setBackendIds(m_manager.enabledBackends());
//     req.setCoordinate(lat, lon);
//     req.setName(name);

//     for (auto result: m_manager.queryLocation(req)->result()) {
//         return convertLocationToJsonString(result);
//     }
//     return QString("{\"name\":\"Default\"}");
// }

QString getLocationJsonFromCoorAndName(float lat, float lon)
{
    KPublicTransport::LocationRequest req;
    req.setBackendIds(m_manager.enabledBackends());
    req.setCoordinate(lat, lon);

    for (auto result: m_manager.queryLocation(req)->result()) {
        return convertLocationToJsonString(result);
    }
    return QString("{\"name\":\"Default\"}");
}

// auto f()
// { 
//     std::cout << "        Task started ...\n";
//     sleep_for(seconds(60));
//     std::cout << "        Task done!\n";
// }

// QVariant TrainConnection::getJourneyBetweenLocations(const QString &fromLocationJson, const QString &toLocationJson)
// {
//     KPublicTransport::JourneyRequest req;
//     req.setBackendIds(m_manager.enabledBackends());

//     for (auto id: req.backendIds()) {
//         std::cout << "Id: " << id.toStdString() << std::endl;
//     }

//     // req.setFrom(m_start);
//     // req.setTo(m_destination);
//     req.setFrom(convertJsonStringToLocation(fromLocationJson));
//     req.setTo(convertJsonStringToLocation(toLocationJson));

//     // QDateTime depTime(QDate::currentDate(), QTime::currentTime());
//     QDateTime depTime(m_departureDate, m_departureTime);
//     req.setDepartureTime(depTime);

//     std::cout << "Start: " << fromLocationJson.toStdString() << std::endl;
//     std::cout << "Desti: " << toLocationJson.toStdString() << std::endl;
//     std::cout << "Req is Valid: " << req.isValid() << std::endl;
    
//     KPublicTransport::JourneyReply *reply = m_manager.queryJourney(req);
//     const std::vector<KPublicTransport::Journey> &test = reply->result();
//     std::cout << "Anzahl: " << test.size() << std::endl;

//     for (auto result: test) {
//         std::cout << "Gefunden" << std::endl;
//     }

    // QVector<KPublicTransport::Journey> journeys;
    // return QVariant::fromValue(journeys);

//     // KPublicTransport::JourneyRequest req = KPublicTransport::JourneyRequest(m_start, m_destination);
//     // req.setFrom(m_start);
//     // req.setTo(m_destination);

//     // QDateTime depTime(m_departureDate, m_departureTime);
//     // req.setDepartureTime(depTime);

//     // std::cout << "IsValid: " << queryModel.isValid() << std::endl;

//     // KPublicTransport::JourneyQueryModel queryModel;
//     // queryModel.setManager(&m_manager);
//     // queryModel.setRequest(req);
    
//     // std::thread t(f);
//     // std::cout << "Test1" << std::endl;
//     // t.join();
//     // std::cout << "Test2" << std::endl;

//     // std::cout << "Next: " << queryModel.canQueryNext() << std::endl;
//     // std::cout << "Prev: " << queryModel.canQueryPrevious() << std::endl;

//     // std::cout << "IdLoading: " << queryModel.isLoading() << std::endl;
//     // std::cout << "Error: " << queryModel.errorMessage().toStdString() << std::endl;

//     // for (auto result: queryModel.journeys()) {
//     //     std::cout << "Test" << std::endl;
//     // }

//     // return QVariant::fromValue(journeys);
// }

QVariant TrainConnection::getJourneyBetweenLocations(float lon1, float lat1, float lon2, float lat2)
{
    QVector<KPublicTransport::Journey> journeys;

    // Location 1
    KPublicTransport::Location location1 = convertJsonStringToLocation(QString("{\"name\":\"Default\"}"));
    for (int i = 0; (location1.name().toStdString().compare("Default") == 0) && i < 3; i++) {
        location1 = convertJsonStringToLocation(getLocationJsonFromCoorAndName(lat1, lon1));
    }

    std::cout << "Location1-Json: " << convertLocationToJsonString(location1).toStdString() << std::endl;

    if (location1.name().toStdString().compare("Default") == 0) {
        // Early return -> No Location was found
        return QVariant::fromValue(journeys);    
    }

    // Location 2
    KPublicTransport::Location location2 = convertJsonStringToLocation(QString("{\"name\":\"Default\"}"));
    for (int i = 0; (location2.name().toStdString().compare("Default") == 0) && i < 3; i++) {
        location2 = convertJsonStringToLocation(getLocationJsonFromCoorAndName(lat2, lon2));
    }

    std::cout << "Location2-Json: " << convertLocationToJsonString(location2).toStdString() << std::endl;

    if (location2.name().toStdString().compare("Default") == 0) {
        // Early return -> No Location was found
        return QVariant::fromValue(journeys);    
    }

    

    
    return QVariant::fromValue(journeys);
}


KPublicTransport::JourneyRequest TrainConnection::createJourneyRequest()
{
    KPublicTransport::JourneyRequest req;
    req.setFrom(m_start);
    req.setTo(m_destination);

    QDateTime depTime(m_departureDate, m_departureTime);
    req.setDepartureTime(depTime);

    return req;
}

KPublicTransport::LocationRequest TrainConnection::createLocationRequest(const QString &name)
{
    KPublicTransport::LocationRequest req;
    req.setName(name);
    
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