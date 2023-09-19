import "pkg:/source/utils/misc.brs"
import "ViewCreator.brs"
import "pkg:/source/api/Items.brs"
import "pkg:/source/api/baserequest.brs"
import "pkg:/source/utils/config.brs"
import "pkg:/source/api/Image.brs"
import "pkg:/source/utils/deviceCapabilities.brs"

sub init()
    m.hold = []
    m.queue = []
    m.originalQueue = []
    m.queueTypes = []
    m.isPlaying = false
    ' Preroll videos only play if user has cinema mode setting enabled
    m.isPrerollActive = m.global.session.user.settings["playback.cinemamode"]
    m.position = 0
    m.shuffleEnabled = false
end sub

' Clear all content from play queue
sub clear()
    m.isPlaying = false
    m.queue = []
    m.queueTypes = []
    m.isPrerollActive = m.global.session.user.settings["playback.cinemamode"]
    setPosition(0)
end sub

' Clear all hold content
sub clearHold()
    m.hold = []
end sub

' Delete item from play queue at passed index
sub deleteAtIndex(index)
    m.queue.Delete(index)
    m.queueTypes.Delete(index)
end sub

' Return the number of items in the play queue
function getCount()
    return m.queue.count()
end function

' Return the item currently in focus from the play queue
function getCurrentItem()
    return getItemByIndex(m.position)
end function

' Return the items in the hold
function getHold()
    return m.hold
end function

' Return whether or not shuffle is enabled
function getIsShuffled()
    return m.shuffleEnabled
end function

' Return the item in the passed index from the play queue
function getItemByIndex(index)
    return m.queue[index]
end function

' Returns current playback position within the queue
function getPosition()
    return m.position
end function

' Hold an item
sub hold(newItem)
    m.hold.push(newItem)
end sub

' Move queue position back one
sub moveBack()
    m.position--
end sub

' Move queue position ahead one
sub moveForward()
    m.position++
end sub

' Return the current play queue
function getQueue()
    return m.queue
end function

' Return the types of items in current play queue
function getQueueTypes()
    return m.queueTypes
end function

' Return the unique types of items in current play queue
function getQueueUniqueTypes()
    itemTypes = []

    for each item in getQueueTypes()
        if not inArray(itemTypes, item)
            itemTypes.push(item)
        end if
    end for

    return itemTypes
end function

' Return item at end of play queue without removing
function peek()
    return m.queue.peek()
end function

' Play items in queue
sub playQueue()
    m.isPlaying = true
    nextItem = getCurrentItem()
    if not isValid(nextItem) then return

    nextItemMediaType = getItemType(nextItem)
    if nextItemMediaType = "" then return

    if nextItemMediaType = "audio"
        CreateAudioPlayerView()
        return
    end if

    if nextItemMediaType = "video"
        CreateVideoPlayerView()
        return
    end if

    if nextItemMediaType = "movie"
        CreateVideoPlayerView()
        return
    end if

    if nextItemMediaType = "episode"
        CreateVideoPlayerView()
        return
    end if

    if nextItemMediaType = "trailer"
        CreateVideoPlayerView()
        return
    end if
end sub

' Remove item at end of play queue
sub pop()
    m.queue.pop()
    m.queueTypes.pop()
end sub

' Return isPrerollActive status
function isPrerollActive() as boolean
    return m.isPrerollActive
end function

' Set prerollActive status
sub setPrerollStatus(newStatus as boolean)
    m.isPrerollActive = newStatus
end sub

' Push new items to the play queue
sub push(newItem)
    m.queue.push(newItem)
    m.queueTypes.push(getItemType(newItem))
end sub

' Set the queue position
sub setPosition(newPosition)
    m.position = newPosition
end sub

' Reset shuffle to off state
sub resetShuffle()
    m.shuffleEnabled = false
end sub

' Toggle shuffleEnabled state
sub toggleShuffle()
    m.shuffleEnabled = not m.shuffleEnabled

    if m.shuffleEnabled
        shuffleQueueItems()
        return
    end if

    resetQueueItemOrder()
end sub

' Reset queue items back to original, unshuffled order
sub resetQueueItemOrder()
    set(m.originalQueue)
end sub

' Return original, unshuffled queue
function getUnshuffledQueue()
    return m.originalQueue
end function

' Save a copy of the original queue and randomize order of queue items
sub shuffleQueueItems()
    ' By calling getQueue 2 different ways, Roku avoids needing to do a deep copy
    m.originalQueue = m.global.queueManager.callFunc("getQueue")
    itemIDArray = getQueue()
    temp = invalid

    if m.isPlaying
        ' Save the currently playing item
        temp = getCurrentItem()
        ' remove currently playing item from itemIDArray
        itemIDArray.Delete(m.position)
    end if

    ' shuffle all items
    itemIDArray = shuffleArray(itemIDArray)

    if m.isPlaying
        ' Put currently playing item in front of itemIDArray
        itemIDArray.Unshift(temp)
    end if

    set(itemIDArray)
end sub

' Return the fitst item in the play queue
function top()
    return getItemByIndex(0)
end function

' Replace play queue with passed array
sub set(items)
    clear()
    m.queue = items
    for each item in items
        m.queueTypes.push(getItemType(item))
    end for
end sub

' Set starting point for top item in the queue
sub setTopStartingPoint(positionTicks)
    m.queue[0].startingPoint = positionTicks
end sub

function getItemType(item) as string
    if isValid(item) and isValid(item.json) and isValid(item.json.mediatype) and item.json.mediatype <> ""
        return LCase(item.json.mediatype)
    else if isValid(item) and isValid(item.type) and item.type <> ""
        return LCase(item.type)
    end if

    return ""
end function
