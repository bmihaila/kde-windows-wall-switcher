/********************************************************************
 This file is part of the KDE project.

Copyright (C) 2012 Martin Gr‰ﬂlin <mgraesslin@kde.org>
Copyright (C) 2012, 2013 Bogdan Mihaila <bogdan.mihaila@gmx.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************/

import QtQuick 1.1
import org.kde.plasma.core 0.1 as PlasmaCore
import org.kde.plasma.components 0.1 as PlasmaComponents
import org.kde.qtextracomponents 0.1
import org.kde.kwin 0.1 as KWin

Item {
    id: presentWindowsTabBox
    property int screenWidth: 1
    property int screenHeight: 1
    property int optimalWidth: screenWidth
    property int optimalHeight: screenHeight
    property int imagePathPrefix: (new Date()).getTime()
    property int standardMargin: 2
    width: optimalWidth
    height: optimalHeight
    focus: true

    function setModel(model) {
        thumbnailListView.model = model;
        thumbnailListView.imageId++;
    }

    function modelChanged() {
        thumbnailListView.imageId++;
    }

    // just to get the margin sizes
    PlasmaCore.FrameSvgItem {
        id: hoverItem
        imagePath: "widgets/viewitem"
        prefix: "hover"
        visible: false
    }

    // to access various properties set by the theme
    PlasmaCore.Theme {
        id: theme
    }

    Rectangle {
        id: background
        anchors {
            fill: parent
            margins: 0
        }
        radius: 0
        color: theme.backgroundColor
        opacity: 0.8
    }

// TODO: if opaque then below ...
//     PlasmaCore.FrameSvgItem {
//         id: background
//         anchors.fill: parent
//         imagePath: "dialogs/background"
//     }

// TODO: if with wallpaper then below ...
//     Image {
//         id: background
//         anchors.fill: parent
//         source: theme.wallpaperPathForSize(parent.width, parent.height)
//     }

    function getContentMargin(screenWidth, screenHeight) {
        var screenPercentage = 10;
        var xMargin = Math.min(100, screenWidth * screenPercentage / 100);
        var yMargin = Math.min(100, screenHeight * screenPercentage / 100);
        return Math.min(xMargin, yMargin);
    }

    GridView {
        id: thumbnailListView
        objectName: "listView"
        signal currentIndexChanged(int index)
        // used for image provider URL to trick Qt into reloading icons when the model changes
        property int imageId: 0
        property int rows: Math.round(Math.sqrt(count))
        property int columns: (rows * rows < count) ? rows + 1 : rows
        property bool mouseMoved: false
        cellWidth: Math.floor(width / columns)
        cellHeight: Math.floor(height / rows)
        clip: true // TODO: try without to see if the borders are not clipped anymore
        keyNavigationWraps: true
        anchors {
            fill: parent
            margins: getContentMargin(background.width, background.height)
        }
        highlight: Rectangle {
            id: highlight
            width: thumbnailListView.cellWidth
            height: thumbnailListView.cellHeight
            radius: 10
            // TODO: see about the theme highlight color
            color: Qt.darker(background.color)
        }
        boundsBehavior: Flickable.StopAtBounds
        delegate: Rectangle {
            // TODO: if at right corner then width - 1 and if at bottom row height - 1
            width: thumbnailListView.cellWidth
            height: thumbnailListView.cellHeight
            radius: 10
            color: "Transparent"
            border {
                width: 1
                color: "white"
            }
            // needed to reset to initial state
            Component.onCompleted: {
                thumbnailListView.mouseMoved = false
            }
            PlasmaComponents.Button {
                id: closeButton
                iconSource: "window-close"
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: hoverItem.margins.top
                    rightMargin: hoverItem.margins.right
                }
                onClicked: {
                    thumbnailListView.model.close(index)
                }
            }
            KWin.ThumbnailItem {
                id: thumbnailItem
                wId: windowId
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: captionItem.top
                    leftMargin: hoverItem.margins.left
                    rightMargin: hoverItem.margins.right
                    topMargin: hoverItem.margins.top + closeButton.height
                    bottomMargin: standardMargin
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: {
                        thumbnailListView.mouseMoved = true
                    }
                    onEntered: {
                        if (thumbnailListView.mouseMoved) {
                            thumbnailListView.currentIndex = index;
                            thumbnailListView.currentIndexChanged(thumbnailListView.currentIndex);
                        }
                    }
                }
            }
            Item {
                id: captionItem
                height: iconItem.height
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: hoverItem.margins.left + standardMargin
                    rightMargin: hoverItem.margins.right
                    bottomMargin: hoverItem.margins.bottom
                }
                Image {
                    id: iconItem
                    source: "image://client/" + index + "/" + presentWindowsTabBox.imagePathPrefix + "-" + thumbnailListView.imageId
                    // TODO: icon size from theme
                    width: 32
                    height: 32
                    sourceSize {
                        width: 32
                        height: 32
                    }
                    anchors {
                        bottom: parent.bottom
                        right: textItem.left
                    }
                }
                Item {
                    id: textItem
                    property int maxWidth: parent.width - iconItem.width - parent.anchors.leftMargin - parent.anchors.rightMargin - anchors.leftMargin - standardMargin * 2
                    width: (textElementSelected.implicitWidth >= maxWidth) ? maxWidth : textElementSelected.implicitWidth
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        leftMargin: standardMargin
                    }
                    Text {
                        id: textElementSelected
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: caption
                        font.italic: minimized
                        font.bold: true
                        visible: index == thumbnailListView.currentIndex
                        color: theme.textColor
                        elide: Text.ElideMiddle
                        anchors.fill: parent
                    }
                    Text {
                        id: textElementNormal
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: caption
                        // TODO: font from theme
                        font.italic: minimized
                        visible: index != thumbnailListView.currentIndex
                        color: theme.textColor
                        elide: Text.ElideMiddle
                        anchors.fill: parent
                    }
                }
            }
        }
    }
    /*
     * Key navigation on outer item for two reasons:
     * @li we have to emit the change signal
     * @li on multiple invocation it does not work on the list view. Focus seems to be lost.
     **/
    Keys.onPressed: {
        if (event.key == Qt.Key_Left) {
            thumbnailListView.moveCurrentIndexLeft();
            thumbnailListView.currentIndexChanged(thumbnailListView.currentIndex);
        } else if (event.key == Qt.Key_Right) {
            thumbnailListView.moveCurrentIndexRight();
            thumbnailListView.currentIndexChanged(thumbnailListView.currentIndex);
        } else if (event.key == Qt.Key_Up) {
            thumbnailListView.moveCurrentIndexUp();
            thumbnailListView.currentIndexChanged(thumbnailListView.currentIndex);
        } else if (event.key == Qt.Key_Down) {
            thumbnailListView.moveCurrentIndexDown();
            thumbnailListView.currentIndexChanged(thumbnailListView.currentIndex);
        }
    }
}
