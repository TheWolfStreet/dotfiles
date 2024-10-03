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
  property int currentIndex: -1

  visible: menu.count > 1

  Image {
    id: icon
    anchors.centerIn: parent
    height: width = 22
    mipmap: true
    sourceSize.width: width
    sourceSize.height: height
    source: "resources/session.svg"
    fillMode: Image.PreserveAspectFit
  }

  Component.onCompleted: currentIndex = sessionModel.lastIndex

  onClicked: {
    if (menu.visible) {
      menu.dismiss()
      menu.visible = false
    } else {
      const x = root.width / 2 - menu.width / 2
      const y = root.height
      menu.popup(root, x, y)
      menu.visible = true
    }
    tooltip.visible = !menu.visible
  }

  onHoveredChanged: tooltip.visible = hovered && !menu.visible

  signal sessionChanged()

  PlasmaComponents.Menu {
    PlasmaCore.ColorScope.colorGroup: PlasmaCore.Theme.NormalColorGroup
    PlasmaCore.ColorScope.inherit: false

    id: menu

    onClosed: {
      menu.visible = false
      tooltip.visible = !menu.visible
    }

    Instantiator {
      id: instantiator
      model: sessionModel
      onObjectAdded: menu.insertItem(index, object)
      onObjectRemoved: menu.removeItem(object)
      delegate: PlasmaComponents.MenuItem {
        text: model.name
        onTriggered: {
          root.currentIndex = model.index
          sessionChanged()
        }
      }
    }
  }

  PlasmaComponents.ToolTip {
    id: tooltip
    text: "Switch Plasma Session"
  }
}
