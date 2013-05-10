import "random" as rnd
import "mgcollections" as col
import "gtk" as gtk

var dirty is public,readable,writable := {}
var transcript is public,readable,writable :=  
      object { 
         method transcript(t) { } 
      }

// sorting utilities

def collection is public, readable = col.list.new

method size {collection.size}

method fill (sz) {
  while {collection.size > 0} do {collection.pop}
  for (1..sz) do {n->collection.push(n)}
}

method shuffle {
  for (collection.indices) do {n->
         swap(n) and(rnd.random * size)
         while {gtk.events_pending} do {gtk.main_iteration}
  }
}

method reverse {
 for (1..(size/2)) do {n->swap(n) and(size - n + 1)}
}

method swap(a) and(b) {
  def t=collection[a]
  collection[a]:=collection[b]
  collection[b]:=t
  transcript.transcript "swqp {a} and {b}"
  dirty.apply
}

method compare(a) and(b) {
   transcript.transcript "compare {a} and {b}"   
   return collection[a] > collection[b]}

method compare(a) with(b) {
   transcript.transcript "compare {a} with {b}"
   return collection[a] > b}



//      quick* = (|
//                 quickSort =  (quickSortFrom: 0 To: size predecessor).
//                 quickSortFrom: l To: r = ( | i. j. x. |
//                         i: l.
//                         j: r.
//                         x: at: (l + r) / 2.
//                         [
//                             [(at: i) < x] whileTrue: [i: i successor].
//                             [x < (at: j)] whileTrue: [j: j predecessor].
//                             i <= j ifTrue: [ | w |
//                                 i = j ifFalse: [swap: i And: j].

//                                 i: i successor.
//                                 j: j predecessor.
//                             ].
//                         ] untilFalse: [ i <= j ].
                
//                         l < j ifTrue: [quickSortFrom: l To: j].
//                         i < r ifTrue: [quickSortFrom: i To: r]. 
//                         self).
//         |).


method bubble {
   var top:= size-1      
   while {top >= 1} do
    {
     for (1..top) do {i->
      if (compare(i) and(i+1)) then {swap(i) and(i+1)}
      while {gtk.events_pending} do {gtk.main_iteration}
      }
    top:=top-1
    }
}
