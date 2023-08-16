/*
 * This file is part of Pure Maps.
 *
 * SPDX-FileCopyrightText: 2023 lhaenschke https://github.com/lhaenschke
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 */

#ifndef TRAINCONNECTION_H
#define TRAINCONNECTION_H

#include <QObject>
#include <QDate>
#include <QTime>
#include <QDateTime>
#include <QString>
#include <QVariant>
#include <QMap>
#include <QVector>

#include <KPublicTransport/Manager>
#include <KPublicTransport/Backend>
#include <KPublicTransport/Attribution>
#include <KPublicTransport/JourneyRequest>
#include <KPublicTransport/JourneyReply>
#include <KPublicTransport/Journey>
#include <KPublicTransport/LocationRequest>
#include <KPublicTransport/LocationReply>
#include <KPublicTransport/Location>
#include <KPublicTransport/StopoverRequest>

class TrainConnection : public QObject
{
    Q_OBJECT
    Q_PROPERTY(KPublicTransport::Location start READ start WRITE setStart NOTIFY startChanged)
    Q_PROPERTY(KPublicTransport::Location destination READ destination WRITE setDestination NOTIFY destinationChanged)
    Q_PROPERTY(QDate departureDate READ departureDate WRITE setDepartureDate NOTIFY departureDateChanged)
    Q_PROPERTY(QTime departureTime READ departureTime WRITE setDepartureTime NOTIFY departureTimeChanged)

public:
    explicit TrainConnection(QObject *parent = nullptr);

    KPublicTransport::Location start() const;
    void setStart(const KPublicTransport::Location &start);

    KPublicTransport::Location destination() const;
    void setDestination(const KPublicTransport::Location &destination);

    QDate departureDate() const;
    void setDepartureDate(const QDate &date);

    QTime departureTime() const;
    void setDepartureTime(const QTime &time);

    Q_INVOKABLE void setBackendEnable(const QString &identifier, bool enabeld);
    Q_INVOKABLE void setStartLocation(float lat, float lon, const QString &name);

    Q_INVOKABLE QString convertLocationToJsonString(const KPublicTransport::Location &location);
    Q_INVOKABLE KPublicTransport::Location convertJsonStringToLocation(const QString &jsonString);

    Q_INVOKABLE QString convertJourneyToJsonString(const KPublicTransport::Journey &journey);
    Q_INVOKABLE KPublicTransport::Journey convertJsonStringToJourney(const QString &jsonString);

    Q_INVOKABLE QString getJsonLocationFromCoorAndName(float lat, float lon, const QString &name);
    Q_INVOKABLE void loadJourney(const QString &locationFromString, const QString &locationToString, const int index);
    Q_INVOKABLE bool loadingFinished();
    Q_INVOKABLE QDateTime getDepartureTime(const int index);
    Q_INVOKABLE QDateTime getArrivalTime(const int index);
    Q_INVOKABLE KPublicTransport::Journey getJourney(const int index);


    Q_INVOKABLE KPublicTransport::JourneyRequest createJourneyRequest();
    Q_INVOKABLE KPublicTransport::LocationRequest createLocationRequest(const QString &name);
    Q_INVOKABLE KPublicTransport::StopoverRequest createStopoverRequest();

Q_SIGNALS:
    void startChanged();
    void destinationChanged();
    void departureDateChanged();
    void departureTimeChanged();

private:
    KPublicTransport::Location m_start;
    KPublicTransport::Location m_destination;
    KPublicTransport::Manager m_manager;
    QMap<int, KPublicTransport::Journey> m_journeys;
    QDate m_departureDate;
    QTime m_departureTime;
};

#endif // TRAINCONNECTION_H