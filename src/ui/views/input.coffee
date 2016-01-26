autosize = require 'autosize'
clipboard = require 'clipboard'
{scrollToBottom, messages} = require './messages'
{later, toggleVisibility} = require '../util'

isModifierKey = (ev) -> ev.altKey || ev.ctrlKey || ev.metaKey || ev.shiftKey
isAltCtrlMeta = (ev) -> ev.altKey || ev.ctrlKey || ev.metaKey

cursorToEnd = (el) -> el.selectionStart = el.selectionEnd = el.value.length

history = []
historyIndex = 0
historyLength = 100
historyBackup = ""

historyPush = (data) ->
    history.push data
    if history.length == historyLength then history.shift()
    historyIndex = history.length

historyWalk = (el, offset) ->
    # if we are starting to dive into history be backup current message
    if offset is -1 and historyIndex is history.length then historyBackup = el.value
    historyIndex = historyIndex + offset
    # constrain index
    if historyIndex < 0 then historyIndex = 0
    if historyIndex > history.length then historyIndex = history.length
    # if don't have history value restore 'current message'
    val = history[historyIndex] or historyBackup
    el.value = val
    setTimeout (-> cursorToEnd el), 1

lastConv = null

# TODO Import emojiRanges from a separate file and have a nicely indented version of this array in there
emojiCategories = [{"range": ["\ud83d\ude00", "\ud83d\ude01", "\ud83d\ude02", "\ud83d\ude03", "\ud83d\ude04", "\ud83d\ude05", "\ud83d\ude06", "\ud83d\ude09", "\ud83d\ude0a", "\ud83d\ude0b", "\ud83d\ude0e", "\ud83d\ude0d", "\ud83d\ude18", "\ud83d\ude17", "\ud83d\ude19", "\ud83d\ude1a", "\u263a", "\ud83d\ude42", "\ud83e\udd17", "\ud83d\ude07", "\ud83e\udd14", "\ud83d\ude10", "\ud83d\ude11", "\ud83d\ude36", "\ud83d\ude44", "\ud83d\ude0f", "\ud83d\ude23", "\ud83d\ude25", "\ud83d\ude2e", "\ud83e\udd10", "\ud83d\ude2f", "\ud83d\ude2a", "\ud83d\ude2b", "\ud83d\ude34", "\ud83d\ude0c", "\ud83e\udd13", "\ud83d\ude1b", "\ud83d\ude1c", "\ud83d\ude1d", "\u2639", "\ud83d\ude41", "\ud83d\ude12", "\ud83d\ude13", "\ud83d\ude14", "\ud83d\ude15", "\ud83d\ude16", "\ud83d\ude43", "\ud83d\ude37", "\ud83e\udd12", "\ud83e\udd15", "\ud83e\udd11", "\ud83d\ude32", "\ud83d\ude1e", "\ud83d\ude1f", "\ud83d\ude24", "\ud83d\ude22", "\ud83d\ude2d", "\ud83d\ude26", "\ud83d\ude27", "\ud83d\ude28", "\ud83d\ude29", "\ud83d\ude2c", "\ud83d\ude30", "\ud83d\ude31", "\ud83d\ude33", "\ud83d\ude35", "\ud83d\ude21", "\ud83d\ude20", "\ud83d\udc7f", "\ud83d\ude08", "\ud83d\udc66", "\ud83d\udc67", "\ud83d\udc68", "\ud83d\udc69", "\ud83d\udc74", "\ud83d\udc75", "\ud83d\udc76", "\ud83d\udc71", "\ud83d\udc6e", "\ud83d\udc72", "\ud83d\udc73", "\ud83d\udc77", "\u26d1", "\ud83d\udc78", "\ud83d\udc82", "\ud83c\udf85", "\ud83d\udc7c", "\ud83d\udd75", "\ud83d\udc6f", "\ud83d\udc86", "\ud83d\udc87", "\ud83d\udc70", "\ud83d\ude4d", "\ud83d\ude4e", "\ud83d\ude45", "\ud83d\ude46", "\ud83d\udc81", "\ud83d\ude4b", "\ud83d\ude47", "\ud83d\ude4c", "\ud83d\ude4f", "\ud83d\udde3", "\ud83d\udc64", "\ud83d\udc65", "\ud83d\udeb6", "\ud83c\udfc3", "\ud83d\udc83", "\ud83d\udd74", "\ud83d\udc8f", "\ud83d\udc91", "\ud83d\udc6a", "\ud83d\udc6b", "\ud83d\udc6c", "\ud83d\udc6d", "\ud83d\udcaa", "\ud83d\udc48", "\ud83d\udc49", "\u261d", "\ud83d\udc46", "\ud83d\udd95", "\ud83d\udc47", "\u270c", "\ud83d\udd96", "\ud83e\udd18", "\ud83d\udd90", "\u270a", "\u270b", "\ud83d\udc4a", "\ud83d\udc4c", "\ud83d\udc4d", "\ud83d\udc4e", "\ud83d\udc4b", "\ud83d\udc4f", "\ud83d\udc50", "\u270d", "\ud83d\udc85", "\ud83d\udc63", "\ud83d\udc40", "\ud83d\udc41", "\ud83d\udc42", "\ud83d\udc43", "\ud83d\udc45", "\ud83d\udc44", "\ud83d\udc8b", "\ud83d\udc53", "\ud83d\udd76", "\ud83d\udc54", "\ud83d\udc55", "\ud83d\udc56", "\ud83d\udc57", "\ud83d\udc58", "\ud83d\udc59", "\ud83d\udc5a", "\ud83d\udc5b", "\ud83d\udc5c", "\ud83d\udc5d", "\ud83c\udf92", "\ud83d\udc5e", "\ud83d\udc5f", "\ud83d\udc60", "\ud83d\udc61", "\ud83d\udc62", "\ud83d\udc51", "\ud83d\udc52", "\ud83c\udfa9", "\ud83d\udc84", "\ud83d\udc8d", "\ud83d\udc79", "\ud83d\udc7a", "\ud83d\udc7b", "\ud83d\udc80", "\ud83d\udc7d", "\ud83e\udd16", "\ud83d\udca9", "\ud83d\ude38", "\ud83d\ude39", "\ud83d\ude3a", "\ud83d\ude3b", "\ud83d\ude3c", "\ud83d\ude3d", "\ud83d\ude3e", "\ud83d\ude3f", "\ud83d\ude40", "\ud83c\udf02", "\ud83c\udf93", "\ud83d\udcbc", "\ud83d\udc68\u200d\ud83d\udc69\u200d\ud83d\udc67", "\ud83d\udc68\u200d\ud83d\udc69\u200d\ud83d\udc67\u200d\ud83d\udc66", "\ud83d\udc68\u200d\ud83d\udc69\u200d\ud83d\udc66\u200d\ud83d\udc66", "\ud83d\udc68\u200d\ud83d\udc69\u200d\ud83d\udc67\u200d\ud83d\udc67", "\ud83d\udc69\u200d\ud83d\udc69\u200d\ud83d\udc66", "\ud83d\udc69\u200d\ud83d\udc69\u200d\ud83d\udc67", "\ud83d\udc69\u200d\ud83d\udc69\u200d\ud83d\udc67\u200d\ud83d\udc66", "\ud83d\udc69\u200d\ud83d\udc69\u200d\ud83d\udc66\u200d\ud83d\udc66", "\ud83d\udc69\u200d\ud83d\udc69\u200d\ud83d\udc67\u200d\ud83d\udc67", "\ud83d\udc68\u200d\ud83d\udc68\u200d\ud83d\udc66", "\ud83d\udc68\u200d\ud83d\udc68\u200d\ud83d\udc67", "\ud83d\udc68\u200d\ud83d\udc68\u200d\ud83d\udc67\u200d\ud83d\udc66", "\ud83d\udc68\u200d\ud83d\udc68\u200d\ud83d\udc66\u200d\ud83d\udc66", "\ud83d\udc68\u200d\ud83d\udc68\u200d\ud83d\udc67\u200d\ud83d\udc67", "\ud83d\udc69\u200d\u2764\ufe0f\u200d\ud83d\udc69", "\ud83d\udc68\u200d\u2764\ufe0f\u200d\ud83d\udc68", "\ud83d\udc69\u200d\u2764\ufe0f\u200d\ud83d\udc8b\u200d\ud83d\udc69", "\ud83d\udc68\u200d\u2764\ufe0f\u200d\ud83d\udc8b\u200d\ud83d\udc68"], "representation": "\ud83d\ude03", "title": "people"}, {"range": ["\ud83d\udca7", "\ud83d\udca6", "\ud83d\udca8", "\ud83d\udc35", "\ud83d\ude48", "\ud83d\ude49", "\ud83d\ude4a", "\ud83d\udc12", "\ud83d\udc36", "\ud83d\udc15", "\ud83d\udc29", "\ud83d\udc3a", "\ud83d\udc31", "\ud83d\udc08", "\ud83e\udd81", "\ud83d\udc2f", "\ud83d\udc05", "\ud83d\udc06", "\ud83d\udc34", "\ud83d\udc0e", "\ud83e\udd84", "\ud83d\udc2e", "\ud83d\udc02", "\ud83d\udc03", "\ud83d\udc04", "\ud83d\udc37", "\ud83d\udc16", "\ud83d\udc17", "\ud83d\udc3d", "\ud83d\udc0f", "\ud83d\udc11", "\ud83d\udc10", "\ud83d\udc2a", "\ud83d\udc2b", "\ud83d\udc18", "\ud83d\udc2d", "\ud83d\udc01", "\ud83d\udc00", "\ud83d\udc39", "\ud83d\udc30", "\ud83d\udc07", "\ud83d\udc3f", "\ud83d\udc3b", "\ud83d\udc28", "\ud83d\udc3c", "\ud83d\udc3e", "\ud83e\udd83", "\ud83d\udc14", "\ud83d\udc13", "\ud83d\udc23", "\ud83d\udc24", "\ud83d\udc25", "\ud83d\udc26", "\ud83d\udc27", "\ud83d\udd4a", "\ud83d\udc38", "\ud83d\udc0a", "\ud83d\udc22", "\ud83d\udc0d", "\ud83d\udc32", "\ud83d\udc09", "\ud83d\udc33", "\ud83d\udc0b", "\ud83d\udc2c", "\ud83d\udc1f", "\ud83d\udc20", "\ud83d\udc21", "\ud83d\udc19", "\ud83d\udc1a", "\ud83e\udd80", "\ud83d\udc0c", "\ud83d\udc1b", "\ud83d\udc1c", "\ud83d\udc1d", "\ud83d\udc1e", "\ud83d\udd77", "\ud83d\udd78", "\ud83e\udd82", "\ud83d\udc90", "\ud83c\udf38", "\ud83d\udcae", "\ud83c\udff5", "\ud83c\udf39", "\ud83c\udf3a", "\ud83c\udf3b", "\ud83c\udf3c", "\ud83c\udf37", "\u2618", "\ud83c\udf31", "\ud83c\udf32", "\ud83c\udf33", "\ud83c\udf34", "\ud83c\udf35", "\ud83c\udf3e", "\ud83c\udf3f", "\ud83c\udf40", "\ud83c\udf41", "\ud83c\udf42", "\ud83c\udf43", "\ud83c\udf0d", "\ud83c\udf0e", "\ud83c\udf0f", "\ud83c\udf10", "\ud83c\udf0a", "\ud83c\udf11", "\ud83c\udf12", "\ud83c\udf13", "\ud83c\udf14", "\ud83c\udf15", "\ud83c\udf16", "\ud83c\udf17", "\ud83c\udf18", "\ud83c\udf19", "\ud83c\udf1a", "\ud83c\udf1b", "\ud83c\udf1c", "\u2600", "\ud83c\udf1d", "\ud83c\udf1e", "\u2601", "\u26c5", "\u26c8", "\ud83c\udf24", "\ud83c\udf25", "\ud83c\udf26", "\ud83c\udf27", "\ud83c\udf28", "\ud83c\udf29", "\ud83c\udf2a", "\ud83c\udf2b", "\ud83c\udf2c", "\u2602", "\u2614", "\u2744", "\u2603", "\ud83c\udf1f", "\ud83c\udf20", "\u2604", "\ud83d\udd25", "\u26a1", "\u2b50"], "representation": "\ud83d\udc3b", "title": "nature"}, {"range": ["\ud83c\udf47", "\ud83c\udf48", "\ud83c\udf49", "\ud83c\udf4a", "\ud83c\udf4b", "\ud83c\udf4c", "\ud83c\udf4d", "\ud83c\udf4e", "\ud83c\udf4f", "\ud83c\udf50", "\ud83c\udf51", "\ud83c\udf52", "\ud83c\udf53", "\ud83c\udf45", "\ud83c\udf46", "\ud83c\udf3d", "\ud83c\udf36", "\ud83c\udf44", "\ud83c\udf30", "\ud83c\udf5e", "\ud83e\uddc0", "\ud83c\udf56", "\ud83c\udf57", "\ud83c\udf54", "\ud83c\udf5f", "\ud83c\udf55", "\ud83c\udf2d", "\ud83c\udf2e", "\ud83c\udf2f", "\ud83c\udf7f", "\ud83c\udf72", "\ud83c\udf71", "\ud83c\udf58", "\ud83c\udf59", "\ud83c\udf5a", "\ud83c\udf5b", "\ud83c\udf5c", "\ud83c\udf5d", "\ud83c\udf60", "\ud83c\udf62", "\ud83c\udf63", "\ud83c\udf64", "\ud83c\udf65", "\ud83c\udf61", "\ud83c\udf66", "\ud83c\udf67", "\ud83c\udf68", "\ud83c\udf69", "\ud83c\udf6a", "\ud83c\udf82", "\ud83c\udf70", "\ud83c\udf6b", "\ud83c\udf6c", "\ud83c\udf6d", "\ud83c\udf6e", "\ud83c\udf6f", "\ud83c\udf7c", "\u2615", "\ud83c\udf75", "\ud83c\udf76", "\ud83c\udf7e", "\ud83c\udf77", "\ud83c\udf78", "\ud83c\udf79", "\ud83c\udf7a", "\ud83c\udf7b", "\ud83c\udf7d", "\ud83c\udf74", "\ud83c\udf73"], "representation": "\ud83c\udf54", "title": "food"}, {"range": ["\ud83d\udd74", "\ud83d\udc7e", "\ud83c\udfaa", "\ud83c\udfad", "\ud83c\udfa8", "\ud83c\udfb0", "\ud83d\udea3", "\ud83d\udec0", "\ud83c\udfaf", "\ud83c\udf96", "\ud83c\udf97", "\ud83c\udf9f", "\ud83c\udfab", "\u26bd", "\u26be", "\ud83c\udfc0", "\ud83c\udfc8", "\ud83c\udfc9", "\ud83c\udfbe", "\ud83c\udfb1", "\ud83c\udfb3", "\u26f3", "\ud83c\udfcc", "\u26f8", "\ud83c\udfa3", "\ud83c\udfbd", "\ud83c\udfbf", "\u26f7", "\ud83c\udfc2", "\ud83c\udfc4", "\ud83c\udfc7", "\ud83c\udfca", "\u26f9", "\ud83c\udfcb", "\ud83d\udeb4", "\ud83d\udeb5", "\ud83c\udfc5", "\ud83c\udfc6", "\ud83c\udfcf", "\ud83c\udfd0", "\ud83c\udfd1", "\ud83c\udfd2", "\ud83c\udfd3", "\ud83c\udff8", "\ud83c\udfae", "\ud83c\udfb2", "\ud83c\udfb7", "\ud83c\udfb8", "\ud83c\udfba", "\ud83c\udfbb", "\ud83c\udfac", "\ud83c\udff9"], "representation": "\u26bd", "title": "activity"}, {"range": ["\ud83c\udfd4", "\u26f0", "\ud83c\udf0b", "\ud83d\uddfb", "\ud83c\udfd5", "\ud83c\udfd6", "\ud83c\udfdc", "\ud83c\udfdd", "\ud83c\udfde", "\ud83c\udfdf", "\ud83c\udfdb", "\ud83c\udfd7", "\ud83c\udfd8", "\ud83c\udfd9", "\ud83c\udfda", "\ud83c\udfe0", "\ud83c\udfe1", "\u26ea", "\ud83d\udd4b", "\ud83d\udd4c", "\ud83d\udd4d", "\ud83c\udfe2", "\ud83c\udfe3", "\ud83c\udfe4", "\ud83c\udfe5", "\ud83c\udfe6", "\ud83c\udfe8", "\ud83c\udfe9", "\ud83c\udfea", "\ud83c\udfeb", "\ud83c\udfec", "\ud83c\udfed", "\ud83c\udfef", "\ud83c\udff0", "\ud83d\udc92", "\ud83d\uddfc", "\ud83d\uddfd", "\u26f2", "\ud83c\udf01", "\ud83c\udf03", "\ud83c\udf06", "\ud83c\udf07", "\ud83c\udf09", "\ud83d\uddff", "\ud83c\udf0c", "\ud83c\udfa0", "\ud83c\udfa1", "\ud83c\udfa2", "\ud83d\ude82", "\ud83d\ude83", "\ud83d\ude84", "\ud83d\ude85", "\ud83d\ude86", "\ud83d\ude87", "\ud83d\ude88", "\ud83d\ude89", "\ud83d\ude8a", "\ud83d\ude9d", "\ud83d\ude9e", "\ud83d\ude8b", "\ud83d\ude8c", "\ud83d\ude8d", "\ud83d\ude8e", "\ud83d\ude8f", "\ud83d\ude90", "\ud83d\ude91", "\ud83d\ude92", "\ud83d\ude93", "\ud83d\ude94", "\ud83d\ude95", "\ud83d\ude96", "\ud83d\ude97", "\ud83d\ude98", "\ud83d\ude9a", "\ud83d\ude9b", "\ud83d\ude9c", "\ud83d\udeb2", "\u26fd", "\ud83d\udee4", "\ud83d\udea8", "\u2693", "\u26f5", "\ud83d\udea3", "\ud83d\udea4", "\ud83d\udef3", "\u26f4", "\ud83d\udee5", "\ud83d\udea2", "\u2708", "\ud83d\udee9", "\ud83d\udeeb", "\ud83d\udeec", "\ud83d\udcba", "\ud83d\ude81", "\ud83d\ude9f", "\ud83d\udea0", "\ud83d\udea1", "\ud83d\ude80", "\ud83d\udef0", "\ud83d\udea5", "\ud83d\udea6", "\ud83d\udea7", "\ud83d\udec2", "\ud83d\udec3", "\ud83d\udec4", "\ud83d\udec5", "\ud83c\udfce", "\ud83c\udfcd", "\ud83d\udcb4", "\ud83d\udcb5", "\ud83d\udcb6", "\ud83d\udcb7", "\u26e9"], "representation": "\ud83c\udf07", "title": "travel-places"}, {"range": ["\ud83d\udc8c", "\ud83d\udca3", "\ud83d\udd73", "\ud83d\udecd", "\ud83d\udcff", "\ud83d\udc8e", "\u2620", "\ud83c\udffa", "\ud83d\uddfa", "\ud83d\uddff", "\ud83d\udc88", "\ud83d\uddbc", "\ud83d\udee2", "\ud83d\udece", "\ud83d\udeaa", "\ud83d\udecc", "\ud83d\udecf", "\ud83d\udecb", "\ud83d\udebd", "\ud83d\udebf", "\ud83d\udec1", "\u231b", "\u23f3", "\u231a", "\u23f0", "\u23f1", "\u23f2", "\ud83d\udd70", "\ud83c\udf21", "\u26f1", "\ud83c\udf88", "\ud83c\udf89", "\ud83c\udf8a", "\ud83c\udf8c", "\ud83c\udf8e", "\ud83c\udf8f", "\ud83c\udf90", "\ud83c\udf80", "\ud83c\udf81", "\ud83c\udf9e", "\ud83c\udff7", "\ud83d\udd79", "\ud83d\udcef", "\ud83c\udf99", "\ud83c\udf9a", "\ud83c\udf9b", "\ud83d\udcfb", "\ud83d\udcf1", "\ud83d\udcf2", "\u260e", "\ud83d\udcde", "\ud83d\udcdf", "\ud83d\udce0", "\ud83d\udd0b", "\ud83d\udd0c", "\ud83d\udcbb", "\ud83d\udda5", "\ud83d\udda8", "\u2328", "\ud83d\uddb1", "\ud83d\uddb2", "\ud83d\udcbd", "\ud83d\udcbe", "\ud83d\udcbf", "\ud83d\udcc0", "\ud83c\udfa5", "\ud83d\udcfd", "\ud83d\udcfa", "\ud83d\udcf7", "\ud83d\udcf8", "\ud83d\udcf9", "\ud83d\udcfc", "\ud83d\udd0d", "\ud83d\udd0e", "\ud83d\udd2c", "\ud83d\udd2d", "\ud83d\udce1", "\ud83d\udd6f", "\ud83d\udca1", "\ud83d\udd26", "\ud83c\udfee", "\ud83d\udcd4", "\ud83d\udcd5", "\ud83d\udcd6", "\ud83d\udcd7", "\ud83d\udcd8", "\ud83d\udcd9", "\ud83d\udcda", "\ud83d\udcd3", "\ud83d\udcc3", "\ud83d\udcdc", "\ud83d\udcc4", "\ud83d\udcf0", "\ud83d\uddde", "\ud83d\udcd1", "\ud83d\udd16", "\ud83d\udcb0", "\ud83d\udcb4", "\ud83d\udcb5", "\ud83d\udcb6", "\ud83d\udcb7", "\ud83d\udcb8", "\ud83d\udcb3", "\u2709", "\ud83d\udce7", "\ud83d\udce8", "\ud83d\udce9", "\ud83d\udce4", "\ud83d\udce5", "\ud83d\udce6", "\ud83d\udceb", "\ud83d\udcea", "\ud83d\udcec", "\ud83d\udced", "\ud83d\udcee", "\ud83d\uddf3", "\u270f", "\u2712", "\ud83d\udd8b", "\ud83d\udd8a", "\ud83d\udd8c", "\ud83d\udd8d", "\ud83d\udcdd", "\ud83d\udcc1", "\ud83d\udcc2", "\ud83d\uddc2", "\ud83d\udcc5", "\ud83d\udcc6", "\ud83d\uddd2", "\ud83d\uddd3", "\ud83d\udcc7", "\ud83d\udcc8", "\ud83d\udcc9", "\ud83d\udcca", "\ud83d\udccb", "\ud83d\udccc", "\ud83d\udccd", "\ud83d\udcce", "\ud83d\udd87", "\ud83d\udccf", "\ud83d\udcd0", "\u2702", "\ud83d\uddc3", "\ud83d\uddc4", "\ud83d\uddd1", "\ud83d\udd12", "\ud83d\udd13", "\ud83d\udd0f", "\ud83d\udd10", "\ud83d\udd11", "\ud83d\udddd", "\ud83d\udd28", "\u26cf", "\u2692", "\ud83d\udee0", "\ud83d\udd27", "\ud83d\udd29", "\u2699", "\ud83d\udddc", "\u2697", "\u2696", "\ud83d\udd17", "\u26d3", "\ud83d\udc89", "\ud83d\udc8a", "\ud83d\udde1", "\ud83d\udd2a", "\u2694", "\ud83d\udd2b", "\ud83d\udee1", "\ud83d\udeac", "\u26b0", "\u26b1", "\ud83c\udff3", "\ud83c\udff4", "\ud83d\udea9", "\ud83d\udd2e"], "representation": "\ud83d\udca1", "title": "objects"}, {"range": ["\ud83d\udc98", "\u2764", "\ud83d\udc93", "\ud83d\udc94", "\ud83d\udc95", "\ud83d\udc96", "\ud83d\udc97", "\ud83d\udc99", "\ud83d\udc9a", "\ud83d\udc9b", "\ud83d\udc9c", "\ud83d\udc9d", "\ud83d\udc9e", "\ud83d\udc9f", "\u2763", "\ud83d\udca4", "\ud83d\udca2", "\ud83d\udcac", "\ud83d\udcad", "\ud83d\uddef", "\ud83d\udcae", "\ud83d\uded0", "\u2668", "\ud83d\udc88", "\ud83d\udeb3", "\ud83d\udd31", "\ud83c\udfe7", "\ud83d\udeae", "\ud83d\udeab", "\ud83d\udead", "\ud83d\udeaf", "\ud83d\udeb0", "\ud83d\udeb1", "\ud83d\udeb7", "\ud83d\udeb8", "\u267f", "\ud83d\udeb9", "\ud83d\udeba", "\ud83d\udebb", "\ud83d\udebc", "\ud83d\udebe", "\u26a0", "\u26d4", "\ud83d\udd5b", "\ud83d\udd67", "\ud83d\udd50", "\ud83d\udd5c", "\ud83d\udd51", "\ud83d\udd5d", "\ud83d\udd52", "\ud83d\udd5e", "\ud83d\udd53", "\ud83d\udd5f", "\ud83d\udd54", "\ud83d\udd60", "\ud83d\udd55", "\ud83d\udd61", "\ud83d\udd56", "\ud83d\udd62", "\ud83d\udd57", "\ud83d\udd63", "\ud83d\udd58", "\ud83d\udd64", "\ud83d\udd59", "\ud83d\udd65", "\ud83d\udd5a", "\ud83d\udd66", "\u2648", "\u2649", "\u264a", "\u264b", "\u264c", "\u264d", "\u264e", "\u264f", "\u2650", "\u2651", "\u2652", "\u2653", "\u26ce", "\ud83c\udf00", "\ud83d\udd4e", "\ud83c\udfb4", "\u2660", "\u2665", "\u2666", "\u2663", "\ud83c\udc04", "\ud83d\udd07", "\ud83d\udd08", "\ud83d\udd09", "\ud83d\udd0a", "\ud83d\udce2", "\ud83d\udce3", "\ud83d\udcef", "\ud83d\udd14", "\ud83d\udd15", "\ud83d\udd00", "\ud83d\udd01", "\ud83d\udd02", "\u25b6", "\u23e9", "\u25c0", "\u23ea", "\ud83d\udd3c", "\u23eb", "\ud83d\udd3d", "\u23ec", "\u23f9", "\ud83d\udcf3", "\ud83d\udcf4", "#\u20e3", "0\u20e3", "1\u20e3", "2\u20e3", "3\u20e3", "4\u20e3", "5\u20e3", "6\u20e3", "7\u20e3", "8\u20e3", "9\u20e3", "\ud83d\udd1f", "\ud83d\udcf6", "\ud83c\udfa6", "\ud83d\udd05", "\ud83d\udd06", "\u2b06", "\u2197", "\u27a1", "\u2198", "\u2b07", "\u2199", "\u2b05", "\u2196", "\u2195", "\u2194", "\u21a9", "\u21aa", "\u2934", "\u2935", "\ud83d\udd03", "\ud83d\udd04", "\ud83d\udd19", "\ud83d\udd1a", "\ud83d\udd1b", "\ud83d\udd1c", "\ud83d\udd1d", "\ud83d\udd30", "\u269b", "\ud83d\udd49", "\u2721", "\u2638", "\u262f", "\u271d", "\u2626", "\u262a", "\u262e", "\ud83d\udd2f", "\u267b", "\u2622", "\u2623", "\u2b55", "\u2705", "\u2611", "\u2714", "\u2716", "\u274c", "\u274e", "\u2795", "\u2796", "\u2797", "\u27b0", "\u27bf", "\u303d", "\u2733", "\u2734", "\u2747", "\u203c", "\u2049", "\u2753", "\u2754", "\u2755", "\u2757", "\u00a9", "\u00ae", "\u2122", "\ud83d\udcaf", "\ud83d\udd1e", "\ud83d\udd20", "\ud83d\udd21", "\ud83d\udd22", "\ud83d\udd23", "\ud83d\udd24", "\ud83c\udd70", "\ud83c\udd8e", "\ud83c\udd71", "\ud83c\udd91", "\ud83c\udd92", "\ud83c\udd93", "\u2139", "\ud83c\udd94", "\u24c2", "\ud83c\udd95", "\ud83c\udd96", "\ud83c\udd7e", "\ud83c\udd97", "\ud83c\udd7f", "\ud83c\udd98", "\ud83c\udd99", "\ud83c\udd9a", "\ud83c\ude01", "\ud83c\ude02", "\ud83c\ude37", "\ud83c\ude36", "\ud83c\ude2f", "\ud83c\ude50", "\ud83c\ude39", "\ud83c\ude1a", "\ud83c\ude32", "\ud83c\ude51", "\ud83c\ude38", "\ud83c\ude34", "\ud83c\ude33", "\u3297", "\u3299", "\ud83c\ude3a", "\ud83c\ude35", "\u25aa", "\u25ab", "\u25fb", "\u25fc", "\u25fd", "\u25fe", "\u2b1b", "\u2b1c", "\ud83d\udd36", "\ud83d\udd37", "\ud83d\udd38", "\ud83d\udd39", "\ud83d\udd3a", "\ud83d\udd3b", "\ud83d\udca0", "\ud83d\udd32", "\ud83d\udd33", "\u26aa", "\u26ab", "\ud83d\udd34", "\ud83d\udd35", "\ud83d\udc41\u200d\ud83d\udde8"], "representation": "\ud83d\udd23", "title": "symbols"}, {"range": ["\ud83c\udde6\ud83c\uddeb", "\ud83c\udde6\ud83c\uddfd", "\ud83c\udde6\ud83c\uddf1", "\ud83c\udde9\ud83c\uddff", "\ud83c\udde6\ud83c\uddf8", "\ud83c\udde6\ud83c\udde9", "\ud83c\udde6\ud83c\uddf4", "\ud83c\udde6\ud83c\uddee", "\ud83c\udde6\ud83c\uddf6", "\ud83c\udde6\ud83c\uddec", "\ud83c\udde6\ud83c\uddf7", "\ud83c\udde6\ud83c\uddf2", "\ud83c\udde6\ud83c\uddfc", "\ud83c\udde6\ud83c\udde8", "\ud83c\udde6\ud83c\uddfa", "\ud83c\udde6\ud83c\uddf9", "\ud83c\udde6\ud83c\uddff", "\ud83c\udde7\ud83c\uddf8", "\ud83c\udde7\ud83c\udded", "\ud83c\udde7\ud83c\udde9", "\ud83c\udde7\ud83c\udde7", "\ud83c\udde7\ud83c\uddfe", "\ud83c\udde7\ud83c\uddea", "\ud83c\udde7\ud83c\uddff", "\ud83c\udde7\ud83c\uddef", "\ud83c\udde7\ud83c\uddf2", "\ud83c\udde7\ud83c\uddf9", "\ud83c\udde7\ud83c\uddf4", "\ud83c\udde7\ud83c\udde6", "\ud83c\udde7\ud83c\uddfc", "\ud83c\udde7\ud83c\uddfb", "\ud83c\udde7\ud83c\uddf7", "\ud83c\uddee\ud83c\uddf4", "\ud83c\uddfb\ud83c\uddec", "\ud83c\udde7\ud83c\uddf3", "\ud83c\udde7\ud83c\uddec", "\ud83c\udde7\ud83c\uddeb", "\ud83c\udde7\ud83c\uddee", "\ud83c\uddf0\ud83c\udded", "\ud83c\udde8\ud83c\uddf2", "\ud83c\udde8\ud83c\udde6", "\ud83c\uddee\ud83c\udde8", "\ud83c\udde8\ud83c\uddfb", "\ud83c\udde7\ud83c\uddf6", "\ud83c\uddf0\ud83c\uddfe", "\ud83c\udde8\ud83c\uddeb", "\ud83c\uddea\ud83c\udde6", "\ud83c\uddf9\ud83c\udde9", "\ud83c\udde8\ud83c\uddf1", "\ud83c\udde8\ud83c\uddf3", "\ud83c\udde8\ud83c\uddfd", "\ud83c\udde8\ud83c\uddf5", "\ud83c\udde8\ud83c\udde8", "\ud83c\udde8\ud83c\uddf4", "\ud83c\uddf0\ud83c\uddf2", "\ud83c\udde8\ud83c\uddec", "\ud83c\udde8\ud83c\udde9", "\ud83c\udde8\ud83c\uddf0", "\ud83c\udde8\ud83c\uddf7", "\ud83c\udde8\ud83c\uddee", "\ud83c\udded\ud83c\uddf7", "\ud83c\udde8\ud83c\uddfa", "\ud83c\udde8\ud83c\uddfc", "\ud83c\udde8\ud83c\uddfe", "\ud83c\udde8\ud83c\uddff", "\ud83c\udde9\ud83c\uddf0", "\ud83c\udde9\ud83c\uddec", "\ud83c\udde9\ud83c\uddef", "\ud83c\udde9\ud83c\uddf2", "\ud83c\udde9\ud83c\uddf4", "\ud83c\uddea\ud83c\udde8", "\ud83c\uddea\ud83c\uddec", "\ud83c\uddf8\ud83c\uddfb", "\ud83c\uddec\ud83c\uddf6", "\ud83c\uddea\ud83c\uddf7", "\ud83c\uddea\ud83c\uddea", "\ud83c\uddea\ud83c\uddf9", "\ud83c\uddea\ud83c\uddfa", "\ud83c\uddeb\ud83c\uddf0", "\ud83c\uddeb\ud83c\uddf4", "\ud83c\uddeb\ud83c\uddef", "\ud83c\uddeb\ud83c\uddee", "\ud83c\uddeb\ud83c\uddf7", "\ud83c\uddec\ud83c\uddeb", "\ud83c\uddf5\ud83c\uddeb", "\ud83c\uddf9\ud83c\uddeb", "\ud83c\uddec\ud83c\udde6", "\ud83c\uddec\ud83c\uddf2", "\ud83c\uddec\ud83c\uddea", "\ud83c\udde9\ud83c\uddea", "\ud83c\uddec\ud83c\udded", "\ud83c\uddec\ud83c\uddee", "\ud83c\uddec\ud83c\uddf7", "\ud83c\uddec\ud83c\uddf1", "\ud83c\uddec\ud83c\udde9", "\ud83c\uddec\ud83c\uddf5", "\ud83c\uddec\ud83c\uddfa", "\ud83c\uddec\ud83c\uddf9", "\ud83c\uddec\ud83c\uddec", "\ud83c\uddec\ud83c\uddf3", "\ud83c\uddec\ud83c\uddfc", "\ud83c\uddec\ud83c\uddfe", "\ud83c\udded\ud83c\uddf9", "\ud83c\udded\ud83c\uddf2", "\ud83c\udded\ud83c\uddf3", "\ud83c\udded\ud83c\uddf0", "\ud83c\udded\ud83c\uddfa", "\ud83c\uddee\ud83c\uddf8", "\ud83c\uddee\ud83c\uddf3", "\ud83c\uddee\ud83c\udde9", "\ud83c\uddee\ud83c\uddf7", "\ud83c\uddee\ud83c\uddf6", "\ud83c\uddee\ud83c\uddea", "\ud83c\uddee\ud83c\uddf2", "\ud83c\uddee\ud83c\uddf1", "\ud83c\uddee\ud83c\uddf9", "\ud83c\uddef\ud83c\uddf2", "\ud83c\uddef\ud83c\uddf5", "\ud83c\uddef\ud83c\uddea", "\ud83c\uddef\ud83c\uddf4", "\ud83c\uddf0\ud83c\uddff", "\ud83c\uddf0\ud83c\uddea", "\ud83c\uddf0\ud83c\uddee", "\ud83c\uddfd\ud83c\uddf0", "\ud83c\uddf0\ud83c\uddfc", "\ud83c\uddf0\ud83c\uddec", "\ud83c\uddf1\ud83c\udde6", "\ud83c\uddf1\ud83c\uddfb", "\ud83c\uddf1\ud83c\udde7", "\ud83c\uddf1\ud83c\uddf8", "\ud83c\uddf1\ud83c\uddf7", "\ud83c\uddf1\ud83c\uddfe", "\ud83c\uddf1\ud83c\uddee", "\ud83c\uddf1\ud83c\uddf9", "\ud83c\uddf1\ud83c\uddfa", "\ud83c\uddf2\ud83c\uddf4", "\ud83c\uddf2\ud83c\uddf0", "\ud83c\uddf2\ud83c\uddec", "\ud83c\uddf2\ud83c\uddfc", "\ud83c\uddf2\ud83c\uddfe", "\ud83c\uddf2\ud83c\uddfb", "\ud83c\uddf2\ud83c\uddf1", "\ud83c\uddf2\ud83c\uddf9", "\ud83c\uddf2\ud83c\udded", "\ud83c\uddf2\ud83c\uddf6", "\ud83c\uddf2\ud83c\uddf7", "\ud83c\uddf2\ud83c\uddfa", "\ud83c\uddfe\ud83c\uddf9", "\ud83c\uddf2\ud83c\uddfd", "\ud83c\uddeb\ud83c\uddf2", "\ud83c\uddf2\ud83c\udde9", "\ud83c\uddf2\ud83c\udde8", "\ud83c\uddf2\ud83c\uddf3", "\ud83c\uddf2\ud83c\uddea", "\ud83c\uddf2\ud83c\uddf8", "\ud83c\uddf2\ud83c\udde6", "\ud83c\uddf2\ud83c\uddff", "\ud83c\uddf2\ud83c\uddf2", "\ud83c\uddf3\ud83c\udde6", "\ud83c\uddf3\ud83c\uddf7", "\ud83c\uddf3\ud83c\uddf5", "\ud83c\uddf3\ud83c\uddf1", "\ud83c\uddf3\ud83c\udde8", "\ud83c\uddf3\ud83c\uddff", "\ud83c\uddf3\ud83c\uddee", "\ud83c\uddf3\ud83c\uddea", "\ud83c\uddf3\ud83c\uddec", "\ud83c\uddf3\ud83c\uddfa", "\ud83c\uddf3\ud83c\uddeb", "\ud83c\uddf2\ud83c\uddf5", "\ud83c\uddf0\ud83c\uddf5", "\ud83c\uddf3\ud83c\uddf4", "\ud83c\uddf4\ud83c\uddf2", "\ud83c\uddf5\ud83c\uddf0", "\ud83c\uddf5\ud83c\uddfc", "\ud83c\uddf5\ud83c\uddf8", "\ud83c\uddf5\ud83c\udde6", "\ud83c\uddf5\ud83c\uddec", "\ud83c\uddf5\ud83c\uddfe", "\ud83c\uddf5\ud83c\uddea", "\ud83c\uddf5\ud83c\udded", "\ud83c\uddf5\ud83c\uddf3", "\ud83c\uddf5\ud83c\uddf1", "\ud83c\uddf5\ud83c\uddf9", "\ud83c\uddf5\ud83c\uddf7", "\ud83c\uddf6\ud83c\udde6", "\ud83c\uddf7\ud83c\uddea", "\ud83c\uddf7\ud83c\uddf4", "\ud83c\uddf7\ud83c\uddfa", "\ud83c\uddf7\ud83c\uddfc", "\ud83c\uddfc\ud83c\uddf8", "\ud83c\uddf8\ud83c\uddf2", "\ud83c\uddf8\ud83c\uddf9", "\ud83c\uddf8\ud83c\udde6", "\ud83c\uddf8\ud83c\uddf3", "\ud83c\uddf7\ud83c\uddf8", "\ud83c\uddf8\ud83c\udde8", "\ud83c\uddf8\ud83c\uddf1", "\ud83c\uddf8\ud83c\uddec", "\ud83c\uddf8\ud83c\uddfd", "\ud83c\uddf8\ud83c\uddf0", "\ud83c\uddf8\ud83c\uddee", "\ud83c\uddf8\ud83c\udde7", "\ud83c\uddf8\ud83c\uddf4", "\ud83c\uddff\ud83c\udde6", "\ud83c\uddec\ud83c\uddf8", "\ud83c\uddf0\ud83c\uddf7", "\ud83c\uddf8\ud83c\uddf8", "\ud83c\uddea\ud83c\uddf8", "\ud83c\uddf1\ud83c\uddf0", "\ud83c\udde7\ud83c\uddf1", "\ud83c\uddf8\ud83c\udded", "\ud83c\uddf0\ud83c\uddf3", "\ud83c\uddf1\ud83c\udde8", "\ud83c\uddf2\ud83c\uddeb", "\ud83c\uddf5\ud83c\uddf2", "\ud83c\uddfb\ud83c\udde8", "\ud83c\uddf8\ud83c\udde9", "\ud83c\uddf8\ud83c\uddf7", "\ud83c\uddf8\ud83c\uddef", "\ud83c\uddf8\ud83c\uddff", "\ud83c\uddf8\ud83c\uddea", "\ud83c\udde8\ud83c\udded", "\ud83c\uddf8\ud83c\uddfe", "\ud83c\uddf9\ud83c\uddfc", "\ud83c\uddf9\ud83c\uddef", "\ud83c\uddf9\ud83c\uddff", "\ud83c\uddf9\ud83c\udded", "\ud83c\uddf9\ud83c\uddf1", "\ud83c\uddf9\ud83c\uddec", "\ud83c\uddf9\ud83c\uddf0", "\ud83c\uddf9\ud83c\uddf4", "\ud83c\uddf9\ud83c\uddf9", "\ud83c\uddf9\ud83c\udde6", "\ud83c\uddf9\ud83c\uddf3", "\ud83c\uddf9\ud83c\uddf7", "\ud83c\uddf9\ud83c\uddf2", "\ud83c\uddf9\ud83c\udde8", "\ud83c\uddf9\ud83c\uddfb", "\ud83c\uddfa\ud83c\uddec", "\ud83c\uddfa\ud83c\udde6", "\ud83c\udde6\ud83c\uddea", "\ud83c\uddec\ud83c\udde7", "\ud83c\uddfa\ud83c\uddf8", "\ud83c\uddfa\ud83c\uddfe", "\ud83c\uddfa\ud83c\uddf2", "\ud83c\uddfb\ud83c\uddee", "\ud83c\uddfa\ud83c\uddff", "\ud83c\uddfb\ud83c\uddfa", "\ud83c\uddfb\ud83c\udde6", "\ud83c\uddfb\ud83c\uddea", "\ud83c\uddfb\ud83c\uddf3", "\ud83c\uddfc\ud83c\uddeb", "\ud83c\uddea\ud83c\udded", "\ud83c\uddfe\ud83c\uddea", "\ud83c\uddff\ud83c\uddf2", "\ud83c\uddff\ud83c\uddfc"], "representation": "\ud83c\udf8c", "title": "flags"}]
openByDefault = 'people'

