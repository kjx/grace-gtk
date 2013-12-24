//Grace version of timer module for Minigrace/C
//Designed to emulate timer.js by using timer functions 
//from gtk, liked into gtk by James's hacks to gwrap.py
import "gtk" as gtk
import "mgcollections" as collections

type TimerId = Number 

def allTimersAndIntervals = collections.list.new

//no idea what this is supposed to do
method trapErrors (block : Block) {
  block.apply
}

//repeat the block after every milliseconds
method every (milliseconds : Number) do (block : Block) -> TimerId {
  return gtkTimeoutAdd(milliseconds, block, true)
}

//execute the block once after  milliseconds
method after (milliseconds : Number) do (block : Block) -> TimerId {
  return gtkTimeoutAdd(milliseconds, block, false)
}

//internal method
method gtkTimeoutAdd(milliseconds : Number,  
                            block : Block, 
                           repeat : Boolean ) -> TimerId is confidential {
  def timerId = gtk.timeout_add(milliseconds, { block.apply; repeat } )
  allTimersAndIntervals.push(timerId)
  return timerId
}

//stop interval or timer id
method stop(id : TimerId) {
  gtk.source_remove(id)
  // allTimersAndIntervals.remove(id) // not supported 
}

//stop all timers.
method stopAll {
  for (allTimersAndIntervals) do {id -> stop(id)} 
}

 
