/* -*- coding: utf-8-unix -*-
 *
 * Copyright (C) 2023 lhaenschke
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

PagePL {
    id: page
    title: app.tr("Connection-Details")

    property var journey

    Column {
        width: page.width

        Repeater {
            width: page.width

            model: journey.sections

            delegate: Loader {
                property var sectionData: model.modelData
                
                sourceComponent: {
                    switch(sectionData.mode) {
                        case 2: case 4: case 8: return transferComponent
                        default: return connectionComponent
                    }
                }

            }

        }

        Component {
            id: connectionComponent
            
            Column {
                width: page.width
                
                Rectangle {
                    height: 2
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    color: "gray"
                }

                Grid {
                    columns: 2
                    rows: 1
                    anchors.left: parent.left
                    anchors.leftMargin: styler.themeHorizontalPageMargin
                    anchors.right: parent.right
                    anchors.rightMargin: styler.themeHorizontalPageMargin

                    LabelPL {
                        color: styler.themeHighlightColor
                        width: parent.width - (showMoreButton.width)
                        height: implicitHeight + styler.themePaddingMedium
                        text: sectionData.route.line.name + " -> " + sectionData.route.direction
                        font.pixelSize: styler.themeFontSizeLarge
                        verticalAlignment: Text.AlignVCenter
                        truncMode: truncModes.elide
                    }

                    IconButtonPL {
                        id: showMoreButton
                        iconHeight: styler.themeItemSizeSmall * 0.5
                        iconName: styler.iconDown
                        visible: intermediateStopsRepeater.count > 0
                        property bool isDown: true
                        onClicked: {
                            if (showMoreButton.isDown) {
                                showMoreButton.iconName = styler.iconUp;
                            } else {
                                showMoreButton.iconName = styler.iconDown;
                            }
                            showMoreButton.isDown = !showMoreButton.isDown
                        }
                    }
                }

                Rectangle {
                    height: 1
                    anchors.left: parent.left
                    anchors.leftMargin: styler.themeHorizontalPageMargin
                    anchors.right: parent.right
                    anchors.rightMargin: styler.themeHorizontalPageMargin
                    color: "gray"
                }

                Spacer {
                    height: styler.themePaddingMedium
                }

                Grid {
                    columns: 4
                    rows: 1
                    anchors.left: parent.left
                    anchors.leftMargin: styler.themeHorizontalPageMargin
                    anchors.right: parent.right
                    anchors.rightMargin: styler.themeHorizontalPageMargin

                    LabelPL {
                        id: timeHeader
                        width: parent.width / 5
                        horizontalAlignment: Text.AlignLeft
                        text: app.tr("Time")
                    }

                    LabelPL {
                        id: delayHeader
                        width: parent.width / 11
                        horizontalAlignment: Text.AlignLeft
                        text: ""
                    }

                    LabelPL {
                        width: parent.width - (timeHeader.width + delayHeader.width + trackHeader.width)
                        horizontalAlignment: Text.AlignLeft
                        text: app.tr("Station")
                    }

                    LabelPL {
                        id: trackHeader
                        width: parent.width / 8
                        horizontalAlignment: Text.AlignRight
                        text: app.tr("Track")
                    }
                }

                Rectangle {
                    height: 1
                    anchors.left: parent.left
                    anchors.leftMargin: styler.themeHorizontalPageMargin
                    anchors.right: parent.right
                    anchors.rightMargin: styler.themeHorizontalPageMargin
                    color: "gray"
                }

                Spacer {
                    height: styler.themePaddingMedium
                }

                Grid {
                    columns: 4
                    rows: 1
                    anchors.left: parent.left
                    anchors.leftMargin: styler.themeHorizontalPageMargin
                    anchors.right: parent.right
                    anchors.rightMargin: styler.themeHorizontalPageMargin

                    LabelPL {
                        id: timeLabel
                        width: parent.width / 5
                        horizontalAlignment: Text.AlignLeft
                        text: sectionData.scheduledDepartureTime.toLocaleTimeString(Locale.ShortFormat)
                    }

                    LabelPL {
                        id: delayLabel
                        width: parent.width / 11
                        horizontalAlignment: Text.AlignLeft
                        text: sectionData.hasExpectedDepartureTime ? "+" + sectionData.departureDelay : ""
                        color: sectionData.departureDelay > 3 ? "red" : "green"
                    }

                    LabelPL {
                        id: nameLabel
                        width: parent.width - (timeLabel.width + delayLabel.width + trackLabel.width)
                        horizontalAlignment: Text.AlignLeft
                        text: sectionData.from.name
                    }

                    LabelPL {
                        id: trackLabel
                        width: parent.width / 8
                        horizontalAlignment: Text.AlignRight
                        text: sectionData.scheduledDeparturePlatform
                    }
                }

                Spacer {
                    height: styler.themePaddingLarge
                }

                Repeater {
                    id: intermediateStopsRepeater
                    width: page.width
                    visible: !showMoreButton.isDown
                    model: sectionData.intermediateStops

                    delegate: ListItemPL {
                        width: page.width
                        contentHeight: stopColumn.height
                        visible: !showMoreButton.isDown

                        property var stopData: model.modelData

                        Column {
                            id: stopColumn
                            width: page.width

                            Spacer {
                                height: styler.themePaddingSmall
                            }

                            Grid {
                                columns: 4
                                rows: 1
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.rightMargin: 8

                                LabelPL {
                                    width: timeLabel.width
                                    horizontalAlignment: Text.AlignLeft
                                    text: stopData.scheduledDepartureTime.toLocaleTimeString(Locale.ShortFormat)
                                }

                                LabelPL {
                                    width: delayLabel.width
                                    horizontalAlignment: Text.AlignLeft
                                    text: stopData.departureDelay ? "+" + stopData.departureDelay : ""
                                    color: stopData.departureDelay > 3 ? "red" : "green"
                                }

                                LabelPL {
                                    width: nameLabel.width
                                    horizontalAlignment: Text.AlignLeft
                                    text: stopData.stopPoint.name
                                    truncMode: truncModes.elide
                                }

                                LabelPL {
                                    width: trackLabel.width
                                    horizontalAlignment: Text.AlignRight
                                    text: stopData.scheduledPlatform
                                }
                            }

                            Spacer {
                                height: styler.themePaddingSmall
                            }

                        }

                    }

                }

                Spacer {
                    height: styler.themePaddingLarge
                    visible: !showMoreButton.isDown
                }

                Grid {
                    columns: 4
                    rows: 1
                    anchors.left: parent.left
                    anchors.leftMargin: styler.themeHorizontalPageMargin
                    anchors.right: parent.right
                    anchors.rightMargin: styler.themeHorizontalPageMargin

                    LabelPL {
                        width: parent.width / 5
                        horizontalAlignment: Text.AlignLeft
                        text: sectionData.scheduledArrivalTime.toLocaleTimeString(Locale.ShortFormat)
                    }

                    LabelPL {
                        width: parent.width / 11
                        horizontalAlignment: Text.AlignLeft
                        text: sectionData.hasExpectedArrivalTime ? "+" + sectionData.arrivalDelay : ""
                        color: sectionData.arrivalDelay > 3 ? "red" : "green"
                    }

                    LabelPL {
                        width: parent.width - (timeLabel.width + delayLabel.width + trackLabel.width)
                        horizontalAlignment: Text.AlignLeft
                        text: sectionData.to.name
                    }

                    LabelPL {
                        width: parent.width / 8
                        horizontalAlignment: Text.AlignRight
                        text: sectionData.scheduledArrivalPlatform
                    }
                } 
                
                Spacer {
                    height: styler.themePaddingMedium
                }

                Rectangle {
                    height: 2
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    color: "gray"
                }

                Spacer {
                    height: styler.themePaddingLarge
                }

            }

        }

        Component {
            id: transferComponent
            
            Column {
                width: page.width

                LabelPL {
                    color: styler.themeHighlightColor
                    width: parent.width - (showMoreButton.width)
                    height: implicitHeight + styler.themePaddingMedium
                    text: app.tr('Transfer: ') + sectionData.duration / 60 + " " + app.tr('minutes')
                    font.pixelSize: styler.themeFontSizeLarge
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                Spacer {
                    height: styler.themePaddingLarge
                }

            }

        }

    }

}