module.exports = view (models) ->
    div class:'input', ->
        div id:'emoji-container', ->
            div id:'emoji-group-selector', ->
                console.debug("Why is this running multiple times?")
                for range in emojiCategories
                    name = range['title']
                    console.debug("Creating selector for " + name)
                    glow = ''
                    if name == openByDefault
                        glow = 'glow'
                    span id:name+'-button'
                    , title:name
                    , class:'emoticon ' + glow
                    , range['representation']
                    , onclick: do (name) -> ->
                        console.log("Opening " + name)
                        openEmoticonDrawer name

            div class:'emoji-selector', ->
                for range in emojiCategories
                    name = range['title']
                    visible = ''
                    if name == openByDefault
                        visible = 'visible'

                    span id:name, class:'group-content ' + visible, ->
                        for emoji in range['range']
                            if emoji.indexOf("\u200d") >= 0
                                # FIXME For now, ignore characters that have the "glue" character in them;
                                # they don't render properly
                                continue
                            span class:'emoticon', emoji
                            , onclick: do (emoji) -> ->
                                    element = document.getElementById "message-input"
                                    insertTextAtCursor element, emoji

        div class:'input-container', ->
            textarea id:'message-input', autofocus:true, placeholder:'Message', rows: 1, ''
            , onDOMNodeInserted: (e) ->
                # at this point the node is still not inserted
                ta = e.target
                later -> autosize ta
                ta.addEventListener 'autosize:resized', ->
                    # we do this because the autosizing sets the height to nothing
                    # while measuring and that causes the messages scroll above to
                    # move. by pinning the div of the outer holding div, we
                    # are not moving the scroller.
                    ta.parentNode.style.height = (ta.offsetHeight + 24) + 'px'
                    messages.scrollToBottom()
            , onkeydown: (e) ->
                if (e.metaKey or e.ctrlKey) and e.keyIdentifier == 'Up' then action 'selectNextConv', -1
                if (e.metaKey or e.ctrlKey) and e.keyIdentifier == 'Down' then action 'selectNextConv', +1
                unless isModifierKey(e)
                    if e.keyCode == 13
                        e.preventDefault()
                        action 'sendmessage', e.target.value
                        historyPush e.target.value
                        e.target.value = ''
                        autosize.update e.target
                    if e.target.value == ''
                        if e.keyIdentifier is "Up" then historyWalk e.target, -1
                        if e.keyIdentifier is "Down" then historyWalk e.target, +1
                action 'lastkeydown', Date.now() unless isAltCtrlMeta(e)
            , onpaste: (e) ->
                setTimeout () ->
                    if not clipboard.readImage().isEmpty() and not clipboard.readText()
                        action 'onpasteimage'
                , 2

            span class:'button-container', ->
                button title:'Show emoticons', onclick: (ef) ->
                    toggleVisibility document.querySelector '#emoji-container'
                    scrollToBottom()
                , ->
                    span class:'icon-emoji'
            , ->
                button title:'Attach image', onclick: (ev) ->
                    document.getElementById('attachFile').click()
                , ->
                    span class:'icon-attach'
                input type:'file', id:'attachFile', accept:'.jpg,.jpeg,.png,.gif', onchange: (ev) ->
                    action 'uploadimage', ev.target.files

    # focus when switching convs
    if lastConv != models.viewstate.selectedConv
        lastConv = models.viewstate.selectedConv
        laterMaybeFocus()

