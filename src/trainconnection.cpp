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

#include<iostream> // for std::cout
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

QString TrainConnection::getJsonLocationFromCoorAndName(float lat, float lon, const QString &name)
{
    KPublicTransport::LocationRequest req;
    req.setBackendIds(m_manager.enabledBackends());
    req.setCoordinate(lat, lon);
    req.setName(name);

    for (auto result: m_manager.queryLocation(req)->result()) {
        return convertLocationToJsonString(result);
    }
    return QString("{\"name\":\"Default\"}");
}

auto f()
{ 
    std::cout << "        Task started ...\n";
    sleep_for(seconds(15));
    std::cout << "        Task done!\n";
}

QVariant TrainConnection::getJourneyBetweenLocations(const QString &fromLocationJson, const QString &toLocationJson)
{
    KPublicTransport::JourneyRequest req;
    req.setBackendIds(m_manager.enabledBackends());
    req.setFrom(m_start);
    req.setTo(m_destination);
    // req.setFrom(convertJsonStringToLocation(fromLocationJson));
    // req.setTo(convertJsonStringToLocation(toLocationJson));

    QDateTime depTime(QDate::currentDate(), QTime::currentTime());
    req.setDepartureTime(depTime);

    std::cout << "Start: " << convertLocationToJsonString(m_start) << std::endl;
    std::cout << "Desti: " << convertLocationToJsonString(m_destination) << std::endl;
    std::cout << "Req is Valid: " << req.isValid() << std::endl;

    KPublicTransport::JourneyReply *reply = m_manager.queryJourney(req);

    std::thread t(f);
    t.join();

    for (auto result: reply->result()) {
        std::cout << "Gefunden" << std::endl;
        
        // if (journeys.size() < 3) {
        //     journeys.append(result);
        // } else {
        //     break;
        // }
    }

    QVector<KPublicTransport::Journey> journeys;
    return QVariant::fromValue(journeys);

    // KPublicTransport::JourneyRequest req = KPublicTransport::JourneyRequest(m_start, m_destination);
    // req.setFrom(m_start);
    // req.setTo(m_destination);

    // QDateTime depTime(m_departureDate, m_departureTime);
    // req.setDepartureTime(depTime);

    // std::cout << "IsValid: " << queryModel.isValid() << std::endl;

    // KPublicTransport::JourneyQueryModel queryModel;
    // queryModel.setManager(&m_manager);
    // queryModel.setRequest(req);
    
    // std::thread t(f);
    // t.join();

    // std::cout << "Next: " << queryModel.canQueryNext() << std::endl;
    // std::cout << "Prev: " << queryModel.canQueryPrevious() << std::endl;

    // std::cout << "IdLoading: " << queryModel.isLoading() << std::endl;
    // std::cout << "Error: " << queryModel.errorMessage().toStdString() << std::endl;

    // for (auto result: queryModel.journeys()) {
    //     std::cout << "Test" << std::endl;
    // }

    // return QVariant::fromValue(journeys);
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