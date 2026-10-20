pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Polls /sys/class/net, /proc/net/wireless and `ip addr` for interface
// state, IPv4 addresses, wifi link quality and transfer rates.
Singleton {
    id: root

    // Array of interfaces:
    // { name, wifi, connected, ip, link (0..70, -1 if unknown), rxRate, txRate }
    property var interfaces: []

    readonly property var ethernet: interfaces.find(i => !i.wifi) ?? null
    readonly property var wifi: interfaces.find(i => i.wifi) ?? null

    // Previous byte counters per interface: name -> [rx, tx, timestamp]
    property var _prevBytes: ({})

    // One line per interface: name wifi(0/1) operstate rx tx ip link
    Process {
        id: netProc
        command: ["sh", "-c", 'for i in /sys/class/net/*; do n=${i##*/}; [ "$n" = lo ] && continue; s=$(cat $i/operstate 2>/dev/null); rx=$(cat $i/statistics/rx_bytes 2>/dev/null); tx=$(cat $i/statistics/tx_bytes 2>/dev/null); ip=$(ip -o -4 addr show dev $n 2>/dev/null | awk "{print \\$4}" | head -n1); if [ -d "$i/wireless" ]; then w=1; else w=0; fi; q=-; if [ $w = 1 ]; then qq=$(awk -v n="$n:" "\\$1==n {print \\$3}" /proc/net/wireless 2>/dev/null); q=${qq%.*}; [ -z "$q" ] && q=-; fi; echo "$n $w ${s:-down} ${rx:-0} ${tx:-0} ${ip:--} $q"; done']
        stdout: StdioCollector {
            onStreamFinished: root._parse(text.trim())
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    function _parse(out) {
        const now = Date.now();
        const ifaces = [];
        for (const line of out.split("\n")) {
            if (!line.trim())
                continue;
            const p = line.split(" ");
            const name = p[0];
            const rx = Number(p[3]), tx = Number(p[4]);
            const prev = _prevBytes[name];
            let rxRate = 0, txRate = 0;
            if (prev && now > prev[2]) {
                const dt = (now - prev[2]) / 1000;
                rxRate = Math.max(0, (rx - prev[0]) / dt);
                txRate = Math.max(0, (tx - prev[1]) / dt);
            }
            _prevBytes[name] = [rx, tx, now];
            ifaces.push({
                name: name,
                wifi: p[1] === "1",
                connected: p[2] === "up",
                ip: p[5],
                link: p[6] === "-" ? -1 : Number(p[6]),
                rxRate: rxRate,
                txRate: txRate
            });
        }
        interfaces = ifaces;
    }

    function fmtRate(bytesPerSec) {
        if (bytesPerSec >= 1048576)
            return (bytesPerSec / 1048576).toFixed(1) + " MB/s";
        if (bytesPerSec >= 1024)
            return (bytesPerSec / 1024).toFixed(1) + " kB/s";
        return Math.round(bytesPerSec) + " B/s";
    }
}
