(* Ocsigen
 * http://www.ocsigen.org
 * Module eliommod.ml
 * Copyright (C) 2007 Vincent Balat
 * Laboratoire PPS - CNRS Université Paris Diderot
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception; 
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)
(*****************************************************************************)
(*****************************************************************************)
(** Internal functions used by Eliom:                                        *)
(** Tables of services (global and session tables,                           *)
(** persistant and volatile data tables)                                     *)
(** Store and load services                                                  *)
(*****************************************************************************)
(*****************************************************************************)

open Lwt
open Http_frame
open Ocsigen_lib
open Extensions
open Lazy


(****************************************************************************)
let default_max_sessions_per_group = Some 20
      
let new_sitedata =
  (* We want to keep the old site data even if we reload the server *)
  (* To do that, we keep the site data in a table *)
  let module S = Hashtbl.Make(struct 
                                type t = url_path
                                let equal = (=)
                                let hash = Hashtbl.hash
                              end)
  in
  let t = S.create 5 in
  fun site_dir ->
    try
      S.find t site_dir
    with 
      | Not_found ->
          let sitedata =
            {Eliom_common.servtimeout = [];
             datatimeout = [];
             perstimeout = [];
             site_dir = site_dir;
             site_dir_string = Ocsigen_lib.string_of_url_path site_dir;
             global_services = Eliom_common.empty_tables ();
             session_services = Eliommod_cookies.new_service_cookie_table ();
             session_data = Eliommod_cookies.new_data_cookie_table ();
             remove_session_data = (fun cookie -> ());
             not_bound_in_data_tables = (fun cookie -> true);
             exn_handler = Eliommod_pagegen.def_handler;
             unregistered_services = [];
             unregistered_na_services = [];
             max_service_sessions_per_group = 
                default_max_sessions_per_group;
             max_volatile_data_sessions_per_group = 
                default_max_sessions_per_group;
             max_persistent_data_sessions_per_group = 
                default_max_sessions_per_group;
            }
          in
          Eliommod_gc.service_session_gc sitedata;
          Eliommod_gc.data_session_gc sitedata;
          S.add t site_dir sitedata;
          sitedata


let close_volatile_session ?close_group ?session_name ~sp () =
  Eliommod_datasess.close_data_session ?close_group ?session_name ~sp ();
  Eliommod_sersess.close_service_session ?close_group ?session_name ~sp ()










      

(*****************************************************************************)
(* Session service table *)
(** We associate to each service a function server_params -> page *)





(****************************************************************************)
(****************************************************************************)
(****************************************************************************)





(*****************************************************************************)
(** Parsing global configuration for Eliommod: *)
open Simplexmlparser

