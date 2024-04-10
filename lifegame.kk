import std/num/random
import std/core/list
import std/num/int64

effect fun debug(msg : string) : unit

effect fun view(x : int, y : int) : bool
effect fun set(x : int, y : int, v : bool) : unit
effect val x-width : int
effect val y-width : int

alias game = <view, set, x-width, y-width>

fun print-board() : <game, console> unit
  list(0, x-width).foreach fn(x)
    list(0, y-width).foreach fn(y)
      print(if view(x, y) then "■" else "□")
    println("")

fun make-field() : <debug, game, random> unit
  with x <- list(0, x-width).foreach 
  with y <- list(0, y-width).foreach
  set(x, y, random-bool())

fun get-bit(bitmap : int64, x : int, y : int) : <debug, x-width> bool
  val bit = 1.int64.shl(x + y * x-width)
  debug(bit.show)
  bitmap.and(bit) != int64(0)

fun set-bit(bitmap : int64, x : int, y : int, v : bool) : <debug, x-width> int64
  if v then
    val bit = 1.int64.shl(x + y * x-width)
    debug(bit.show)
    bitmap.or(1.int64.shl(x + y * x-width))
  else
    val bit = 1.int64.shl(x + y * x-width).not
    debug(bit.show)
    bitmap.and(bit)

fun get-vector(vec : vector<bool>, x : int, y : int) : <debug, x-width> bool
  vec.at(x + y * x-width).default(False)

fun set-vector(vec : vector<bool>, x : int, y : int, v : bool) : <debug, x-width, y-width> vector<bool>
  vector-init(x-width * y-width) fn(i)
    if i == x + y * x-width then
      v
    else
      vec.at(i).default(False)

fun main()
  with fun debug(msg) ()
  with val x-width = 8
  with val y-width = 8
  var table := vector(x-width * y-width, False)
  // var table := 0.int64
  with fun view(x, y)
      get-vector(table, x, y)
  with fun set(x, y, v)
      table := set-vector(table, x, y, v)
  make-field()
  print-board()