/* -*- coding: utf-8-unix -*-
 *
 * Copyright (C) 2018 lhaenschke
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtPositioning 5.4
import org.puremaps 1.0
import org.kde.kpublictransport 1.0 as KPT
import "."
import "platform"

DialogPL {
    id: page
    title: app.tr("Providers")
    acceptText: app.tr("Save")

    Column {
        id: column
        width: page.width

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: app.tr("Select the providers relevant for your area")
            truncMode: truncModes.none
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        ListView {
            model: backendModel
            
            delegate: ListItemPL {
                id: listItem
                contentHeight: nameLabel.height + styler.themePaddingMedium

                LabelPL {
                    id: nameLabel
                    text: model.name
                }

            }

        }

    }

    KPT.BackendModel {
        id: backendModel
        manager: Manager
    }

    onAccepted: {
        app.pages.pop();
    }

}

// Kirigami.ScrollablePage {
//     id: root
//     title: "Providers"

//     Component {
//         id: backendDelegate
//         Kirigami.AbstractListItem {
//             highlighted: false
//             enabled: model.itemEnabled

//             Item {
//                 anchors.margins: Kirigami.Units.largeSpacing
//                 implicitHeight: childrenRect.height

//                 QQC2.Label {
//                     id: nameLabel
//                     text: model.name
//                     anchors.left: parent.left
//                     anchors.top: parent.top
//                     anchors.right: securityIcon.left
//                     anchors.rightMargin: Kirigami.Units.largeSpacing
//                     // try to retain trailing abbreviations when we have to elide
//                     elide: text.endsWith(")") ? Text.ElideMiddle : Text.ElideRight
//                 }
//                 QQC2.Switch {
//                     id: toggle
//                     checked: model.backendEnabled
//                     onToggled: model.backendEnabled = checked;
//                     anchors.top: parent.top
//                     anchors.right: parent.right
//                 }
//                 QQC2.Label {
//                     anchors.top: nameLabel.bottom
//                     anchors.left: parent.left
//                     anchors.right: toggle.left
//                     anchors.topMargin: Kirigami.Units.smallSpacing
//                     text: model.description
//                     font.italic: true
//                     wrapMode: Text.WordWrap
//                 }
//             }

//             onClicked: {
//                 toggle.toggle(); // does not trigger the signal handler for toggled...
//                 model.backendEnabled = toggle.checked;
//             }
//         }
//     }

//     ListView {
//         model: backendModel
//         delegate: backendDelegate

//         section.property: "countryCode"
//         section.delegate: Kirigami.ListSectionHeader {
//             text: {
//                 switch (section) {
//                     case "":
//                     case "UN":
//                         return "Global";
//                     case "EU":
//                         return 🇪🇺 European Union";
//                     default:
//                         const c = Country.fromAlpha2(section);
//                         return "emoji flag, country name", "%1 %2", c.emojiFlag, c.name;
//                 }

//             }
//         }
//         section.criteria: ViewSection.FullString
//         section.labelPositioning: ViewSection.CurrentLabelAtStart | ViewSection.InlineLabels
//     }
// }
