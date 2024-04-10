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
effect ctl set(x : int, y : int, v : bool) : unit
effect<a> val nextField : a
// go to the next generation. This should be called after all cells are set.
effect ctl next() : unit
effect val x-width : int
effect val y-width : int

alias game<a> = <view, set, next, nextField<a>, x-width, y-width>

// print the current cells.
fun print-field() : <game<a>, console> unit
  println("=====================================")
  list(0, x-width).foreach fn(x)
    list(0, y-width).foreach fn(y)
      print(if view(x, y) then "#" else " ")
    println("")

fun make-field() : <debug, game<a>, random> unit
  with x <- list(0, x-width).foreach 
  debug("x: " ++ x.show)
  with y <- list(0, y-width).foreach
  debug("y: " ++ x.show)
  set(x, y, random-bool())

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

fun viewTuple(t : (int, int)) : game<a> bool
  match t
    (x, y) -> view(x, y)

fun is-live(x : int, y : int) : <debug, game<a>> bool
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

fun runWithVector(body : () -> <game<vector<bool>>, debug|e> ()) : <debug|e> ()
  with val x-width = 30
  with val y-width = 30
  val field = vector(x-width * y-width, False)
  with fun view(x, y)
    if x < 0 || x >= x-width || y < 0 || y >= y-width then
      False
    else
      get-vector(field, x, y)
  with val nextField = field
  with ctl set(x, y, v)
    debug("set: " ++ x.show ++ ", " ++ y.show ++ ", " ++ v.show)
    if not(x < 0 || x >= x-width || y < 0 || y >= y-width) then
      val new = set-vector(nextField, x, y, v)
      mask<nextField>
        with val nextField = new
        resume(())
    else
      resume(())
  with ctl next()
    mask<view>
      val new = nextField
      with fun view(x, y)
        if x < 0 || x >= x-width || y < 0 || y >= y-width then
          False
        else
          get-vector(new, x, y)
      resume(())
  body()

fun main()
  with fun debug(msg) println("DEBUG: " ++ msg)
  runWithVector
    make-field()
    debug("field initialized")
    next()
    print-field()
    while { True }
      sleep(seconds(1))
      list(0, x-width).foreach fn(x)
        list(0, y-width).foreach fn(y)
          set(x, y, is-live(x, y))
      next()
      print-field()