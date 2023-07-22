#ifndef TRAINCONNECTION_H
#define TRAINCONNECTION_H

#include <QDate>
#include <QObject>
#include <QTime>
#include <QVariant>

#include <KPublicTransport/JourneyRequest>
#include <KPublicTransport/Location>
#include <KPublicTransport/Manager>
#include <KPublicTransport/LocationRequest>
#include <KPublicTransport/LocationReply>
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

    Q_INVOKABLE KPublicTransport::JourneyRequest createJourneyRequest();
    Q_INVOKABLE KPublicTransport::LocationRequest createLocationRequest(const QString &name);
    Q_INVOKABLE KPublicTransport::StopoverRequest createStopoverRequest();

    Q_INVOKABLE void showOnMap(KPublicTransport::Location location);

    void test();

Q_SIGNALS:
    void startChanged();
    void destinationChanged();
    void departureDateChanged();
    void departureTimeChanged();

private:
    KPublicTransport::Location m_start;
    KPublicTransport::Location m_destination;
    KPublicTransport::Manager manager;
    QDate m_departureDate;
    QTime m_departureTime;
};

#endif // TRAINCONNECTION_H