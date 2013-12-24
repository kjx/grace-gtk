//  "math" module for compatability with math.js
import "gtk" as gtk

def Pi is readable = 3.14159265

method sqr(n : Number) -> Number {n * n}

method sqrt(n : Number) -> Number {gtk.sqrt(n)}

 
