import QtQuick 2.8
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.5
import org.kde.plasma.core 2.0

ColumnLayout {
    spacing: -10

    property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software

    Label {
        text: Qt.formatDateTime(new Date(), "dddd, d MMMM")
        color: "white"
        opacity: 0.5
        style: softwareRendering ? Text.Outline : Text.Normal
        styleColor: softwareRendering ? ColorScope.backgroundColor : "transparent"
        font.pointSize: 20
        font.weight: Font.DemiBold
        font.capitalization: Font.Capitalize
        Layout.alignment: Qt.AlignHCenter
        font.family: config.name
    }

    Label {
        id: clockLabel
        color: "white"
        opacity: 0.5
        style: softwareRendering ? Text.Outline : Text.Normal
        styleColor: softwareRendering ? ColorScope.backgroundColor : "transparent"
        font.pointSize: 100
        font.bold: true
        font.family: config.name 
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatTime(new Date(), "hh:mm")
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: {
            clockLabel.text = Qt.formatTime(new Date(), "hh:mm")
        }
    }
}

