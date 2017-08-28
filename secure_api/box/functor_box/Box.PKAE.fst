(**
  This module represents the PKAE cryptographic security game expressed in terms of the underlying cryptobox construction.
*)
module Box.PKAE


open FStar.Set
open FStar.HyperHeap
open FStar.HyperStack
open FStar.HyperStack.ST
open FStar.Monotonic.RRef
open FStar.Seq
open FStar.Monotonic.Seq
open FStar.List.Tot

open Crypto.Symmetric.Bytes

open Box.Flags

module MR = FStar.Monotonic.RRef
module MM = MonotoneMap
module HS = FStar.HyperStack
module HH = FStar.HyperHeap
module HSalsa = Spec.HSalsa20
module Curve = Spec.Curve25519
module SPEC = Spec.SecretBox
module Plain = Box.Plain
module Key = Box.Key
module ID = Box.Indexing
module ODH = Box.ODH
module AE = Box.AE
module LE = FStar.Endianness

let nonce = AE.nonce
let cipher = AE.cipher
let subId_t = ODH.dh_share
let valid_length = AE.valid_length
let plain_t = AE.ae_plain
let length = AE.length

//let message_log_range (im:index_module) = AE.message_log_range im
//let message_log_inv (im:index_module) (pm:plain_module) (f:MM.map' (message_log_key im) (message_log_range im pm)) = AE.message_log_inv im pm f

let pkey = ODH.pkey
let skey = ODH.skey

let pkey_from_skey sk = ODH.get_pkey sk
let compatible_keys sk pk = ODH.compatible_keys sk pk


private noeq type aux_t' (im:index_module{ID.get_subId im == subId_t}) (pm:plain_module) (rgn:log_region im) =
  | AUX:
    am:AE.ae_module im ->
    km:Key.key_module im{km == AE.instantiate_km am} ->
    om:ODH.odh_module im km ->
    aux_t' im pm rgn

let aux_t im pm = aux_t' im pm

#set-options "--z3rlimit 600 --max_ifuel 1 --max_fuel 1"
val message_log_lemma: im:index_module -> rgn:log_region im -> Lemma
  (requires True)
  (ensures message_log im rgn === AE.message_log im rgn)
let message_log_lemma im rgn =
  assert(FStar.FunctionalExtensionality.feq (message_log_value im) (AE.message_log_value im));
  assert(FStar.FunctionalExtensionality.feq (message_log_range im) (AE.message_log_range im));
  let inv = message_log_inv im in
  let map_t =MM.map' (message_log_key im) (message_log_range im) in
  let inv_t = map_t -> Type0 in
  let ae_inv = AE.message_log_inv im in
  let ae_inv:map_t -> Type0 = ae_inv in
  assert(FStar.FunctionalExtensionality.feq
    #map_t #Type
    inv ae_inv);
  assert(message_log im rgn == AE.message_log im rgn);
  ()


#set-options "--z3rlimit 100 --max_ifuel 1 --max_fuel 0"
let get_message_log_region pkm = AE.get_message_log_region pkm.aux.am

val coerce: t1:Type -> t2:Type{t1 == t2} -> x:t1 -> t2
let coerce t1 t2 x = x

let get_message_logGT pkm =
  let (ae_log:AE.message_log pkm.im (get_message_log_region pkm)) = AE.get_message_logGT #pkm.im pkm.aux.am in
  let (ae_rgn:log_region pkm.im) = AE.get_message_log_region pkm.aux.am in
  message_log_lemma pkm.im ae_rgn;
  let log:message_log pkm.im ae_rgn = coerce (AE.message_log pkm.im ae_rgn) (message_log pkm.im ae_rgn) ae_log in
  log

val create_aux: (im:index_module{ID.get_subId im == subId_t}) -> (pm:plain_module{Plain.get_plain pm == plain_t /\ Plain.valid_length #pm == valid_length}) -> rgn:log_region im -> St (aux_t im pm rgn)
let create_aux im pm rgn =
  assert(FStar.FunctionalExtensionality.feq (valid_length) (AE.valid_length));
  let am = AE.create im pm rgn in
  let km = AE.instantiate_km am in
  let om = ODH.create im km rgn in
  AUX am km om

assume val lemma_compatible_length: n:nat -> Lemma
  (requires valid_length n)
  (ensures n / Spec.Salsa20.blocklen < pow2 32)

val enc (im:ODH.index_module): plain_t -> n:nonce -> pk:pkey -> sk:skey{ODH.compatible_keys sk pk} -> GTot cipher
let enc im p n pk sk = 
  lemma_compatible_length (length p);
  SPEC.secretbox_easy p (ODH.prf_odhGT im sk pk) n

assume val dec: c:cipher -> n:nonce -> pk:pkey -> sk:skey -> Tot (option plain_t) 

let create rgn =
  let id_log_rgn : ID.id_log_region = new_region rgn in
  let im = ID.create id_log_rgn subId_t ODH.smaller ODH.total_order_lemma in
  let pm = Plain.create plain_t AE.valid_length AE.length in
  let log_rgn : log_region im = new_region rgn in
  assert(FStar.FunctionalExtensionality.feq (valid_length) (AE.valid_length));
  let aux = create_aux im pm log_rgn in
  PKAE im pm log_rgn (enc im) (dec) aux

type key (pkm:pkae_module) = AE.key pkm.im

let zero_bytes = AE.create_zero_bytes

let pkey_to_subId #pkm pk = ODH.pk_get_share pk
let pkey_to_subId_inj #pkm pk = ODH.lemma_pk_get_share_inj pk

let nonce_is_fresh (pkm:pkae_module) (i:id pkm.im) (n:nonce) (h:mem) =
  AE.nonce_is_fresh pkm.aux.am i n h

let invariant pkm =
  Key.invariant pkm.im pkm.aux.km

let gen pkm =
  ODH.keygen()

#set-options "--z3rlimit 600 --max_ifuel 1 --max_fuel 1"
let encrypt pkm #i n sk pk m =
  let k = ODH.prf_odh pkm.im pkm.aux.km pkm.aux.om sk pk in
  let c = AE.encrypt pkm.aux.am #i n k m in
  let h = get() in assert(Key.invariant pkm.im pkm.aux.km h);
  ID.lemma_honest_or_dishonest pkm.im (ID.ID i);
  let honest_i = ID.get_honesty pkm.im (ID.ID i) in
  if not honest_i then ( 
    assert(ID.dishonest pkm.im (ID.ID i));
    assert(Key.leak pkm.im pkm.aux.km k = ODH.prf_odhGT pkm.im sk pk );
    //assert(c = SPEC.secretbox_easy (Plain.repr #pkm.im #pkm.pm #i m) (Key.get_rawGT pkm.im pkm.aux.km k) n);
    //assert( eq2 #cipher c (pkm.enc (Plain.repr #pkm.im #pkm.pm #i m) n pk sk));
    ()
  );
  let h = get() in
  assert(FStar.FunctionalExtensionality.feq (message_log_range pkm.im) (AE.message_log_range pkm.im));
  MM.contains_eq_compat (get_message_logGT pkm) (AE.get_message_logGT pkm.aux.am) (n,i) (c,m) h;
  MM.contains_stable (get_message_logGT pkm) (n,i) (c,m);
  MR.witness (get_message_logGT pkm) (MM.contains (get_message_logGT pkm) (n,i) (c,m));
  c

let decrypt pkm #i n sk pk c =
  let k = ODH.prf_odh pkm.im pkm.aux.km pkm.aux.om sk pk in
  let m = AE.decrypt pkm.aux.am #i n k c in
  m