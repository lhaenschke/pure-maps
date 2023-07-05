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

    ''' Managing search for timetables '''

    def __init__(self):
        self._clientID = poor.key.get("DBTRAININFORMATION_CLIENT")
        self._clientSecret = poor.key.get("DBTRAININFORMATION_SECRET")
        self._trains = []
        self._timetable_cache = dict()
        self._eva_chache = dict()

    def search(self, latitude: str, longitude: str, hour: int):
        (status, eva_number) = self._get_eva_number_coor(latitude, longitude)
        if status != 200:
            return "".join((str(status), '|', eva_number))
        
        self._trains = self._get_train_dict(eva_number, datetime.today().strftime('%Y%m%d')[2:], hour, "dp")
        if len(self._trains) > 0 and self._trains[0].get('status') != None:
            return "".join((str(self._trains[0].get('status')), '|', self._trains[0].get('reason')))
        
        return "".join((str(200), '|'))

    def load_destination_informations(self, train_id: str, destination_name: str, hour: int):
        today = datetime.today()
        (ar_time, ar_track) = (None, "")
        for i in range(3):
            (ar_time, ar_track) = self._get_time_from_destination(train_id, destination_name, today.strftime('%Y%m%d')[2:], hour + i)
            if ar_time is not None:
                for i in range(len(self._trains)):
                    if self._trains[i].get('train_id')[:25] == train_id[:25]:
                        return "".join((ar_time[6:8], '|', ar_time[8:], '|', ar_track))

        tomorrow = today + timedelta(days=1)
        hour = 0
        for i in range(3):
            (ar_time, ar_track) = self._get_time_from_destination(train_id, destination_name, tomorrow.strftime('%Y%m%d')[2:], hour + i)
            if ar_time is not None:
                for i in range(len(self._trains)):
                    if self._trains[i].get('train_id')[:25] == train_id[:25]:
                        return "".join((ar_time[6:8], '|', ar_time[8:], '|', ar_track))

    def get_trains(self):
        return self._trains

    def clear_cache(self):
        self._timetable_cache.clear()
        self._eva_chache.clear()

    def _get_eva_number_coor(self, latitude: str, longitude: str):
        cache_key = "".join((str(latitude), str(longitude)))
        if cache_key in self._eva_chache.keys():
            return (200, self._eva_chache.get(cache_key))

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
        if res.status == 200:
            json_data = json.loads(res.read().decode('utf-8'))
            eva_number = json_data['stopPlaces'][0]['evaNumber']
            self._eva_chache[cache_key] = eva_number
            return (res.status, eva_number)
        else:
            return (res.status, res.reason)

    def _get_eva_number_dest_name(self, destination_name: str):
        cache_key = destination_name
        if cache_key in self._eva_chache.keys():
            return (200, self._eva_chache.get(cache_key))
    
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }

        conn.request("GET", "".join((
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-name/{}".format(urllib.parse.quote(destination_name).replace('/', '%2F'))
        )), "", headers)

        res = conn.getresponse()
        if res.status == 200:
            json_data = json.loads(res.read().decode('utf-8'))
            eva_number = json_data['stopPlaces'][0]['evaNumber']
            self._eva_chache[cache_key] = eva_number
            return (res.status, eva_number)
        else:
            return (res.status, res.reason)

    def _get_timetable_str(self, eva_number: str, date: str, hour: int):
        cache_key = "".join((str(eva_number), str(date), str(hour)))
        if cache_key in self._timetable_cache.keys():
            return (200, self._timetable_cache.get(cache_key))
        
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
        if res.status == 200:
            timetable_str = res.read().decode("utf-8")
            self._timetable_cache[cache_key] = timetable_str
            return (res.status, timetable_str)
        else:
            return (res.status, res.reason)
    
    def _get_train_dict(self, eva_number: str, date: str, hour: int, key: str):
        (status, result) = self._get_timetable_str(eva_number, date, hour)
        if status != 200:
            return [dict(status = status, reason = result)]

        xml_root = ET.fromstring(result)
        trains = []

        ''' Get every train that departs from or arrives at given station '''
        for train in xml_root.iter('s'):
            if train.find(key) != None:
                train_type = train.find('tl').attrib.get('c')   if train.find('tl').attrib.get('c')   != None else ""
                name       = train.find(key).attrib.get('l')    if train.find(key).attrib.get('l')    != None else ""
                train_id   = train.attrib.get('id')             if train.attrib.get('id')             != None else ""
                time       = train.find(key).attrib.get('pt')   if train.find(key).attrib.get('pt')   != None else ""
                track      = train.find(key).attrib.get('pp')   if train.find(key).attrib.get('pp')   != None else ""
                stops      = train.find(key).attrib.get('ppth') if train.find(key).attrib.get('ppth') != None else ""

                train_dict = dict(
                    type        = train_type,
                    name        = name,
                    train_id    = train_id,
                    destination = stops.split('|')[-1] if stops != "" else "",
                )
                train_dict["".join((key, "_time_hh"))] = time[6:8] if len(time) > 9 else ""
                train_dict["".join((key, "_time_mm"))] = time[8:]  if len(time) > 9 else ""
                train_dict["".join((key, "_track"))]   = track
                train_dict["".join((key, "_stops"))]   = stops

                trains.append(train_dict)

        ''' Sort trains by time '''
        trains = sorted(trains, key=lambda x: x.get("".join((key, "_time_hh"))))
        trains = sorted(trains, key=lambda x: x.get("".join((key, "_time_mm"))))
        return trains

    def _get_time_from_destination(self, train_id: str, destination_name: str, date: str, hour: int):
        (status, eva_number) = self._get_eva_number_dest_name(destination_name)
        if status != 200:
            return (None, "")

        (status, timetable_xml_str) = self._get_timetable_str(eva_number, date, hour)
        if status != 200:
            return (None, "")
        
        xml_root = ET.fromstring(timetable_xml_str)
        for train in xml_root.iter('s'):
            if train.attrib.get('id')[:25] == train_id[:25]:
                if train.find('ar') != None:
                    return (train.find('ar').attrib.get('pt'), train.find('ar').attrib.get('pp'))

        return (None, "")