#include "ratpack.h"

#include "ratmotion.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QtMath>

#include <limits>

namespace {

// Deterministic pseudo-random in [0, 1) so the swarm looks the same
// on every launch.
float hash(int i, float seed)
{
    const float x = qSin(i * 12.9898f + seed * 78.233f) * 43758.5453f;
    return x - qFloor(x);
}

struct Obb {
    QVector3D center;
    QVector3D axis[3]; // unit axes
    QVector3D half;    // half extents
};

float projectionRadius(const Obb &o, const QVector3D &l)
{
    return o.half.x() * qAbs(QVector3D::dotProduct(o.axis[0], l))
         + o.half.y() * qAbs(QVector3D::dotProduct(o.axis[1], l))
         + o.half.z() * qAbs(QVector3D::dotProduct(o.axis[2], l));
}

// Separating Axis Test for two OBBs (15 axes: 6 face normals + 9 edge
// cross products). On overlap, returns the minimum translation vector
// (pointing from a towards b) and its depth.
bool obbOverlap(const Obb &a, const Obb &b, QVector3D &mtv, float &depth)
{
    QVector3D axes[15];
    int n = 0;
    for (int i = 0; i < 3; ++i)
        axes[n++] = a.axis[i];
    for (int i = 0; i < 3; ++i)
        axes[n++] = b.axis[i];
    for (int i = 0; i < 3; ++i)
        for (int j = 0; j < 3; ++j)
            axes[n++] = QVector3D::crossProduct(a.axis[i], b.axis[j]);

    depth = std::numeric_limits<float>::max();
    const QVector3D between = b.center - a.center;

    for (int i = 0; i < n; ++i) {
        if (axes[i].lengthSquared() < 1e-8f)
            continue; // parallel edge pair
        const QVector3D l = axes[i].normalized();
        const float t = QVector3D::dotProduct(between, l);
        const float r = projectionRadius(a, l) + projectionRadius(b, l);
        const float overlap = r - qAbs(t);
        if (overlap <= 0.0f)
            return false;
        if (overlap < depth) {
            depth = overlap;
            mtv = t < 0.0f ? -l : l;
        }
    }
    return true;
}

QVector3D readVector(const QJsonArray &a, const QVector3D &fallback)
{
    if (a.size() != 3)
        return fallback;
    return QVector3D(static_cast<float>(a[0].toDouble()),
                     static_cast<float>(a[1].toDouble()),
                     static_cast<float>(a[2].toDouble()));
}

} // namespace

RatPack::RatPack(QObject *parent)
    : QObject(parent)
{
    spawn();
}

void RatPack::setTarget(const QVector3D &target)
{
    if (m_target == target)
        return;
    m_target = target;
    for (int i = 0; i < m_rats.size(); ++i)
        m_rats[i]->setTarget(target + m_offsets[i]);
    emit targetChanged();
}

void RatPack::setCount(int count)
{
    count = qBound(1, count, 32);
    if (m_count == count)
        return;
    m_count = count;
    spawn();
}

QVariantList RatPack::ratsVariant() const
{
    QVariantList list;
    list.reserve(m_rats.size());
    for (RatMotion *rat : m_rats)
        list.append(QVariant::fromValue(rat));
    return list;
}

void RatPack::setHullSource(const QUrl &source)
{
    if (m_hullSource == source)
        return;
    m_hullSource = source;
    loadHull();
    emit hullSourceChanged();
}

void RatPack::setScaleMin(double v)
{
    if (qFuzzyCompare(m_scaleMin, v))
        return;
    m_scaleMin = v;
    for (int i = 0; i < m_rats.size(); ++i)
        m_rats[i]->setScale(scaleForIndex(i));
    emit scaleMinChanged();
}

void RatPack::setScaleMax(double v)
{
    if (qFuzzyCompare(m_scaleMax, v))
        return;
    m_scaleMax = v;
    for (int i = 0; i < m_rats.size(); ++i)
        m_rats[i]->setScale(scaleForIndex(i));
    emit scaleMaxChanged();
}

float RatPack::scaleForIndex(int i) const
{
    const float lo = static_cast<float>(qMin(m_scaleMin, m_scaleMax));
    const float hi = static_cast<float>(qMax(m_scaleMin, m_scaleMax));
    return lo + (hi - lo) * hash(i, 8.0f);
}

