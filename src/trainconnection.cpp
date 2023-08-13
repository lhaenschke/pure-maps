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

#include <vector>
using std::this_thread::sleep_for; 
using std::chrono::seconds;
#include <iostream>

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

void sleepInBackground()
{
    std::cout << "Start Background Sleep" << std::endl;
    sleep_for(seconds(20));
    std::cout << "Finished Background Sleep" << std::endl;
}

void TrainConnection::getJsonJourneyBetweenLocations(const QString &locationFromString, const QString &locationToString, const QDateTime depTime, const int index)
{
    KPublicTransport::JourneyRequest req;
    req.setBackendIds(m_manager.enabledBackends());
    req.setFrom(convertJsonStringToLocation(locationFromString));
    req.setTo(convertJsonStringToLocation(locationToString));
    req.setDepartureTime(depTime);

    QVector<KPublicTransport::Journey> journeys;

    std::thread backgroundThread(sleepInBackground);
    m_threadMap.insert({index, backgroundThread});

    KPublicTransport::JourneyReply *reply = m_manager.queryJourney(req);
    QObject::connect(reply, &KPublicTransport::JourneyReply::finished, this, [reply, this] {
        
        for (auto result: reply->result()) {
            std::cout << "Gefunden" << std::endl;
        }

        for (auto& p: m_threadMap) {
            if (p.first == index) {
                p.second.request_stop();
            }
        }

    });

    backgroundThread.join();
    
    std::cout << "Jawollja" << std::endl;

    m_journeys[index] = journeys;
}

QVariant TrainConnection::loadJourneys(const QString &locationFromStrings, const QString &locationToStrings)
{
    m_journeys = QVector<QVector<KPublicTransport::Journey>>(9);
    QDateTime depTime(QDate::currentDate(), QTime::currentTime());

    std::thread t1(getJsonJourneyBetweenLocations, locationFromStrings, locationToStrings, depTime, 0);

    t1.join();

    QVector<KPublicTransport::Journey> journeys;
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