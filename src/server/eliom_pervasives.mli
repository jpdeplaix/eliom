
exception Eliom_Internal_Error of string

external id : 'a -> 'a = "%identity"

val (>>=) : 'a Lwt.t -> ('a -> 'b Lwt.t) -> 'b Lwt.t
val (>|=) : 'a Lwt.t -> ('a -> 'b) -> 'b Lwt.t
val (!!) : 'a Lazy.t -> 'a

type yesnomaybe = Yes | No | Maybe
type ('a, 'b) leftright = Left of 'a | Right of 'b

val map_option : ('a -> 'b) -> 'a option -> 'b option

val fst3 : 'a * 'b * 'c -> 'a
val snd3 : 'a * 'b * 'c -> 'b
val thd3 : 'a * 'b * 'c -> 'c

module List : sig
  include module type of List
  val assoc_remove : 'a -> ('a * 'b) list -> 'b * ('a * 'b) list
  val remove_all_assoc : 'a -> ('a * 'b) list -> ('a * 'b) list
  val remove_first_if_any : 'a -> 'a list -> 'a list
  val remove_first_if_any_q : 'a -> 'a list -> 'a list
end

module String : sig

  include module type of String

  val basic_sep : char -> string -> string * string
  val sep : char -> string -> string * string
  val split : ?multisep:bool -> char -> string -> string list

  val first_diff : string -> string -> int -> int -> int
  val may_append : string -> sep:string -> string -> string (* WAS add_to_string *)
  val may_concat : string -> sep:string -> string -> string (* WAS concat_strings *)

  val make_cryptographic_safe : unit -> string

  module Table : Map.S with type key = string
                        and type 'a t = 'a Ocsigen_pervasives.String.Table.t

end

module Url : sig
  type t = Ocsigen_pervasives.Url.t
  type uri = Ocsigen_pervasives.Url.uri
  type path = Ocsigen_pervasives.Url.path

  val make_absolute_url :
      https:bool -> host:string -> port:int -> uri -> t

  val remove_slash_at_beginning : path -> path
  val remove_internal_slash : path -> path
  val is_prefix_skip_end_slash : string list -> string list -> bool
  val change_empty_list : path -> path

  val string_of_url_path : encode:bool -> path -> uri

  val make_encoded_parameters : (string * string) list -> uri

  val encode : ?plus:bool -> string -> string
  val decode : ?plus:bool -> string -> string

end

module Ip_address : sig

  type t = Ocsigen_pervasives.Ip_address.t =
    | IPv4 of int32
    | IPv6 of int64 * int64

  val parse : string -> t * (t option)

  val network_of_ip : t -> int32 -> int64 * int64 -> t
  val inet6_addr_loopback : t

end

module Filename : sig
  include module type of Filename
end

module Printexc :  sig
  include module type of Printexc
end

module Int : sig
  module Table : Map.S with type key = int
end

val to_json : ?typ:'a Deriving_Json.t -> 'a -> string
val of_json : ?typ:'a Deriving_Json.t -> string -> 'a

module XML : sig

  type aname = string
  type separator = Space | Comma
  type event = string

  type attrib
  type acontent = private
    | AFloat of aname * float
    | AInt of aname * int
    | AStr of aname * string
    | AStrL of separator * aname * string list
  val acontent : attrib -> acontent
  val aname : attrib -> aname

  val float_attrib : aname -> float -> attrib
  val int_attrib : aname -> int -> attrib
  val string_attrib : aname -> string -> attrib
  val space_sep_attrib : aname -> string list -> attrib
  val comma_sep_attrib : aname -> string list -> attrib
  val event_attrib : aname -> event -> attrib

  val attrib_name : attrib -> aname
  val attrib_value_to_string : (string -> string) -> attrib -> string
  val attrib_to_string : (string -> string) -> attrib -> string

  type ename = string

  type econtent =
    | Empty
    | Comment of string
    | EncodedPCDATA of string
    | PCDATA of string
    | Entity of string
    | Leaf of ename * attrib list
    | Node of ename * attrib list * elt list
  and elt = {
      (* the element is boxed with some meta-information *)
      mutable ref : int ;
      elt : econtent ;
      elt_mark : Obj.t;
    }
  val content : elt -> econtent

  val make_mark : (unit -> Obj.t) ref

  val make_node : econtent -> elt

  val empty : unit -> elt

  val comment : string -> elt
  val pcdata : string -> elt
  val encodedpcdata : string -> elt
  val entity : string -> elt
(** Neither [comment], [pcdata] nor [entity] check their argument for invalid
    characters.  Unsafe characters will be escaped later by the output routines.  *)

  val leaf : ?a:(attrib list) -> ename -> elt
  val node : ?a:(attrib list) -> ename -> elt list -> elt
(** NB: [Leaf ("foo", []) -> "<foo />"], but [Node ("foo", [], []) -> "<foo></foo>"] *)

  val cdata : string -> elt
  val cdata_script : string -> elt
  val cdata_style : string -> elt

  type ref_tree = Ref_tree of int option * (int * ref_tree) list

  val ref_node : elt -> int
  val next_ref : unit -> int (** use with care! *)
  val make_ref_tree : elt -> ref_tree
  val make_ref_tree_list : elt list -> (int * ref_tree) list

  val lwt_register_event : ?keep_default:bool -> elt -> ename -> ('a -> 'b Lwt.t) -> 'a -> unit
  val register_event : ?keep_default:bool -> elt -> ename -> ('a -> 'b) -> 'a -> unit

  val class_name : string

end

module SVG : sig

  module M : SVG_sigs.SVG(XML).T
  module P : XML_sigs.TypedSimplePrinter(XML)(M).T

end

module HTML5 : sig

  module M : HTML5_sigs.HTML5(XML)(SVG.M).T
  module P : XML_sigs.TypedSimplePrinter(XML)(M).T

end

module XHTML : sig

  module M : XHTML_sigs.XHTML(XML).T
  module M_01_01 : XHTML_sigs.XHTML(XML).T
  module M_01_00 : XHTML_sigs.XHTML(XML).T
  module P : XML_sigs.TypedSimplePrinter(XML)(M).T

end