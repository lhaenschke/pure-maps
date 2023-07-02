# -*- coding: utf-8 -*-

# Copyright (C) 2014 Osmo Salomaa
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""Managing search for timetables."""

import http.client
import json
from datetime import datetime
from datetime import timedelta
import xml.etree.ElementTree as ET
import urllib.parse

import poor
from poor.i18n import _

__all__ = ("TimetableManager",)

class TimetableManager:

    """Managing search for timetables."""

    def __init__(self):
        """Initialize a :class:`TimetableManager` instance."""
        self._clientID = poor.key.get("DBTRAININFORMATION_CLIENT")
        self._clientSecret = poor.key.get("DBTRAININFORMATION_SECRET")
        self.trains = []

    def search(self, latitude: str, longitude: str, hour: int):
        (status, eva_number) = self._get_eva_number_coor(latitude, longitude)
        if status != 200:
            return
        
        (status, timetable_xml_string) = self._get_timetable_str(eva_number, datetime.today().strftime('%Y%m%d')[2:], hour)
        if status != 200:
            return

        xml_root = ET.fromstring(timetable_xml_string)
        self.trains = []

        for train in xml_root.iter('s'):
            if train.find('dp') != None:
                train_type = train.find('tl').attrib.get('c') if train.find('tl').attrib.get('c') != None else ""
                name = train.find('dp').attrib.get('l') if train.find('dp').attrib.get('l') != None else ""
                train_id = train.attrib.get('id') if train.attrib.get('id') != None else ""
                dep_time = train.find('dp').attrib.get('pt') if train.find('dp').attrib.get('pt') != None else ""
                track = train.find('dp').attrib.get('pp') if train.find('dp').attrib.get('pp') != None else ""
                next_stops = train.find('dp').attrib.get('ppth') if train.find('dp').attrib.get('ppth') != None else ""

                self.trains.append(dict(
                    type = train_type,
                    name = name,
                    train_id = train_id,
                    dep_time_hh = dep_time[6:8] if dep_time != "" else "",
                    dep_time_mm = dep_time[8:] if dep_time != "" else "",
                    track = track,
                    destination = next_stops.split('|')[-1] if next_stops != "" else "",
                    next_stops = next_stops,
                    next_stops_informations = [],
                ))

        self.trains = sorted(self.trains, key=lambda x: x.get('dep_time_hh'))
        self.trains = sorted(self.trains, key=lambda x: x.get('dep_time_mm'))

    def load_destination_informations(self, train_id: str, dest_name: str, hour: int):
        for train in self.trains:
            if train.get('train_id') == train_id:
                for (name, dest_time_hh, dest_time_mm, track) in train.get('next_stops_informations'):
                    if name == dest_name:
                        return "".join((dest_time_hh, '|', dest_time_mm, '|', track))
        
        today = datetime.today()
        (dest_arr_time, dest_track) = (None, "")
        for i in range(3):
            (dest_arr_time, dest_track) = self._get_time_from_destination(train_id, dest_name, today.strftime('%Y%m%d')[2:], hour + i)
            if dest_arr_time is not None:
                for i in range(len(self.trains)):
                    if self.trains[i].get('train_id')[:30] == train_id[:30]:
                        self.trains[i]['next_stops_informations'].append((dest_name, dest_arr_time[6:8], dest_arr_time[8:], dest_track))
                        return "".join((dest_arr_time[6:8], '|', dest_arr_time[8:], '|', dest_track))

        tomorrow = today + timedelta(days=1)
        hour = 0
        for i in range(3):
            (dest_arr_time, dest_track) = self._get_time_from_destination(train_id, dest_name, tomorrow.strftime('%Y%m%d')[2:], hour + i)
            if dest_arr_time is not None:
                for i in range(len(self.trains)):
                    if self.trains[i].get('train_id')[:30] == train_id[:30]:
                        self.trains[i]['next_stops_informations'].append((dest_name, dest_arr_time[6:8], dest_arr_time[8:], dest_track))
                        return "".join((dest_arr_time[6:8], '|', dest_arr_time[8:], '|', dest_track))

    def get_trains(self):
        return self.trains

    def _get_eva_number_coor(self, latitude: str, longitude: str) -> str:
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }

        conn.request("GET", "".join((
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-position",
            "?latitude={}".format(latitude),
            "&longitude={}".format(longitude),
            "&groupBy=SALES&limit=1",
        )), "", headers)

        res = conn.getresponse()
        data = res.read()
        json_data = json.loads(data.decode('utf-8'))

        return (res.status, json_data['stopPlaces'][0]['evaNumber'])

    def _get_eva_number_dest_name(self, dest_name: str) -> str:
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }

        conn.request("GET", "".join((
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-name/{}".format(urllib.parse.quote(dest_name).replace('/', '%2F'))
        )), "", headers)

        res = conn.getresponse()
        data = res.read()
        json_data = json.loads(data.decode('utf-8'))

        return (res.status, json_data['stopPlaces'][0]['evaNumber'])

    def _get_timetable_str(self, eva_number: str, date: str, hour: int) -> str:
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")
        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/xml"
            }

        conn.request("GET", "".join((
            "/db-api-marketplace/apis/timetables/v1/plan/",
            "{}/".format(eva_number),
            "{}/".format(date),
            "{:02d}".format(hour),
        )), "", headers)

        res = conn.getresponse()
        data = res.read()

        return (res.status, data.decode("utf-8"))
    
    def _get_time_from_destination(self, train_id: str, dest_name: str, date: str, hour: int) -> str:
        (status, eva_number) = self._get_eva_number_dest_name(dest_name)
        if status != 200:
            return (None, "")

        (status, timetable_xml_str) = self._get_timetable_str(eva_number, date, hour)
        if status != 200:
            return (None, "")
        
        xml_root = ET.fromstring(timetable_xml_str)
        for train in xml_root.iter('s'):
            if train.attrib.get('id')[:30] == train_id[:30]:
                return (train.find('ar').attrib.get('pt'), train.find('dp').attrib.get('pp') if train.find('dp') != None else train.find('ar').attrib.get('pp'))

        return (None, "")