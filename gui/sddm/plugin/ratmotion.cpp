#include "ratmotion.h"

#include <QtMath>

RatMotion::RatMotion(QObject *parent)
    : QObject(parent)
{
}

void RatMotion::setTarget(const QVector3D &target)
{
    if (m_target == target)
        return;
    m_target = target;
    emit targetChanged();
}

void RatMotion::setPosition(const QVector3D &position)
{
    if (m_position == position)
        return;
    m_position = position;
    emit positionChanged();
}

void RatMotion::setVelocity(const QVector3D &velocity)
{
    m_velocity = velocity;
    emit speedChanged();
}

void RatMotion::setScale(float scale)
{
    if (qFuzzyCompare(m_scale, scale))
        return;
    m_scale = scale;
    emit scaleChanged();
}

void RatMotion::addImpulse(const QVector3D &impulse)
{
    m_velocity += impulse;
    m_speedBoost = qMax(m_speedBoost, impulse.length());
    emit speedChanged();
}

void RatMotion::advance(double dt)
{
    // Guard against hitches (tab switches, greeter stalls).
    const float step = static_cast<float>(qBound(0.0, dt, 0.05));
    if (step <= 0.0f)
        return;

    const QVector3D toTarget = m_target - m_position;
    const float dist = toTarget.length();

    // Damped spring towards the target: gives the floaty chase with a
    // natural settle (and slight overshoot) on arrival.
    const QVector3D accel = toTarget * m_springStiffness - m_velocity * m_springDamping;
    QVector3D velocity = m_velocity + accel * step;
    // Startle impulses may exceed maxSpeed while the boost decays.
    const float effectiveMax = m_maxSpeed + m_speedBoost;
    const float spd = velocity.length();
    if (spd > effectiveMax)
        velocity *= effectiveMax / spd;
    m_speedBoost *= qExp(-3.0 * step);

    const QVector3D move = velocity * step;
    const float traveled = move.length();

    setPosition(m_position + move);
    setVelocity(velocity);

    // Whole-object wiggle: bob along world Y about the object origin.
    // The phase advances with distance traveled (stride-matched) and the
    // amplitude is tied to speed, so it fades out as the rat arrives.
    m_wigglePhase += (traveled / m_wiggleWavelength) * 2.0f * float(M_PI);
    const float speedFactor = m_maxSpeed > 0.0f ? qMin(spd / m_maxSpeed, 1.0f) : 0.0f;
    const float wiggle = qSin(m_wigglePhase) * m_wiggleAmplitude * speedFactor;
    if (!qFuzzyCompare(wiggle, m_wiggleOffset)) {
        m_wiggleOffset = wiggle;
        emit wiggleOffsetChanged();
    }

    // Ease the body Z-axis onto the direction of the target
    // (framerate-independent exponential ease on a quaternion slerp).
    if (dist > m_arriveRadius) {
        const QVector3D forward = m_flipForward ? QVector3D(0.0f, 0.0f, -1.0f)
                                                : QVector3D(0.0f, 0.0f, 1.0f);
        const QQuaternion desired = QQuaternion::rotationTo(forward, toTarget / dist);
        const float t = 1.0f - qExp(-m_rotationStiffness * step);
        const QQuaternion rotated = QQuaternion::slerp(m_rotation, desired, t);
        if (rotated != m_rotation) {
            m_rotation = rotated;
            emit rotationChanged();
        }
    }
}
