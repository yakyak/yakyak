#!/usr/bin/env python
# coding=utf-8

from collections import OrderedDict
import json
import requests
from bs4 import BeautifulSoup
from itertools import chain


def partitionToOrd(emojis):
    splitted = {
        'single': [],
        'multiple': []
    }

    for emoji in emojis:
        if len(emoji) == 1:
            splitted['single'].append(ord(emoji))
        else:
            splitted['multiple'].append([ord(x) for x in list(emoji)])

    return splitted


def flatten(listOfLists):
    return list(chain.from_iterable(listOfLists))


categories = OrderedDict([
    (u"😃", ("people", "http://emojipedia.org/people/")),
    (u"🐻", ("nature", "http://emojipedia.org/nature/")),
    (u"🍔", ("food", "http://emojipedia.org/food-drink/")),
    (u"⚽", ("activity", "http://emojipedia.org/activity/")),
    (u"🌇", ("travel-places", "http://emojipedia.org/travel-places/")),
    (u"💡", ("objects", "http://emojipedia.org/objects/")),
    (u"🔣", ("symbols", "http://emojipedia.org/symbols/")),
    (u"🎌", ("flags", "http://emojipedia.org/flags/"))
])


def get(theUrl):
    r = requests.get(theUrl)
    soup = BeautifulSoup(r.text, 'html.parser')

    emoji_lis = soup.find("ul", class_="emoji-list").find_all('li')
    # print "Amount of li's: {}".format(len(emoji_lis))

    return [x.find("span", class_="emoji").text.strip() for x in emoji_lis]
    # retur partitionToOrd(emojis_as_chars)

result = []
for key in categories:
    title = categories[key][0]
    print "working on {}".format(title)
    result.append({
        "title": title,
        "range": get(categories[key][1]),
        "representation": key
    })


with open('emoji.coffee', 'w') as fp:
    json.dump(result, fp, indent=2)






