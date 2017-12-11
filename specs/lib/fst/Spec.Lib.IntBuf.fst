module Spec.Lib.IntBuf

open FStar.HyperStack
open FStar.HyperStack.ST
open Spec.Lib.IntTypes
open Spec.Lib.IntSeq

module LSeq = Spec.Lib.IntSeq

module Buf = FStar.Buffer
module U32 = FStar.UInt32 
type lbuffer (a:Type0) (len:size_t) = b:Buf.buffer a {Buf.length b == len}
let sub #a #len b start n = Buf.sub b (U32.uint_to_t start) (U32.uint_to_t n)

let disjoint #a1 #a2 #len1 #len2 b1 b2 : GTot Type0 = Buf.disjoint #a1 #a2 b1 b2
let live #a #len h b : GTot Type0 = Buf.live h b

let preserves_live h0 h1 = True
let as_lseq #a #len b m = admit()
let modifies1 #a #len b h0 h1 = admit()
let modifies2 = admit()
let modifies3 = admit()
let modifies = admit()
let live_list = admit()
let disjoint_list = admit()

let create #a len init = Buf.create init (U32.uint_to_t len)
let createL #a init = Buf.createL init

let alloc #a #b len init read writes spec impl = 
  push_frame();
  let buf = create len init in
  let r = impl buf in
  pop_frame();
  r

let index #a #len b i = Buf.index b (U32.uint_to_t i)
let upd #a #len b i v = Buf.upd b (U32.uint_to_t i) v

//let op_Array_Assignment = upd
//let op_Array_Access = index

let map #a #len f b = admit()
let map2 #a1 #a2 #len f b1 b2 = admit()
let blit #a #len i start1 o start2 num = admit()
let copy #a #len i o = admit()
let repeat #a #b #lift n spec impl input = admit()
let repeat_range #a #b #lift start fin spec impl input = admit()
let repeati #a #b #lift fin spec impl input = admit()
let iter #a #len n spec impl input = admit()
let iteri #a #len n spec impl input = admit()
let iter_range #a #len start fin spec impl input = admit()
let uints_from_bytes_le #t #len o i = admit()
let uint32s_from_bytes_le #len o i = admit()
let uint32s_to_bytes_le #len o i = admit()

//let index #a #len b i = Buf.index b (U32.uint_to_t i)


(*

     x1 == update_sub (update_sub x0 x.start x.length (as_lseq h1 x)) y.start y.length (as_lseq h1 y)))


val create: #a:Type -> len:size_t -> init:a -> StackInline (lbuf a len)
		    (requires (fun _ -> True))
		    (ensures (fun h0 r h1 -> live h1 r /\ creates_1 #a r h0 h1))
let create #a len init =
  let s = salloc #(lseq a len) (create #a len init) in
  MkBuffer s 0 len

val createL: #a:Type -> l:list a {List.Tot.length l <= max_size_t} -> StackInline (lbuf a (List.Tot.length l))
		    (requires (fun _ -> True))
		    (ensures (fun h0 r h1 -> live h1 r /\ creates_1 r h0 h1))
let createL #a l = 
  let len : size_t = List.Tot.length l in
  let s = salloc #(lseq a len) (createL #a l) in
  MkBuffer s 0 len


val deref: #a:Type -> #len:size_t -> b:lbuf a len -> Stack (lseq a len) 
		     (requires (fun h -> live h b))
		     (ensures (fun h0 r h1 -> h0 == h1 /\ r == as_lseq h0 b))
let deref #a #len b = sub (!b.content) b.start b.length


val index: #a:Type -> #len:size_t{len > 0} -> b: lbuf a len -> n:size_t{n < len} -> Stack a
		     (requires (fun h -> live h b))
		     (ensures (fun h0 r h1 -> h0 == h1 /\ r == index #a #len (as_lseq #a h0 b) n))
let index #a #len b n = 
  let s = deref b in
  s.[n]
		     
val upd: #a:Type -> #len:size_t -> b:lbuf a len -> n:size_t{n < len /\ len > 0} -> x:a -> Stack unit 
		     (requires (fun h -> live h b))
		     (ensures (fun h0 _ h1 -> modifies_1 b h0 h1 /\
					   as_lseq h1 b == upd #a #len (as_lseq h0 b) n x))

let upd #a #len b n x = 
  let full = !b.content in
  let s = deref b in
  b.content := update_sub full b.start b.length (s.[n] <- x)
					   
			      
val sub: #a:Type -> #len:size_t -> b:lbuf a len -> start:size_t -> n:size_t{start + n <= len} -> b':lbuf a n{b'.max_length == b.max_length /\ b'.content == b.content /\ b'.start == b.start + start /\ b'.length == n}
let sub #a #len b s n = 
  MkBuffer b.content (b.start+s) n

val slice: #a:Type -> #len:size_t -> b:lbuf a len -> start:size_t{start < len} -> fin:size_t{start <= fin /\ fin <= len} -> b':lbuf a (fin - start){b'.max_length == b.max_length /\ b'.content == b.content /\ b'.start == b.start + start /\ b'.length == (fin - start)}
let slice #a #len b s f = 
  MkBuffer b.content (b.start + s) (f - s)


*)