void RatPack::applyTunables(RatMotion *rat, int i)
{
    // Deterministic per-rat jitter so the swarm doesn't move in lockstep.
    const float j1 = 0.85f + 0.30f * hash(i, 1.0f);
    const float j2 = 0.85f + 0.30f * hash(i, 2.0f);
    const float j3 = 0.85f + 0.30f * hash(i, 3.0f);
    rat->setMaxSpeed(static_cast<float>(m_maxSpeed) * j1);
    rat->setSpringStiffness(static_cast<float>(m_springStiffness) * j2);
    rat->setSpringDamping(static_cast<float>(m_springDamping));
    rat->setRotationStiffness(static_cast<float>(m_rotationStiffness) * j3);
    rat->setWiggleAmplitude(static_cast<float>(m_wiggleAmplitude));
    rat->setWiggleWavelength(static_cast<float>(m_wiggleWavelength));
    rat->setScale(scaleForIndex(i));
}

void RatPack::retune()
{
    for (int i = 0; i < m_rats.size(); ++i)
        applyTunables(m_rats[i], i);
}

#define RATPACK_TUNABLE_SETTER(name, member, signal)                            \
    void RatPack::name(double v)                                                \
    {                                                                           \
        if (qFuzzyCompare(member, v))                                           \
            return;                                                             \
        member = v;                                                             \
        retune();                                                               \
        emit signal();                                                          \
    }

RATPACK_TUNABLE_SETTER(setMaxSpeed, m_maxSpeed, maxSpeedChanged)
RATPACK_TUNABLE_SETTER(setSpringStiffness, m_springStiffness, springStiffnessChanged)
RATPACK_TUNABLE_SETTER(setSpringDamping, m_springDamping, springDampingChanged)
RATPACK_TUNABLE_SETTER(setRotationStiffness, m_rotationStiffness, rotationStiffnessChanged)
RATPACK_TUNABLE_SETTER(setWiggleAmplitude, m_wiggleAmplitude, wiggleAmplitudeChanged)
RATPACK_TUNABLE_SETTER(setWiggleWavelength, m_wiggleWavelength, wiggleWavelengthChanged)

void RatPack::setWallX(double x)
{
    if (qFuzzyCompare(m_wallX, x))
        return;
    m_wallX = x;
    emit wallXChanged();
}

void RatPack::setWallReferenceZ(double z)
{
    if (qFuzzyCompare(m_wallReferenceZ, z))
        return;
    m_wallReferenceZ = z;
    emit wallReferenceZChanged();
}

void RatPack::setCameraZ(double z)
{
    if (qFuzzyCompare(m_cameraZ, z))
        return;
    m_cameraZ = z;
    emit cameraZChanged();
}

void RatPack::spawn()
{
    qDeleteAll(m_rats);
    m_rats.clear();
    m_offsets.clear();

    for (int i = 0; i < m_count; ++i) {
        auto *rat = new RatMotion(this);
        applyTunables(rat, i);

        // Fixed spawn locations: a loose line along the bottom of the view.
        const float x = (i - (m_count - 1) / 2.0f) * 1.4f;
        const float y = -2.5f + 0.6f * hash(i, 4.0f);
        const float z = -0.5f * hash(i, 5.0f);
        rat->setPosition(QVector3D(x, y, z));

        // Per-rat offset around the shared target (golden-angle ring with
        // a Z wobble) so the rats spread out around the cursor.
        const float angle = i * 2.39996f;
        const float r = 0.5f + 0.35f * hash(i, 6.0f);
        m_offsets.append(QVector3D(qCos(angle) * r,
                                   qSin(angle) * r * 0.7f,
                                   (hash(i, 7.0f) - 0.5f) * 0.8f));

        rat->setTarget(m_target + m_offsets.last());
        m_rats.append(rat);
    }

    emit ratsChanged();
}

void RatPack::loadHull()
{
    QFile file(m_hullSource.toLocalFile());
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning("RatPack: cannot open hull file %ls, using defaults",
                 qUtf16Printable(m_hullSource.toLocalFile()));
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    const QJsonObject obb = doc.object().value(QStringLiteral("obb")).toObject();
    m_obbCenter = readVector(obb.value(QStringLiteral("center")).toArray(), m_obbCenter);
    m_obbHalf = readVector(obb.value(QStringLiteral("halfExtents")).toArray(), m_obbHalf);
    const double radius = doc.object().value(QStringLiteral("radius")).toDouble(-1.0);
    if (radius > 0.0)
        m_boundRadius = static_cast<float>(radius);
}

