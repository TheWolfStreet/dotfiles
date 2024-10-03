/*
    SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2022 Aleix Pol Gonzalez <aleixpol@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.15

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmaComponents.ToolButton {

  // Tooltip
  property string tooltipText: ""

  // Icon properties
  property int iconSize: 22
  property string mainIcon: ""
  property string hoverIcon: mainIcon
  property string clickedIcon: mainIcon

  // Custom event handlers
  property
  var enterHandler: null
  property
  var exitHandler: null
  property
  var clickHandler: null

  Image {
    id: iconID
    anchors {
      verticalCenter: parent.verticalCenter
      horizontalCenter: parent.horizontalCenter
    }
    height: iconSize
    width: iconSize
    mipmap: true
    sourceSize.width: width
    sourceSize.height: height
    source: mainIcon
    fillMode: Image.PreserveAspectFit
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true

    onEntered: {
      iconID.source = hoverIcon
      if (enterHandler) enterHandler()
    }

    onExited: {
      iconID.source = mainIcon
      if (exitHandler) exitHandler()
    }

    onClicked: {
      iconID.source = clickedIcon
      if (clickHandler) clickHandler()
    }
  }

  PlasmaComponents.ToolTip {
    id: tooltip
    text: tooltipText
  }
}