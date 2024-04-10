import std/num/random
import std/core/list
import std/num/int64
import std/time/chrono
import std/time/instant
import std/time/duration
import std/time/utc

effect fun debug(msg : string) : unit

// view the current cell state at (x, y).
effect fun view(x : int, y : int) : bool
// set the next cell state at (x, y) to v. It does not affect the current cell state.
effect fun set(x : int, y : int, v : bool) : unit
// go to the next generation. This should be called after all cells are set.
effect fun next() : unit
effect val x-width : int
effect val y-width : int

alias game = <view, set, next, x-width, y-width>

// print the current cells.
fun print-field() : <game, console> unit
  println("=====================================")
  list(0, x-width).foreach fn(x)
    list(0, y-width).foreach fn(y)
      print(if view(x, y) then "#" else " ")
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

fun neighbors(x : int, y : int) : list<(int, int)>
  with dx <- list(-1, 1).flatmap
  with dy <- list(-1, 1).flatmap
  if dx == 0 && dy == 0 then
    []
  else
    [(x + dx, y + dy)]

fun viewTuple(t : (int, int)) : game bool
  match t
    (x, y) -> view(x, y)

fun is-live(x : int, y : int) : <debug, game> bool
  val ns = neighbors(x, y)
  debug(ns.show)
  val count = ns.filter(viewTuple).length
  if view(x, y) then
    count == 2 || count == 3
  else
    count == 3

fun sleep(dt : duration) : <debug, utc, div, ndet> unit
  val start = duration(now())
  while { duration(now()) - start < dt }
    ()

fun runWithVector(body : () -> <game, debug|e> ()) : <debug|e> ()
  with val x-width = 30
  with val y-width = 30
  var field := vector(x-width * y-width, False)
  var nextField := vector(x-width * y-width, False)
  with fun view(x, y)
    if x < 0 || x >= x-width || y < 0 || y >= y-width then
      False
    else
      get-vector(field, x, y)
  with fun set(x, y, v)
    if not(x < 0 || x >= x-width || y < 0 || y >= y-width) then
      nextField := set-vector(nextField, x, y, v)
  with fun next()
    field := nextField
    nextField := vector(x-width * y-width, False)
  body()

fun runWithBit(body : () -> <game, debug, console|e> ()) : <console, debug|e> ()
  with val x-width = 8
  with val y-width = 8
  var field := int64(0)
  var nextField := int64(0)
  with fun view(x, y)
    if x < 0 || x >= x-width || y < 0 || y >= y-width then
      False
    else
      get-bit(field, x, y)
  with fun set(x, y, v)
    if not(x < 0 || x >= x-width || y < 0 || y >= y-width) then
      nextField := set-bit(nextField, x, y, v)
  with fun next()
    field := nextField
    nextField := int64(0)
    println("Value: " ++ field.show)
  body()


fun main()
  with fun debug(msg) ()
  runWithBit {
    make-field()
    next()
    print-field()
    while { True }
      sleep(seconds(1))
      list(0, x-width).foreach fn(x)
        list(0, y-width).foreach fn(y)
          set(x, y, is-live(x, y))
      next()
      print-field()
  }