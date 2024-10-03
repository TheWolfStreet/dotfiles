// Copyright 2022 Alexey Varfolomeev <varlesh@gmail.com>
// Used sources & ideas:
// - Joshua Krämer from https://github.com/joshuakraemer/sddm-theme-dialog
// - Suraj Mandal from https://github.com/surajmandalcell/Elegant-sddm
// - Breeze theme by KDE Visual Design Group
// - SDDM Team https://github.com/sddm/sddm
import QtQuick 2.8
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.2
import QtQuick.Controls.Styles 1.4

import org.kde.plasma.components 3.0 as PlasmaComponents
import "components"

Rectangle {
  width: 1900
  height: 1080
  LayoutMirroring.enabled: Qt.locale().textDirection === Qt.RightToLeft
  LayoutMirroring.childrenInherit: true

  readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software

    Timer {
    id: resetTimer
    interval: 5000
    onTriggered: {
      password.placeholderText = "Enter Password"
    }
  }

  Connections {
    target: sddm
    function onLoginSucceeded() {
    }

    function onLoginFailed() {
      password.placeholderText = i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Login Failed")
      password.placeholderTextColor = "white"
      password.text = ""
      password.enabled = true
      password.focus = true
      resetTimer.start()
    }
  }

  Image {
    id: wallpaper
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    mipmap: true

    Binding on source {
      when: config.background !== undefined
      value: config.background
    }
  }

  IconButton {
    id: shutDownButton
    iconSize: 28
    mainIcon: "resources/system-shutdown.svg"
    tooltipText: "Shutdown"
    anchors {
      top: parent.top
      right: parent.right
      rightMargin: 20
      topMargin: 10
    }

    clickHandler: function () {
      sddm.powerOff()
    }
  }

  IconButton {
    id: rebootButton
    iconSize: 22
    mainIcon: "resources/system-reboot.svg"
    tooltipText: "Reboot"
    anchors {
      top: parent.top
      right: shutDownButton.left
      rightMargin: 20
      topMargin: 10
    }

    clickHandler: function () {
      sddm.reboot()
    }
  }

  IconButton {
    id: suspendButton
    iconSize: 22
    mainIcon: "resources/system-suspend.svg"
    tooltipText: "Suspend"
    anchors {
      top: parent.top
      right: rebootButton.left
      rightMargin: 20
      topMargin: 10
    }

    clickHandler: function () {
      sddm.suspend()
            resetTimer.start()
    }
  }

  SessionButton {
    anchors {
      top: parent.top
      right: suspendButton.left
      rightMargin: 20
      topMargin: 10
    }
    id: sessionButton
    font.pointSize: config.fontSize
    onSessionChanged: {
      password.forceActiveFocus()
    }
  }

  KeyboardButton {
    id: layoutButton
    font.pointSize: config.fontSize
    anchors {
      top: parent.top
      right: sessionButton.left
      rightMargin: 20
      topMargin: 10
    }

    onKeyboardLayoutChanged: {
      password.forceActiveFocus()
    }
  }

  Clock {
    id: clock
    anchors {
      topMargin: 120
      horizontalCenter: parent.horizontalCenter
      top: parent.top
    }
    visible: true
  }

  Grid {
    columns: 1
    spacing: 8
    verticalItemAlignment: Grid.AlignVCenter
    horizontalItemAlignment: Grid.AlignHCenter

    anchors {
      horizontalCenter: parent.horizontalCenter
      bottom: parent.bottom
      bottomMargin: 70
    }
    Column {
      anchors {
        horizontalCenter: parent.horizontalCenter
        bottom: parent.bottom
        bottomMargin: 155
      }
      Item {

        Rectangle {
          id: mask
          anchors.centerIn: parent
          width: 88
          height: 88
          radius: 100
          visible: true

        }

        Image {
          id: avatar
          anchors.centerIn: parent
          width: 86
          height: 86
          sourceSize.width: width
          sourceSize.height: height
          fillMode: Image.PreserveAspectCrop
          mipmap: true
          layer.enabled: true
          layer.effect: OpacityMask {
            maskSource: mask
          }

          source: "/var/lib/AccountsService/icons/" + user.objectAt(userButton.currentIndex).userInfo.name

          onStatusChanged: {
            if (status == Image.Error)
              return source = "resources/.face.icon"
          }

        }
      }
    }

    PlasmaComponents.ToolButton {
      id: userButton
      height: 40
      width: 226
      property int currentIndex: -1
      enabled: password.enabled

      Component.onCompleted: {
        currentIndex = userModel.lastIndex
      }

      PlasmaComponents.Label {
        text: user.objectAt(userButton.currentIndex).userInfo.realName
        font.bold: true
        font.pointSize: 12
        font.family: config.name
        color: "white"
        anchors.centerIn: parent
      }

      property bool isExtended: false

      onClicked: {

        userMenu.visible = !userMenu.visible
        if (userMenu.visible) {
          userMenu.x = userButton.x
          userMenu.y = userButton.y - userMenu.height + 2
          password.forceActiveFocus()
        }
        isExtended = userMenu.visible
      }

      indicator: Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 9
        height: parent.height
        width: 24
        color: "transparent"

        Image {
          id: arrowImage
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          height: width
          fillMode: Image.PreserveAspectFit
          source: "resources/go-down.svg"

          transform: Rotation {
            id: rotationTransform
            origin.x: arrowImage.width / 2
            origin.y: arrowImage.height / 2
            angle: userButton.isExtended ? 180 : 0

            Behavior on angle {
              NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
              }
            }
          }
        }
      }
    }

    PlasmaComponents.Menu {

      id: userMenu
      width: 226
      visible: false
      font.family: config.name
      onVisibleChanged: {
        userButton.isExtended = visible
      }

      Instantiator {
        id: user
        model: userModel
        onObjectAdded: userMenu.insertItem(index, object)
        onObjectRemoved: userMenu.removeItem(object)
        delegate: PlasmaComponents.MenuItem {
          property
          var userInfo: ({
            name: model.name,
            realName: model.realName
          })
          text: userInfo.realName ? userInfo.realName : userInfo.name
          onTriggered: {
            userButton.currentIndex = model.index
            avatar.source = "/var/lib/AccountsService/icons/" + userInfo.name
            password.forceActiveFocus()
          }
        }
      }
    }

    TextField {
      id: password
      height: 32
      width: 200
      color: "#fff"
      echoMode: TextInput.Password
      focus: true
      placeholderText: "Enter Password"
      font.family: config.name

      onAccepted: {
        password.enabled = false
        sddm.login(user.objectAt(userButton.currentIndex).userInfo.name, password.text, sessionButton.currentIndex)
      }

      background: Rectangle {
        implicitWidth: parent.width
        implicitHeight: parent.height
        color: "#fff"
        opacity: 0.2
        radius: 15
      }

      Image {
        id: caps
        width: 24
        height: 24
        opacity: 0
        state: keyboard.capsLock ? "activated" : ""
        anchors.right: password.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 10
        fillMode: Image.PreserveAspectFit
        source: "resources/capslock.svg"
        sourceSize.width: 24
        sourceSize.height: 24

        states: [
          State {
            name: "activated"
            PropertyChanges {
              target: caps
              opacity: 1
            }
          },
          State {
            name: ""
            PropertyChanges {
              target: caps
              opacity: 0
            }
          }
        ]

        transitions: [
          Transition {
            to: "activated"
            NumberAnimation {
              target: caps
              property: "opacity"
              from: 0
              to: 1
              duration: imageFadeIn
            }
          },

          Transition {
            to: ""
            NumberAnimation {
              target: caps
              property: "opacity"
              from: 1
              to: 0
              duration: imageFadeOut
            }
          }
        ]
      }
    }

    Label {
      id: greetingLabel
      text: "Touch ID or Enter Password"
      color: "#fff"
      style: softwareRendering ? Text.Outline : Text.Normal
      styleColor: softwareRendering ? ColorScope.backgroundColor : "transparent"
      font.family: config.name
      font.pointSize: 10
      opacity: 0.5
      Layout.alignment: Qt.AlignHCenter
    }

    Keys.onPressed: {
      if (event.key === Qt.Key_Return ||
        event.key === Qt.Key_Enter) {

        sddm.login(user.objectAt(userButton.currentIndex).userInfo.name, password.text, sessionButton.currentIndex)
        password.enabled = false
        event.accepted = true
      }
    }

  }
}
