#pragma once

#include <QObject>
#include <QUrl>
#include <QVariantList>
#include <QVector3D>
#include <QtQml/qqmlregistration.h>

class RatMotion;

// RatPack owns a swarm of RatMotion instances, fans the shared cursor
// target out into per-rat offsets, and resolves collisions between the
// rats using OBBs (the box bounding the model's convex hull) via SAT.
class RatPack : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVector3D target READ target WRITE setTarget NOTIFY targetChanged)
    Q_PROPERTY(int count READ count WRITE setCount NOTIFY ratsChanged)
    Q_PROPERTY(QVariantList rats READ ratsVariant NOTIFY ratsChanged)
    Q_PROPERTY(QUrl hullSource READ hullSource WRITE setHullSource NOTIFY hullSourceChanged)
    // Per-rat uniform scales are sampled deterministically in [scaleMin,
    // scaleMax] at spawn time.
    Q_PROPERTY(double scaleMin READ scaleMin WRITE setScaleMin NOTIFY scaleMinChanged)
    Q_PROPERTY(double scaleMax READ scaleMax WRITE setScaleMax NOTIFY scaleMaxChanged)
    // Swarm motion feel (per-rat jitter is applied on top).
    Q_PROPERTY(double maxSpeed READ maxSpeed WRITE setMaxSpeed NOTIFY maxSpeedChanged)
    Q_PROPERTY(double springStiffness READ springStiffness WRITE setSpringStiffness NOTIFY springStiffnessChanged)
    Q_PROPERTY(double springDamping READ springDamping WRITE setSpringDamping NOTIFY springDampingChanged)
    Q_PROPERTY(double rotationStiffness READ rotationStiffness WRITE setRotationStiffness NOTIFY rotationStiffnessChanged)
    Q_PROPERTY(double wiggleAmplitude READ wiggleAmplitude WRITE setWiggleAmplitude NOTIFY wiggleAmplitudeChanged)
    Q_PROPERTY(double wiggleWavelength READ wiggleWavelength WRITE setWiggleWavelength NOTIFY wiggleWavelengthChanged)
    // A vertical wall that blocks the rats (used to keep them out of the
    // login panel's screen region). wallX is the wall's world-space X at
    // the reference plane wallReferenceZ; the actual limit is scaled per
    // rat by depth so the block matches the panel's projection on screen.
    // Set wallX below -1e8 to disable (the default).
    Q_PROPERTY(double wallX READ wallX WRITE setWallX NOTIFY wallXChanged)
    Q_PROPERTY(double wallReferenceZ READ wallReferenceZ WRITE setWallReferenceZ NOTIFY wallReferenceZChanged)
    Q_PROPERTY(double cameraZ READ cameraZ WRITE setCameraZ NOTIFY cameraZChanged)

public:
    explicit RatPack(QObject *parent = nullptr);

    QVector3D target() const { return m_target; }
    void setTarget(const QVector3D &target);

    int count() const { return m_count; }
    void setCount(int count);

    QVariantList ratsVariant() const;

    QUrl hullSource() const { return m_hullSource; }
    void setHullSource(const QUrl &source);

    double scaleMin() const { return m_scaleMin; }
    void setScaleMin(double v);

    double scaleMax() const { return m_scaleMax; }
    void setScaleMax(double v);

    double maxSpeed() const { return m_maxSpeed; }
    void setMaxSpeed(double v);
    double springStiffness() const { return m_springStiffness; }
    void setSpringStiffness(double v);
    double springDamping() const { return m_springDamping; }
    void setSpringDamping(double v);
    double rotationStiffness() const { return m_rotationStiffness; }
    void setRotationStiffness(double v);
    double wiggleAmplitude() const { return m_wiggleAmplitude; }
    void setWiggleAmplitude(double v);
    double wiggleWavelength() const { return m_wiggleWavelength; }
    void setWiggleWavelength(double v);

    double wallX() const { return m_wallX; }
    void setWallX(double x);

    double wallReferenceZ() const { return m_wallReferenceZ; }
    void setWallReferenceZ(double z);

    double cameraZ() const { return m_cameraZ; }
    void setCameraZ(double z);

    // Advances every rat by dt seconds, then resolves collisions.
    Q_INVOKABLE void advance(double dt);

    // Startles the rats: those within `radius` of `point` get a radial
    // velocity impulse away from it (strength falls off with distance,
    // plus per-rat jitter). Afterwards normal chasing resumes by itself.
    Q_INVOKABLE void scare(const QVector3D &point, double radius = 5.0, double strength = 14.0);

signals:
    void targetChanged();
    void ratsChanged();
    void hullSourceChanged();
    void scaleMinChanged();
    void scaleMaxChanged();
    void maxSpeedChanged();
    void springStiffnessChanged();
    void springDampingChanged();
    void rotationStiffnessChanged();
    void wiggleAmplitudeChanged();
    void wiggleWavelengthChanged();
    void wallXChanged();
    void wallReferenceZChanged();
    void cameraZChanged();

private:
    void spawn();
    void loadHull();
    void resolveCollisions();
    void applyWall();
    float scaleForIndex(int i) const;
    void applyTunables(RatMotion *rat, int i);
    void retune();

    QVector<RatMotion *> m_rats;
    QVector<QVector3D> m_offsets;

    QVector3D m_target{0.0f, 0.0f, 1.0f};
    int m_count = 6;
    QUrl m_hullSource;
    double m_scaleMin = 3.0;
    double m_scaleMax = 5.0;
    double m_maxSpeed = 8.0;
    double m_springStiffness = 8.0;
    double m_springDamping = 5.0;
    double m_rotationStiffness = 6.0;
    double m_wiggleAmplitude = 0.10;
    double m_wiggleWavelength = 0.8;
    double m_wallX = -1.0e9; // disabled by default
    double m_wallReferenceZ = 1.0;
    double m_cameraZ = 10.0;

    // Collision shape in model units (overridden by the hull JSON).
    // Defaults match the measured bounds of assets/rat.glb.
    QVector3D m_obbCenter{0.00003f, 0.0307f, -0.0741f};
    QVector3D m_obbHalf{0.0247f, 0.0314f, 0.1582f};
    float m_boundRadius = 0.24f;
};
