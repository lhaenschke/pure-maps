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

std::vector<KPublicTransport::Location> TrainConnection::getLocationsFromCoorAndName(float lat, float lon)
{
    KPublicTransport::LocationRequest req;
    req.setBackendIds(m_manager.enabledBackends());
    req.setCoordinate(lat, lon);

    std::vector<KPublicTransport::Location> locations;

    for (auto result: m_manager.queryLocation(req)->result()) {
        locations.push_back(result);
        
        if (locations.size() >= 3)
            break;

    }
    return locations;
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

//    // KPublicTransport::JourneyQueryModel queryModel;
//    // queryModel.setManager(&m_manager);
//    // queryModel.setRequest(req);
    
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
    QDateTime depTime(QDate::currentDate(), QTime::currentTime());

    // Possible Locations 1
    std::vector<KPublicTransport::Location> locations1;
    for (int i = 0; locations1.size() == 0 && i < 10; i++) {
        locations1 = getLocationsFromCoorAndName(lat1, lon1);
    }

    std::cout << "Location1 Count: " << locations1.size() << std::endl;

    if (locations1.size() == 0) {
        // Early return -> No Location was found
        return QVariant::fromValue(journeys);    
    }

    // Possible Locations 2
    std::vector<KPublicTransport::Location> locations2;
    for (int i = 0; locations2.size() == 0 && i < 10; i++) {
        locations2 = getLocationsFromCoorAndName(lat2, lon2);
    }

    std::cout << "Location2 Count: " << locations2.size() << std::endl;

    if (locations2.size() == 0) {
        // Early return -> No Location was found
        return QVariant::fromValue(journeys);    
    }

    // Search for Journeys
    KPublicTransport::JourneyRequest req;
    req.setBackendIds(m_manager.enabledBackends());
    req.setFrom(locations1[0]);
    req.setTo(locations2[0]);
    req.setDepartureTime(depTime);

    // KPublicTransport::JourneyQueryModel queryModel;
    // queryModel.setManager(&m_manager);
    // queryModel.setRequest(req);

    KPublicTransport::JourneyReply *reply = m_manager.queryJourney(req);
    QObject::connect(reply, &KPublicTransport::JourneyReply::finished, this, [reply, this] {
        // Q_D(JourneyQueryModel);
        // if (reply->error() == KPublicTransport::JourneyReply::NoError) {
        //     d->m_nextRequest = reply->nextRequest();
        // } else {
        //     d->m_nextRequest = {};
        // }
        // Q_EMIT canQueryPrevNextChanged();
        // std::cout << "Finished" << std::endl;

        for (auto result: reply->result()) {
            std::cout << "Json: " << QJsonDocument(KPublicTransport::Journey::toJson(result)).toJson(QJsonDocument::Compact).toStdString() << std::endl;
        }

    });
    QObject::connect(reply, &KPublicTransport::JourneyReply::updated, this, [reply, this]() {
        std::cout << "Update" << std:.endl;    
    });


    
    
    // std::vector<KPublicTransport::Journey> test;
    // for (int i = 0; test.size() == 0 && i < 10; i++) {
    //     std::cout << "Journey i: " << i << std::endl;
    //     test = m_manager.queryJourney(req)->result();
    //     sleep_for(seconds(5));
    // }

    // for (auto j: test) {
    //     std::cout << "Test" << std::endl;
    // }

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