let rec parse_global_config = function
  | [] -> ()
  | (Element ("timeout", [("value", s)], []))::ll
  | (Element ("volatiletimeout", [("value", s)], []))::ll -> 
      (try
        Eliommod_timeouts.set_default_volatile_timeout
          (Some (float_of_string s))
      with Failure _ -> 
        if (s = "infinity")
        then Eliommod_timeouts.set_default_volatile_timeout None
        else
          raise (Error_in_config_file "Eliom: Wrong value for value attribute of <timeout> or <volatiletimeout> tag"));
      parse_global_config ll
  | (Element ("datatimeout", [("value", s)], []))::ll -> 
      (try
        Eliommod_timeouts.set_default_data_timeout (Some (float_of_string s))
      with Failure _ -> 
        if (s = "infinity")
        then Eliommod_timeouts.set_default_data_timeout None
        else
          raise (Error_in_config_file "Eliom: Wrong value for value attribute of <datatimeout> tag"));
      parse_global_config ll
  | (Element ("servicetimeout", [("value", s)], []))::ll -> 
      (try
        Eliommod_timeouts.set_default_service_timeout (Some (float_of_string s))
      with Failure _ -> 
        if (s = "infinity")
        then Eliommod_timeouts.set_default_service_timeout None
        else
          raise (Error_in_config_file "Eliom: Wrong value for value attribute of <servicetimeout> tag"));
      parse_global_config ll
  | (Element ("persistenttimeout", [("value", s)], []))::ll -> 
      (try
        Eliommod_timeouts.set_default_persistent_timeout (Some (float_of_string s))
      with Failure _ -> 
        if (s = "infinity")
        then Eliommod_timeouts.set_default_persistent_timeout None
        else
          raise (Error_in_config_file "Eliom: Wrong value for value attribute of <persistenttimeout> tag"));
      parse_global_config ll
  | (Element ("sessiongcfrequency", [("value", s)], p))::ll ->
      (try
        let t = float_of_string s in
        Eliommod_gc.set_servicesessiongcfrequency (Some t);
        Eliommod_gc.set_datasessiongcfrequency (Some t)
      with Failure _ -> 
        if s = "infinity"
        then begin
          Eliommod_gc.set_servicesessiongcfrequency None;
          Eliommod_gc.set_datasessiongcfrequency None
        end
        else raise (Error_in_config_file
                      "Eliom: Wrong value for <sessiongcfrequency>"));
      parse_global_config ll
  | (Element ("servicesessiongcfrequency", [("value", s)], p))::ll ->
      (try
        Eliommod_gc.set_servicesessiongcfrequency (Some (float_of_string s))
      with Failure _ -> 
        if s = "infinity"
        then Eliommod_gc.set_servicesessiongcfrequency None
        else raise (Error_in_config_file
                      "Eliom: Wrong value for <servicesessiongcfrequency>"));
      parse_global_config ll
  | (Element ("datasessiongcfrequency", [("value", s)], p))::ll ->
      (try
        Eliommod_gc.set_datasessiongcfrequency (Some (float_of_string s))
      with Failure _ -> 
        if s = "infinity"
        then Eliommod_gc.set_datasessiongcfrequency None
        else raise (Error_in_config_file
                      "Eliom: Wrong value for <datasessiongcfrequency>"));
      parse_global_config ll
  | (Element ("persistentsessiongcfrequency", 
              [("value", s)], p))::ll ->
                (try
                  Eliommod_gc.set_persistentsessiongcfrequency
                    (Some (float_of_string s))
                with Failure _ -> 
                  if s = "infinity"
                  then Eliommod_gc.set_persistentsessiongcfrequency None
                  else raise (Error_in_config_file
                                "Eliom: Wrong value for <persistentsessiongcfrequency>"));
                parse_global_config ll
  | (Element (tag,_,_))::ll -> 
      parse_global_config ll
  | _ -> raise (Error_in_config_file ("Unexpected content inside eliom config"))
        
        
let _ = parse_global_config (Extensions.get_config ())










(*****************************************************************************)
(** Module loading *)
let config = ref []

let load_eliom_module sitedata cmo content =
  let preload () =
    config := content;
    Eliom_common.begin_load_eliom_module ()
  in
  let postload () =
    Eliom_common.end_load_eliom_module ();
    config := []
  in
  try
    Ocsigen_loader.loadfiles preload postload true cmo
  with Ocsigen_loader.Dynlink_error _ as e ->
    raise (Eliom_common.Eliom_error_while_loading_site
             (Printf.sprintf "(eliom extension) %s"
                (Ocsigen_loader.error_message e)))



(*****************************************************************************)
(** Parsing of config file for each site: *)
let parse_config site_dir charset = 
(*--- if we put the following line here: *)
  let sitedata = new_sitedata site_dir in
(*--- then there is one service tree for each <site> *)
(*--- (mutatis mutandis for the following line:) *)
  Eliom_common.absolute_change_sitedata sitedata;
  let rec parse_module_attrs file = function
    | [] -> (match file with
        None -> 
          raise (Extensions.Error_in_config_file
                   ("Missing module attribute in <eliom>"))
      | Some s -> s)
    | ("module", s)::suite ->
        (match file with
          None -> parse_module_attrs (Some [s]) suite
        | _ -> raise (Error_in_config_file
                        ("Duplicate attribute file in <eliom>")))
    | ("findlib-package", s)::suite ->
        begin match file with
          | None ->
              begin try
                parse_module_attrs (Some (Ocsigen_loader.findfiles s)) suite
              with Ocsigen_loader.Findlib_error _ as e ->
                raise (Error_in_config_file
                         (Printf.sprintf "Findlib error: %s"
                            (Ocsigen_loader.error_message e)))
              end
          | _ -> raise (Error_in_config_file
                          ("Duplicate attribute file in <eliom>"))
        end
    | (s, _)::_ ->
        raise
          (Error_in_config_file ("Wrong attribute for <eliom>: "^s))
  in fun _ parse_site -> function
    | Element ("eliom", atts, content) -> 
