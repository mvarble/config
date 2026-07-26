#pragma once

#include <QObject>
#include <QQuaternion>
#include <QVector3D>
#include <QtQml/qqmlregistration.h>

// RatMotion drives a single rat: it floats through 3-space towards a target
// using a damped spring, eases its body Z-axis onto the direction of the
// target, and bobs along the world Y axis while moving (the "wiggle").
//
// All tunables are plain C++ setters; RatPack configures them per rat.
// QML only needs `target` (write) and the animated outputs (read).
class RatMotion : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVector3D target READ target WRITE setTarget NOTIFY targetChanged)
    Q_PROPERTY(QVector3D position READ position NOTIFY positionChanged)
    Q_PROPERTY(QQuaternion rotation READ rotation NOTIFY rotationChanged)
    Q_PROPERTY(float wiggleOffset READ wiggleOffset NOTIFY wiggleOffsetChanged)
    Q_PROPERTY(float speed READ speed NOTIFY speedChanged)
    // Uniform model scale; also scales this rat's collision shape.
    Q_PROPERTY(float scale READ scale WRITE setScale NOTIFY scaleChanged)

public:
    explicit RatMotion(QObject *parent = nullptr);

    QVector3D target() const { return m_target; }
    void setTarget(const QVector3D &target);

    QVector3D position() const { return m_position; }
    QQuaternion rotation() const { return m_rotation; }
    float wiggleOffset() const { return m_wiggleOffset; }
    float speed() const { return m_velocity.length(); }
    float scale() const { return m_scale; }
    void setScale(float scale);

    // Advances the simulation by dt seconds.
    Q_INVOKABLE void advance(double dt);

    // --- C++-only API used by RatPack -----------------------------------

    void setPosition(const QVector3D &position);
    QVector3D velocity() const { return m_velocity; }
    void setVelocity(const QVector3D &velocity);

    // Adds an instantaneous velocity impulse (e.g. being scared). The
    // impulse may exceed maxSpeed; a decaying boost permits that briefly
    // before normal speed limits resume.
    void addImpulse(const QVector3D &impulse);

    void setMaxSpeed(float v) { m_maxSpeed = v; }
    void setSpringStiffness(float v) { m_springStiffness = v; }
    void setSpringDamping(float v) { m_springDamping = v; }
    void setRotationStiffness(float v) { m_rotationStiffness = v; }
    void setWiggleAmplitude(float v) { m_wiggleAmplitude = v; }
    void setWiggleWavelength(float v) { m_wiggleWavelength = v; }
    void setArriveRadius(float v) { m_arriveRadius = v; }
    void setFlipForward(bool v) { m_flipForward = v; }

signals:
    void targetChanged();
    void positionChanged();
    void rotationChanged();
    void wiggleOffsetChanged();
    void speedChanged();
    void scaleChanged();

private:
    QVector3D m_target{0.0f, 0.0f, 1.0f};
    QVector3D m_position{0.0f, 0.0f, 0.0f};
    QVector3D m_velocity{0.0f, 0.0f, 0.0f};
    QQuaternion m_rotation; // identity

    float m_wigglePhase = 0.0f;
    float m_wiggleOffset = 0.0f;
    float m_scale = 1.0f;
    float m_speedBoost = 0.0f; // extra speed allowance while startled

    // Tunables (configured by RatPack).
    float m_maxSpeed = 8.0f;          // units / second
    float m_springStiffness = 8.0f;   // acceleration per unit of distance
    float m_springDamping = 5.0f;     // velocity damping
    float m_rotationStiffness = 6.0f; // alignment easing rate
    float m_wiggleAmplitude = 0.10f;  // world units, scaled by speed factor
    float m_wiggleWavelength = 0.8f;  // units traveled per full bob
    float m_arriveRadius = 0.05f;     // stop turning when this close
    bool m_flipForward = false;       // true if the nose is at -Z
};