void RatPack::advance(double dt)
{
    for (RatMotion *rat : m_rats)
        rat->advance(dt);

    resolveCollisions();
    applyWall();
}

void RatPack::scare(const QVector3D &point, double radius, double strength)
{
    for (int i = 0; i < m_rats.size(); ++i) {
        const QVector3D away = m_rats[i]->position() - point;
        const float d = away.length();
        if (d >= static_cast<float>(radius))
            continue;

        const float falloff = 1.0f - d / static_cast<float>(radius);
        const QVector3D dir = d > 1e-3f ? away / d : QVector3D(1.0f, 0.0f, 0.0f);
        const float jitter = 0.8f + 0.4f * hash(i, 9.0f);
        m_rats[i]->addImpulse(dir * (static_cast<float>(strength) * falloff * jitter));
    }
}

void RatPack::applyWall()
{
    if (m_wallX < -1.0e8)
        return;

    const float denom = static_cast<float>(m_cameraZ - m_wallReferenceZ);
    if (qFuzzyIsNull(denom))
        return;

    // Keep the whole body out, not just the origin.
    for (RatMotion *rat : m_rats) {
        QVector3D pos = rat->position();
        const float margin = m_boundRadius * rat->scale();

        // The wall is a screen-space rectangle edge, so its world-space X
        // grows with distance from the camera: scale the reference-plane
        // limit by each rat's own depth.
        const float depthScale = (static_cast<float>(m_cameraZ) - pos.z()) / denom;
        if (depthScale <= 0.05f)
            continue; // behind the camera; nothing sensible to do

        const float limit = static_cast<float>(m_wallX) * depthScale + margin;
        if (pos.x() < limit) {
            pos.setX(limit);
            rat->setPosition(pos);
            QVector3D v = rat->velocity();
            if (v.x() < 0.0f) {
                v.setX(0.0f); // stop pressing into the wall
                rat->setVelocity(v);
            }
        }
    }
}

void RatPack::resolveCollisions()
{
    // A couple of solver iterations keep clusters stable.
    for (int iter = 0; iter < 2; ++iter) {
        for (int i = 0; i < m_rats.size(); ++i) {
            for (int j = i + 1; j < m_rats.size(); ++j) {
                RatMotion *a = m_rats[i];
                RatMotion *b = m_rats[j];

                const QVector3D between = b->position() - a->position();

                // Broad phase: bounding spheres.
                const float reach = m_boundRadius * (a->scale() + b->scale());
                if (between.lengthSquared() > reach * reach)
                    continue;

                // Narrow phase: OBB vs OBB (SAT).
                Obb oa, ob;
                oa.half = m_obbHalf * a->scale();
                ob.half = m_obbHalf * b->scale();
                oa.center = a->position() + a->rotation().rotatedVector(m_obbCenter * a->scale());
                ob.center = b->position() + b->rotation().rotatedVector(m_obbCenter * b->scale());
                oa.axis[0] = a->rotation().rotatedVector(QVector3D(1, 0, 0));
                oa.axis[1] = a->rotation().rotatedVector(QVector3D(0, 1, 0));
                oa.axis[2] = a->rotation().rotatedVector(QVector3D(0, 0, 1));
                ob.axis[0] = b->rotation().rotatedVector(QVector3D(1, 0, 0));
                ob.axis[1] = b->rotation().rotatedVector(QVector3D(0, 1, 0));
                ob.axis[2] = b->rotation().rotatedVector(QVector3D(0, 0, 1));

                QVector3D mtv;
                float depth = 0.0f;
                if (!obbOverlap(oa, ob, mtv, depth))
                    continue;

                // Positional correction split between the pair, plus a
                // little velocity damping along the contact normal so
                // they jostle and slide instead of sticking.
                const QVector3D push = mtv * (depth * 0.5f);
                a->setPosition(a->position() - push);
                b->setPosition(b->position() + push);

                const QVector3D va = a->velocity() - mtv * QVector3D::dotProduct(a->velocity(), mtv) * 0.5f;
                const QVector3D vb = b->velocity() - mtv * QVector3D::dotProduct(b->velocity(), mtv) * 0.5f;
                a->setVelocity(va);
                b->setVelocity(vb);
            }
        }
    }
}
