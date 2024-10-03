/*
    SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2022 Aleix Pol Gonzalez <aleixpol@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmaComponents.ToolButton {
  id: root

  property int currentIndex: keyboard.currentLayout
  onCurrentIndexChanged: keyboard.currentLayout = currentIndex

  visible: keyboard.layouts.length > 1

  Image {
    id: icon
    anchors.centerIn: parent
    width: 22
    height: 22
    sourceSize.width: width
    sourceSize.height: height
    mipmap: true
    source: "resources/keyboard.svg"
  }

  Text {
    id: textElement
    anchors.right: icon.left
    anchors.verticalCenter: icon.verticalCenter
    anchors.rightMargin: 10
    text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "%1", keyboard.layouts[currentIndex].shortName.toUpperCase())
    color: "white"
  }

  checkable: true
  checked: menu.opened

  onToggled: {
    if (checked) {
      const x = root.width / 2 - menu.width / 2
      const y = root.height

      menu.popup(root, x, y)
    } else {
      menu.dismiss()
    }
  }

  signal keyboardLayoutChanged()

  PlasmaComponents.Menu {
    id: menu
    PlasmaCore.ColorScope.colorGroup: PlasmaCore.Theme.NormalColorGroup
    PlasmaCore.ColorScope.inherit: false

    Component.onCompleted: {
      const x = root.width / 2 - menu.width / 2
      const y = root.height
      menu.popup(root, x, y)
    }

    onAboutToShow: {
      if (instantiator.model === null) {
        let layouts = keyboard.layouts
        layouts.sort((a, b) => a.longName.localeCompare(b.longName))
        instantiator.model = layouts
      }
    }

    Instantiator {
      id: instantiator
      model: null
      onObjectAdded: menu.insertItem(index, object)
      onObjectRemoved: menu.removeItem(object)
      delegate: PlasmaComponents.MenuItem {
        text: modelData.longName

        onTriggered: {
          keyboard.currentLayout = keyboard.layouts.indexOf(modelData)
          root.keyboardLayoutChanged()
        }
      }
    }
  }

  PlasmaComponents.ToolTip {
    id: tooltip
    text: "Switch Keyboard Layout"
  }
}