laterMaybeFocus = -> later maybeFocus

maybeFocus = ->
    # no active element? or not focusing something relevant...
    el = document.activeElement
    if !el or not (el.nodeName in ['INPUT', 'TEXTAREA'])
        # steal it!!!
        el = document.querySelector('.input textarea')
        el.focus() if el

handle 'noinputkeydown', (ev) ->
    el = document.querySelector('.input textarea')
    el.focus() if el and not isAltCtrlMeta(ev)

openEmoticonDrawer = (drawerName) ->
    console.debug "Opening drawer for " + drawerName
    for range in emojiCategories
        set = (range['title'] == drawerName)
        setClass set, (document.querySelector '#'+range['title']), 'visible'
        setClass set, (document.querySelector '#'+range['title']+'-button'), 'glow'


setClass = (boolean, element, className) ->
    if element == undefined or element == null
        console.error "Cannot set visibility for undefined variable"
    else
        if boolean
            console.debug 'Setting ' + className + ' for', element
            element.classList.add(className)
        else
            console.debug 'Removing ' + className + ' for', element
            element.classList.remove(className)


insertTextAtCursor = (el, text) ->
    value = el.value
    doc = el.ownerDocument
    if typeof el.selectionStart == "number" and typeof el.selectionEnd == "number"
        endIndex = el.selectionEnd
        el.value = value.slice(0, endIndex) + text + value.slice(endIndex)
        el.selectionStart = el.selectionEnd = endIndex + text.length
    else if doc.selection != "undefined" and doc.selection.createRange
        el.focus()
        range = doc.selection.createRange()
        range.collapse(false)
        range.text = text
        range.select()
