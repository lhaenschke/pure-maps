/*
 * This file is part of Pure Maps.
 *
 * SPDX-FileCopyrightText: 2023 lhaenschke https://github.com/lhaenschke
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 */

#include "publictransport.h"

#include <QQmlApplicationEngine>
#include <QDebug>
#include <QDesktopServices>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QStandardPaths>
#include <QUrl>

#include <vector>
#include <limits>
#include <iostream>

PublicTransport::PublicTransport(QObject *parent)
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

void PublicTransport::setStart(const KPublicTransport::Location &start)
{
    m_start = start;
    Q_EMIT startChanged();
}

KPublicTransport::Location PublicTransport::start() const
{
    return m_start;
}

void PublicTransport::setDestination(const KPublicTransport::Location &destination)
{
    m_destination = destination;
    Q_EMIT destinationChanged();
}

KPublicTransport::Location PublicTransport::destination() const
{
    return m_destination;
}

QDate PublicTransport::departureDate() const
{
    return m_departureDate;
}

void PublicTransport::setDepartureDate(const QDate &date)
{
    if (m_departureDate != date) {
        m_departureDate = date;
        Q_EMIT departureDateChanged();
    }
}

QTime PublicTransport::departureTime() const
{
    return m_departureTime;
}

void PublicTransport::setDepartureTime(const QTime &time)
{
    if (m_departureTime != time) {
        m_departureTime = time;
        Q_EMIT departureTimeChanged();
    }
}

void PublicTransport::setBackendEnable(const QString &identifier, bool enabeld)
{
    m_manager.setBackendEnabled(identifier, enabeld);
}

void PublicTransport::setStartLocation(float lat, float lon, const QString &name)
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


QString PublicTransport::convertLocationToJsonString(const KPublicTransport::Location &location)
{
    return QJsonDocument(KPublicTransport::Location::toJson(location)).toJson(QJsonDocument::Compact);
}

KPublicTransport::Location PublicTransport::convertJsonStringToLocation(const QString &jsonString)
{
    return KPublicTransport::Location::fromJson(QJsonDocument::fromJson(jsonString.toUtf8()).object());
}

void PublicTransport::loadLocationFromCoorAndName(float lat, float lon, const QString &name, const int index)
{
    KPublicTransport::LocationRequest req;
    req.setBackendIds(m_manager.enabledBackends());
    req.setCoordinate(lat, lon);
    req.setName(name);

    for (auto result: m_manager.queryLocation(req)->result()) {
        m_locations.insert(index, result);
    }
}

bool PublicTransport::loadingLocationIsFinished()
{
    for (int i = 0; i < 6; i++) {
        if (!m_locations.contains(i)) {
            return false;
        }
    }
    return true;
}

KPublicTransport::Location PublicTransport::getLocation(const int index)
{
    return m_locations.value(index);
}

bool PublicTransport::locationIsEmpty(const KPublicTransport::Location &location)
{
    return location.isEmpty();
}

void PublicTransport::loadJourney(const KPublicTransport::Location &locationFrom, const KPublicTransport::Location &locationTo, const int index)
{
    KPublicTransport::JourneyRequest req;
    req.setBackendIds(m_manager.enabledBackends());
    req.setFrom(locationFrom);
    req.setTo(locationTo);
    QDateTime depTime = QDateTime::currentDateTime();
    depTime = depTime.addSecs(15 * 60);
    req.setDepartureTime(depTime);
    
    KPublicTransport::JourneyReply *reply = m_manager.queryJourney(req);
    QObject::connect(reply, &KPublicTransport::JourneyReply::finished, this, [reply, index, depTime, this] {
        // std::cout << "Index " << index << " hat gefunden" << std::endl;
        KPublicTransport::Journey earlyJourney;
        QDateTime earlyArrivalTime = QDateTime::currentDateTime();
        earlyArrivalTime = earlyArrivalTime.addYears(10);

        const std::vector<KPublicTransport::Journey> results = reply->result();
        for (int i = 0; i < results.size() && i < 15; i++) {
            if (results.at(i).scheduledArrivalTime() < earlyArrivalTime && results.at(i).scheduledDepartureTime() >= depTime) {
                earlyArrivalTime = results.at(i).scheduledArrivalTime();
                earlyJourney = results.at(i);
            }
            
        }

        m_journeys.insert(index, earlyJourney);
    });
}

bool PublicTransport::loadingJourneyIsFinished()
{
    for (int i = 0; i < 9; i++) {
        if (!m_journeys.contains(i)) {
            return false;
        }
    }
    return true;
}

QDateTime PublicTransport::getDepartureTime(const int index)
{
    if (m_journeys.contains(index)) {
        return m_journeys.value(index).scheduledDepartureTime();
    }

    QDateTime defaultDate = QDateTime::currentDateTime();
    defaultDate = defaultDate.addYears(10);

    return defaultDate;
}

QDateTime PublicTransport::getArrivalTime(const int index)
{
    if (m_journeys.contains(index)) {
        return m_journeys.value(index).scheduledArrivalTime();
    }

    QDateTime defaultDate = QDateTime::currentDateTime();
    defaultDate = defaultDate.addYears(10);

    return defaultDate;
}

KPublicTransport::Journey PublicTransport::getJourney(const int index)
{
    return m_journeys.value(index);
}

void PublicTransport::clear()
{
    std::cout << "Clear called" << std::endl;
    m_locations.clear();
    m_journeys.clear();
}


KPublicTransport::JourneyRequest PublicTransport::createJourneyRequest()
{
    KPublicTransport::JourneyRequest req;
    req.setFrom(m_start);
    req.setTo(m_destination);

    QDateTime depTime(m_departureDate, m_departureTime);
    req.setDepartureTime(depTime);

    return req;
}

KPublicTransport::LocationRequest PublicTransport::createLocationRequest(const QString &name)
{
    KPublicTransport::LocationRequest req;
    req.setName(name);
    
    return req;
}

KPublicTransport::StopoverRequest PublicTransport::createStopoverRequest()
{
    KPublicTransport::StopoverRequest req;
    req.setStop(m_start);

    QDateTime depTime(m_departureDate, m_departureTime);
    req.setDateTime(depTime);

    return req;
}