(*--- if we put the line "new_sitedata" here, then there is 
  one service table for each <eliom> tag ...
  I think the other one is the best, because it corresponds to the way
  browsers manage cookies (one cookie for one site).
  Thus we can have one site in several cmo (with one session).
 *)
        let file = parse_module_attrs None atts in
        load_eliom_module sitedata file content;
        Eliommod_pagegen.gen sitedata charset
    | Element (t, _, _) -> 
        raise (Extensions.Bad_config_tag_for_extension t)
    | _ -> raise (Error_in_config_file "(Eliommod extension)")


(*****************************************************************************)
(** Function to be called at the beginning of the initialisation phase *)
let start_init () = ()

(** Function to be called at the end of the initialisation phase *)
let end_init () =
  Eliom_common.verify_all_registered 
    (Eliom_common.get_current_sitedata ());
  Eliom_common.end_current_sitedata ()

(** Function that will handle exceptions during the initialisation phase *)
let handle_init_exn = function
  | Eliom_common.Eliom_duplicate_registration s -> 
      ("Fatal - Eliom: Duplicate registration of url \""^s^
       "\". Please correct the module.")
  | Eliom_common.Eliom_there_are_unregistered_services (s, l1, l2) ->
      ("Fatal - Eliom: in site \""^
       (Ocsigen_lib.string_of_url_path s)^"\" - "^
       (match l1 with
       | [] -> ""
       | [a] -> "One service or coservice has not been registered on URL \""
           ^(Ocsigen_lib.string_of_url_path a)^"\". "
       | a::ll -> 
           let string_of = Ocsigen_lib.string_of_url_path in
           "Some services or coservices have not been registered \
             on URLs: "^
             (List.fold_left
                (fun beg v -> beg^", "^(string_of v))
                (string_of a)
                ll
             )^". ")^
       (match l2 with
       | [] -> ""
       | [Eliom_common.Na_get' _] -> "One non-attached GET coservice has not been registered."
       | [Eliom_common.Na_post' _] -> "One non-attached POST coservice has not been registered."
       | [Eliom_common.Na_get_ a] -> "The non-attached GET service \""
           ^a^
           "\" has not been registered."
       | [Eliom_common.Na_post_ a] -> "The non-attached POST service \""
           ^a^
           "\" has not been registered."
       | a::ll -> 
           let string_of = function
             | Eliom_common.Na_no -> "<no>"
             | Eliom_common.Na_get' _ -> "<GET coservice>"
             | Eliom_common.Na_get_ n -> n^" (GET)"
             | Eliom_common.Na_post' _ -> "<POST coservice>"
             | Eliom_common.Na_post_ n -> n^" (POST)"
           in
           "Some non-attached services or coservices have not been registered: "^
             (List.fold_left
                (fun beg v -> beg^", "^(string_of v))
                (string_of a)
                ll
             )^".")^
         "\nPlease correct your modules and make sure you have linked in all the modules...")
  | Eliom_common.Eliom_function_forbidden_outside_site_loading f ->
      ("Fatal - Eliom: Bad use of function \""^f^
         "\" outside site loading. \
         (for some functions, you must add the ~sp parameter \
               to use them after initialization. \
               Creation or registration of public service for example)")
  | Eliom_common.Eliom_page_erasing s ->
      ("Fatal - Eliom: You cannot create a page or directory here. "^s^
       " already exists. Please correct your modules.")
  | Eliom_common.Eliom_error_while_loading_site s ->
      ("Fatal - Eliom: Error while loading site: "^s)
  | e -> raise e


(*****************************************************************************)
(** extension registration *)
let _ = register_extension
  (fun hostpattern -> parse_config)
  Extensions.void_extension
  start_init
  end_init
  handle_init_exn

let _ = Eliommod_gc.persistent_session_gc ()



