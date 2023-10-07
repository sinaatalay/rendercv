%%
%% This is file `l3doc.cls',
%% generated with the docstrip utility.
%%
%% The original source files were:
%%
%% l3doc.dtx  (with options: `class')
%% 
%% Copyright (C) 1990-2023 The LaTeX Project
%% 
%% It may be distributed and/or modified under the conditions of
%% the LaTeX Project Public License (LPPL), either version 1.3c of
%% this license or (at your option) any later version.  The latest
%% version of this license is in the file:
%% 
%%    https://www.latex-project.org/lppl.txt
%% 
%% This file is part of the "l3kernel bundle" (The Work in LPPL)
%% and all files in that bundle must be distributed together.
%% 
%% File: l3doc.dtx
\RequirePackage{expl3,calc}
\ProvidesExplClass{l3doc}{2023-08-09}{}
  {L3 Experimental documentation class}
\clist_new:N \g_docinput_clist
\seq_new:N \g_doc_functions_seq
\seq_new:N \g_doc_macros_seq
\bool_new:N \l__codedoc_detect_internals_bool
\bool_set_true:N \l__codedoc_detect_internals_bool
\tl_new:N \l__codedoc_detect_internals_tl
\tl_new:N \l__codedoc_detect_internals_cs_tl
\coffin_new:N \l__codedoc_output_coffin
\coffin_new:N \l__codedoc_functions_coffin
\coffin_new:N \l__codedoc_descr_coffin
\coffin_new:N \l__codedoc_syntax_coffin
\box_new:N \g__codedoc_syntax_box
\bool_new:N \l__codedoc_in_function_bool
\bool_new:N \l__codedoc_long_name_bool
\dim_new:N \l__codedoc_trial_width_dim
\int_new:N \l__codedoc_nested_macro_int
\bool_new:N \l__codedoc_macro_tested_bool
\prop_new:N \g__codedoc_missing_tests_prop
\seq_new:N \g__codedoc_not_tested_seq
\seq_new:N \g__codedoc_testfiles_seq
\bool_new:N \l__codedoc_macro_internal_set_bool
\bool_new:N \l__codedoc_macro_internal_bool
\bool_new:N \l__codedoc_macro_TF_bool
\bool_new:N \l__codedoc_macro_pTF_bool
\bool_new:N \l__codedoc_macro_noTF_bool
\bool_new:N \l__codedoc_macro_EXP_bool
\bool_new:N \l__codedoc_macro_rEXP_bool
\bool_new:N \l__codedoc_macro_var_bool
\tl_new:N \l__codedoc_override_module_tl
\tl_set:Nn \l__codedoc_override_module_tl { \q_no_value }
\tl_new:N \l__codedoc_macro_documented_tl
\bool_new:N \g__codedoc_lmodern_bool
\bool_new:N \g__codedoc_checkfunc_bool
\bool_new:N \g__codedoc_checktest_bool
\bool_new:N \g__codedoc_kernel_bool
\bool_new:N \g__codedoc_cs_break_bool
\bool_new:N \g__codedoc_show_notes_bool
\bool_gset_true:N \g__codedoc_cs_break_bool
\tl_new:N \l__codedoc_tmpa_tl
\tl_new:N \l__codedoc_tmpb_tl
\int_new:N \l__codedoc_tmpa_int
\int_new:N \l__codedoc_tmpa_seq
\tl_new:N \l__codedoc_names_block_tl
\seq_new:N \g__codedoc_variants_seq
\bool_new:N \l__codedoc_names_verb_bool
\seq_new:N \l__codedoc_names_seq
\seq_new:N \g__codedoc_nested_names_seq
\tl_new:N \l__codedoc_index_macro_tl
\tl_new:N \l__codedoc_index_key_tl
\tl_new:N \l__codedoc_index_module_tl
\tl_new:N \l__codedoc_macro_do_not_index_tl
\bool_new:N \l__codedoc_index_internal_bool
\tl_new:N \g__codedoc_module_name_tl
\tl_const:Nn \c__codedoc_iow_rule_tl
  { ======================================== }
\tl_const:Nn \c__codedoc_iow_mid_rule_tl
  { -------------------------------------- }
\box_new:N \l__codedoc_macro_box
\box_new:N \l__codedoc_macro_index_box
\int_new:N \l__codedoc_macro_int
\tl_new:N \l__codedoc_cmd_tl
\tl_new:N \l__codedoc_cmd_index_tl
\tl_new:N \l__codedoc_cmd_module_tl
\bool_new:N \l__codedoc_cmd_noindex_bool
\bool_new:N \l__codedoc_cmd_replace_bool
\bool_new:N \l__codedoc_in_implementation_bool
\bool_new:N \g__codedoc_typeset_documentation_bool
\bool_new:N \g__codedoc_typeset_implementation_bool
\bool_set_true:N \g__codedoc_typeset_documentation_bool
\bool_set_true:N \g__codedoc_typeset_implementation_bool
\tl_new:N \g__codedoc_base_name_tl
\prop_new:N \l__codedoc_variants_prop
\clist_new:N \l__codedoc_function_label_clist
\bool_new:N \l__codedoc_no_label_bool
\tl_new:N \l__codedoc_date_added_tl
\tl_new:N \l__codedoc_date_updated_tl
\tl_new:N \l__codedoc_macro_argument_tl
\cs_new_eq:NN \__codedoc_tmpa:w ?
\cs_new_eq:NN \__codedoc_tmpb:w ?
\cs_generate_variant:Nn \seq_set_split:Nnn { NoV }
\cs_generate_variant:Nn \seq_gput_right:Nn { Nf }
\cs_generate_variant:Nn \str_case:nn { fn }
\cs_generate_variant:Nn \tl_count:n { f }
\cs_generate_variant:Nn \tl_greplace_all:Nnn { Nx , Nno }
\cs_generate_variant:Nn \tl_if_empty:nTF { f }
\cs_generate_variant:Nn \tl_if_head_eq_charcode:nNTF { o }
\cs_generate_variant:Nn \tl_if_head_eq_charcode:nNT  { o }
\cs_generate_variant:Nn \tl_if_head_eq_charcode:nNF  { o }
\cs_generate_variant:Nn \tl_if_head_eq_meaning:nNF  { V }
\cs_generate_variant:Nn \tl_if_in:nnTF { no , oo }
\cs_generate_variant:Nn \tl_if_in:NnTF { No }
\cs_generate_variant:Nn \tl_if_in:NnT  { No }
\cs_generate_variant:Nn \tl_if_in:NnF  { No }
\cs_generate_variant:Nn \tl_remove_all:Nn   { Nx }
\cs_generate_variant:Nn \tl_replace_all:Nnn { Nx , Nnx, No , Nno }
\cs_generate_variant:Nn \tl_replace_once:Nnn { Noo }
\cs_generate_variant:Nn \tl_set_rescan:Nnn { NnV }
\cs_generate_variant:Nn \tl_to_str:n { f , o }
\cs_generate_variant:Nn \prop_get:NnNTF { Nx }
\cs_generate_variant:Nn \prop_put:Nnn { Nx }
\cs_generate_variant:Nn \prop_gput:Nnn { NVx }
\prg_new_protected_conditional:Npnn \__codedoc_if_almost_str:n #1 { TF , T , F }
  {
    \int_compare:nNnTF
      { \tl_count:n {#1} }
      < { \tl_count:f { \tl_to_str:f {#1} } }
      { \prg_return_false: }
      { \prg_return_true: }
  }
\cs_generate_variant:Nn \__codedoc_if_almost_str:nT { V }
\cs_new_protected:Npn \__codedoc_trim_right:Nn #1#2
  {
    \cs_set:Npn \__codedoc_tmp:w ##1 #2 ##2 \q_stop { \exp_not:n {##1} }
    \__kernel_tl_set:Nx #1 { \exp_after:wN \__codedoc_tmp:w #1 #2 \q_stop }
  }
\cs_generate_variant:Nn \__codedoc_trim_right:Nn { No }
\prg_new_protected_conditional:Npnn \__codedoc_str_if_begin:nn #1#2 { TF , T , F }
  {
    \tl_if_in:ooTF
      { \exp_after:wN \scan_stop: \tl_to_str:n {#1} }
      { \exp_after:wN \scan_stop: \tl_to_str:n {#2} }
      { \prg_return_true: }
      { \prg_return_false: }
  }
\prg_generate_conditional_variant:Nnn \__codedoc_str_if_begin:nn
  { oo } { TF , T , F }
\cs_new_protected:Npn \__codedoc_replace_at_at:N #1
  {
    \tl_if_empty:NF \g__codedoc_module_name_tl
      {
        \exp_args:NNo \__codedoc_replace_at_at_aux:Nn
          #1 \g__codedoc_module_name_tl
      }
  }
\cs_new_protected:Npx \__codedoc_replace_at_at_aux:Nn #1#2
  {
    \tl_replace_all:Nnn #1 { \token_to_str:N @ } { @ }
    \tl_replace_all:Nnn #1 { \token_to_str:N _ } { _ }
    \tl_replace_all:Nnn #1 { @ @ @ @ } { \token_to_str:N a a }
    \tl_replace_all:Nnn #1 { _ _ @ @ } { _ _ #2 }
    \tl_replace_all:Nnn #1 {   _ @ @ } { _ _ #2 }
    \tl_replace_all:Nnn #1 {     @ @ } { _ _ #2 }
    \tl_replace_all:Nnn #1 { \token_to_str:N a a } { @ @ }
  }
\cs_new_protected:Npn \__codedoc_detect_internals:N #1
  {
    \bool_if:NT \l__codedoc_detect_internals_bool
      { \__codedoc_detect_internals_aux:N #1 }
  }
\group_begin:
  \char_set_catcode_active:N \^^M
  \cs_new_protected:Npn \__codedoc_detect_internals_aux:N #1
    {
      \tl_set_eq:NN \l__codedoc_detect_internals_tl #1
      \tl_replace_all:Non \l__codedoc_detect_internals_tl { \token_to_str:N _ } { _ }
      \seq_set_split:NnV \l__codedoc_tmpa_seq { _ _ } \l__codedoc_detect_internals_tl
      \seq_pop_left:NN \l__codedoc_tmpa_seq \l__codedoc_detect_internals_tl
      \seq_map_variable:NNn \l__codedoc_tmpa_seq \l__codedoc_detect_internals_tl
        {
          \__codedoc_trim_right:No \l__codedoc_detect_internals_tl
            \c_catcode_active_space_tl
          \__codedoc_trim_right:Nn \l__codedoc_detect_internals_tl ^^M
          \__codedoc_if_detect_internals_ok:NF \l__codedoc_detect_internals_tl
            {
              \tl_set_eq:NN \l__codedoc_detect_internals_cs_tl \l__codedoc_detect_internals_tl
              \__codedoc_trim_right:Nn \l__codedoc_detect_internals_tl _
              \__codedoc_trim_right:Nn \l__codedoc_detect_internals_tl :
              \__codedoc_trim_right:No \l__codedoc_detect_internals_tl { \token_to_str:N : }
              \msg_warning:nnxxx { l3doc } { foreign-internal }
                { \tl_to_str:N \l__codedoc_detect_internals_cs_tl }
                { \tl_to_str:N \l__codedoc_detect_internals_tl }
                { \tl_to_str:N \g__codedoc_module_name_tl }
            }
        }
    }
\group_end:
\prg_new_protected_conditional:Npnn \__codedoc_if_detect_internals_ok:N #1 { F }
  {
    \__codedoc_str_if_begin:ooTF {#1} { \g__codedoc_module_name_tl _ }
      { \prg_return_true: }
      {
        \__codedoc_str_if_begin:ooTF {#1} { \g__codedoc_module_name_tl : }
          { \prg_return_true: }
          {
            \bool_if:NTF \g__codedoc_kernel_bool
              {
                \__codedoc_str_if_begin:ooTF {#1} { kernel _ }
                  { \prg_return_true: }
                  { \prg_return_false: }
              }
              { \prg_return_false: }
          }
      }
  }
\cs_new:Npn \__codedoc_signature_base_form:n #1
  { \__codedoc_signature_base_form_aux:n #1 \q_stop }
\cs_new:Npn \__codedoc_signature_base_form_aux:n #1
  {
    \str_case:nnTF {#1}
      {
        { N } { N }
        { c } { N }
        { n } { n }
        { o } { n }
        { f } { n }
        { e } { n }
        { x } { n }
        { V } { n }
        { v } { n }
      }
      { \__codedoc_signature_base_form_aux:n }
      { \__codedoc_signature_base_form_aux:w #1 }
  }
\cs_new:Npn \__codedoc_signature_base_form_aux:w #1 \q_stop
  { \exp_not:n {#1} }
\cs_new:Npn \__codedoc_predicate_from_base:n #1
  {
    \__codedoc_get_function_name:n {#1}
    \tl_to_str:n { _p: }
    \__codedoc_get_function_signature:n {#1}
  }
\cs_new:Npn \__codedoc_get_function_name:n #1
  { \__codedoc_split_function_do:nn {#1} { \use_i:nnn } }
\cs_new:Npn \__codedoc_get_function_signature:n #1
  { \__codedoc_split_function_do:nn {#1} { \use_ii:nnn } }
\cs_set_protected:Npn \__codedoc_tmpa:w #1
  {
    \cs_new:Npn \__codedoc_split_function_do:nn ##1
      {
        \exp_after:wN \__codedoc_split_function_auxi:w
        \tl_to_str:n {##1} \q_mark \c_true_bool
        #1 \q_mark \c_false_bool
        \q_stop
      }
    \cs_new:Npn \__codedoc_split_function_auxi:w
      ##1 #1 ##2 \q_mark ##3##4 \q_stop ##5
      { \__codedoc_split_function_auxii:w {##5} ##1 \q_mark \q_stop {##2} ##3 }
    \cs_new:Npn \__codedoc_split_function_auxii:w
      ##1##2 \q_mark ##3 \q_stop
      { ##1 {##2} }
  }
\exp_args:No \__codedoc_tmpa:w { \token_to_str:N : }
\cs_generate_variant:Nn \__codedoc_split_function_do:nn { o }
\cs_new_protected:Npn \__codedoc_key_get_base:nN #1#2
  {
    \__codedoc_if_almost_str:nTF {#1}
      {
        \__codedoc_key_get_base_TF:nN {#1} \l__codedoc_tmpa_tl
        \__kernel_tl_set:Nx #2
          { \__codedoc_split_function_do:on \l__codedoc_tmpa_tl { \__codedoc_base_form_aux:nnN } }
      }
      { \tl_set:Nn #2 {#1} }
  }
\cs_new:Npx \__codedoc_key_get_base_TF:nN #1#2
  {
    \__kernel_tl_set:Nx #2 { \exp_not:N \tl_to_str:n {#1} }
    \tl_if_in:NoF #2 { \tl_to_str:n {:} }
      { \exp_not:N \prg_break: }
    \tl_if_in:onT { #2 z } { \tl_to_str:n {TF} z }
      { \exp_not:N \prg_break: }
    \tl_if_in:onT { #2 z } { \tl_to_str:n {T} z }
      {
        \tl_put_right:Nn #2 { \tl_to_str:n {F} }
        \exp_not:N \prg_break:
      }
    \tl_if_in:onT { #2 z } { \tl_to_str:n {F} z }
      {
        \tl_put_right:Nn #2 { z }
        \tl_replace_once:Nnn #2 { \tl_to_str:n {F} z } { \tl_to_str:n {TF} }
        \exp_not:N \prg_break:
      }
    \exp_not:N \prg_break_point:
  }
\cs_new:Npn \__codedoc_base_form_aux:nnN #1#2#3
  {
    \exp_not:n {#1}
    \bool_if:NT #3
      {
        \token_to_str:N :
        \bool_lazy_or:nnTF
            { \str_if_eq_p:nn { #1 ~ } { \exp_args } }
            { \str_if_eq_p:nn { #1 ~ } { \exp_last_unbraced } }
          { \exp_not:n {#2} }
          { \__codedoc_signature_base_form:n {#2} }
      }
  }
\cs_new_protected:Npn \__codedoc_base_form_signature_do:nnn #1#2#3
  {
    \__codedoc_split_function_do:nn {#1}
      { \__codedoc_base_form_aux:nnnnnN {#1} {#2} {#3} }
  }
\cs_new_protected:Npn \__codedoc_base_form_aux:nnnnnN #1#2#3#4#5#6
  {
    \bool_if:NTF #6
      {
        \tl_if_head_eq_charcode:nNTF {#4} :
          { #2 {#1} }
          {
            \use:x
              {
                \exp_not:n {#3}
                { \__codedoc_base_form_aux:nnN {#4} {#5} #6 }
              }
                {#4} {#5}
          }
      }
      { #2 {#1} }
  }
\prg_new_conditional:Npnn \__codedoc_date_compare:nNn #1#2#3 { TF , T , F , p }
  { \__codedoc_date_compare_aux:w #1--- \q_mark #2 #3--- \q_stop }
\cs_new:Npn \__codedoc_date_compare_aux:w
    #1 - #2 - #3 - #4 \q_mark #5 #6 - #7 - #8 - #9 \q_stop
  {
    \__codedoc_date_compare_aux:nnnNnnn
      { \tl_if_empty:nTF {#1} { 0 } {#1} }
      { \tl_if_empty:nTF {#2} { 0 } {#2} }
      { \tl_if_empty:nTF {#3} { 0 } {#3} }
      #5
      { \tl_if_empty:nTF {#6} { 0 } {#6} }
      { \tl_if_empty:nTF {#7} { 0 } {#7} }
      { \tl_if_empty:nTF {#8} { 0 } {#8} }
  }
\cs_new:Npn \__codedoc_date_compare_aux:nnnNnnn #1#2#3#4#5#6#7
  {
    \int_compare:nNnTF {#1} = {#5}
      {
        \int_compare:nNnTF {#2} = {#6}
          {
            \int_compare:nNnTF {#3} #4 {#7}
              { \prg_return_true: } { \prg_return_false: }
          }
          {
            \int_compare:nNnTF {#2} #4 {#6}
              { \prg_return_true: } { \prg_return_false: }
          }
      }
      {
        \int_compare:nNnTF {#1} #4 {#5}
          { \prg_return_true: } { \prg_return_false: }
      }
    \use_none:n
    \q_stop
  }
\cs_new:Npn \__codedoc_gprop_name:n #1 { g__codedoc ~ \tl_to_str:n {#1} }
\cs_new:Npn \__codedoc_lseq_name:n #1 { l__codedoc ~ \tl_to_str:n {#1} }
\msg_new:nnnn { l3doc } { no-signature-TF }
  { Function/macro~'#1'~cannot~be~turned~into~a~conditional. }
  {
    A~function~or~macro~environment~with~option~pTF,~TF~or~noTF~
    received~the~argument~'#1'.~This~function's~name~has~no~
    ':'~hence~it~is~not~clear~where~to~add~'_p'~or~'TF'.~
    Please~follow~expl3~naming~conventions.
  }
\msg_new:nnn { l3doc } { date-format }
  { The~date~'#1'~should~be~given~in~YYYY-MM-DD~format. }
\msg_new:nnn { l3doc } { future-date }
  { The~added/updated~date~'#2'~of~'#1'~is~in~the~future. }
\msg_new:nnn { l3doc } { syntax-nested-function }
  {
    The~'syntax'~environment~should~be~used~in~the~
    innermost~'function'~environment.
  }
\msg_new:nnn { l3doc } { multiple-syntax }
  {
    The~'syntax'~environment~should~only~be~used~once~in~
    a~'function'~environment.
  }
\msg_new:nnn { l3doc } { deprecated-option }
  { The~option~'#1'~has~been~deprecated~for~'#2'. }
\msg_new:nnn { l3doc } { foreign-internal }
  {
    A~control~sequence~of~the~form~'...__#1'~was~used.~
    It~should~only~be~used~in~the~module~'#2'
    \tl_if_empty:nF {#3} { ,~not~in~'#3' } .
  }
\DeclareOption { a5paper } { \@latexerr { Option~not~supported } { } }
\DeclareOption { full }
  {
    \bool_gset_true:N \g__codedoc_typeset_documentation_bool
    \bool_gset_true:N \g__codedoc_typeset_implementation_bool
  }
\DeclareOption { onlydoc }
  {
    \bool_gset_true:N \g__codedoc_typeset_documentation_bool
    \bool_gset_false:N \g__codedoc_typeset_implementation_bool
  }
\DeclareOption { check }
  { \bool_gset_true:N \g__codedoc_checkfunc_bool }
\DeclareOption { nocheck }
  { \bool_gset_false:N \g__codedoc_checkfunc_bool }
\DeclareOption { checktest }
  { \bool_gset_true:N \g__codedoc_checktest_bool }
\DeclareOption { nochecktest }
  { \bool_gset_false:N \g__codedoc_checktest_bool }
\DeclareOption { kernel }
  { \bool_gset_true:N \g__codedoc_kernel_bool }
\DeclareOption { stdmodule }
  { \bool_gset_false:N \g__codedoc_kernel_bool }
\DeclareOption { cm-default }
  { \bool_gset_false:N \g__codedoc_lmodern_bool }
\DeclareOption { lm-default }
  { \bool_gset_true:N \g__codedoc_lmodern_bool }
\DeclareOption { cs-break-off }
  { \bool_gset_false:N \g__codedoc_cs_break_bool }
\DeclareOption { cs-break-nohyphen }
  { \PassOptionsToPackage{nohyphen}{underscore} }
\DeclareOption { show-notes }
  { \bool_gset_true:N  \g__codedoc_show_notes_bool }
\DeclareOption { hide-notes }
  { \bool_gset_false:N \g__codedoc_show_notes_bool }
\DeclareOption* { \PassOptionsToClass { \CurrentOption } { article } }
\ExecuteOptions { full, kernel, nocheck, nochecktest, lm-default }
\PassOptionsToClass { a4paper } { article }
\msg_new:nnn { l3doc } { input-cfg }
  { Local~config~file~l3doc.cfg~loaded. }
\file_if_exist:nT { l3doc.cfg }
  {
    \file_input:n { l3doc.cfg }
    \cs_if_exist:cF { ExplMakeTitle }
      { \msg_info:nn { l3doc } { input-cfg } }
  }
\ProcessOptions
\LoadClass{article}
\RequirePackage{doc}
\RequirePackage
  {
    array,
    alphalph,
    amsmath,
    amssymb,
    booktabs,
    color,
    colortbl,
    hologo,
    enumitem,
    pifont,
    textcomp,
    trace,
    csquotes,
    fancyvrb,
    underscore,
    verbatim
  }
\raggedbottom
\bool_if:NT \g__codedoc_lmodern_bool
  {
    \RequirePackage[T1]{fontenc}
    \RequirePackage{lmodern}
    \group_begin:
      \ttfamily
      \DeclareFontShape{T1}{lmtt}{m}{it}{<->ec-lmtto10}{}
    \group_end:
  }
\RequirePackage{hypdoc}
\cs_gset:Npn \MakePrivateLetters
  {
    \char_set_catcode_letter:N \@
    \char_set_catcode_letter:N \_
    \char_set_catcode_letter:N \:
  }
\setcounter{StandardModuleDepth}{1}
\@addtoreset{CodelineNo}{part}
\tl_replace_once:Nnn \theCodelineNo
  { \HDorg@theCodelineNo }
  { \textcolor[gray]{0.5} { \sffamily\tiny\arabic{CodelineNo} } }
\fvset{gobble=2}
\cs_gset_eq:NN \verbatim \Verbatim
\cs_gset_eq:NN \endverbatim \endVerbatim
\cs_set_protected:Npn \ifnot@excluded
  {
    \exp_args:Nxx \expanded@notin
      { \c_backslash_str \tl_to_str:N \macro@namepart , }
      { \exp_args:NV \tl_to_str:n \index@excludelist }
  }
\cs_new:Npn \pdfstringnewline { : ~ }
\DeclareExpandableDocumentCommand
  { \__codedoc_pdfstring_newline:w } { s o m } { \pdfstringnewline #3 }
\pdfstringdefDisableCommands
  { \cs_set_eq:NN \\ \__codedoc_pdfstring_newline:w }
\setlength   \textwidth      { 385pt }
\addtolength \marginparwidth {  30pt }
\addtolength \oddsidemargin  {  20pt }
\addtolength \evensidemargin {  20pt }
\cs_new_eq:NN \__codedoc_oldlist:nn \list
\cs_gset:Npn \list #1 #2
  { \__codedoc_oldlist:nn {#1} { #2 \dim_zero:N \listparindent } }
\setlength \parindent  { 2em }
\setlength \itemindent { 0pt }
\setlength \parskip    { 0pt plus 3pt minus 0pt }
\tl_gset:Nn \partname {File}
\@addtoreset{section}{part}
\cs_gset:Npn \l@section #1#2
  {
    \ifnum \c@tocdepth >\z@
      \addpenalty\@secpenalty
      \addvspace{1.0em \@plus\p@}
      \setlength\@tempdima{2.5em}  % was 1.5em
      \begingroup
        \parindent \z@ \rightskip \@pnumwidth
        \parfillskip -\@pnumwidth
        \leavevmode \bfseries
        \advance\leftskip\@tempdima
        \hskip -\leftskip
        #1\nobreak\hfil \nobreak\hb@xt@\@pnumwidth{\hss #2}\par
      \endgroup
    \fi
  }
\cs_gset:Npn \l@subsection
  { \@dottedtocline{2}{2.5em}{2.3em} }  % #2 = 1.5em
\AtBeginDocument
  {
    \MakeShortVerb \"
    \MakeShortVerb \|
  }
\AtEndDocument
  {
    \DeleteShortVerb \"
    \DeleteShortVerb \|
  }
\providecommand*\eTeX{\hologo{eTeX}}
\providecommand*\IniTeX{\hologo{iniTeX}}
\providecommand*\Lua{Lua}
\providecommand*\LuaTeX{\hologo{LuaTeX}}
\providecommand*\pdfTeX{\hologo{pdfTeX}}
\providecommand*\XeTeX{\hologo{XeTeX}}
\providecommand*\pTeX{p\kern-.2em\hologo{TeX}}
\providecommand*\upTeX{up\kern-.2em\hologo{TeX}}
\providecommand*\epTeX{$\varepsilon$-\pTeX}
\providecommand*\eupTeX{$\varepsilon$-\upTeX}
\providecommand*\ConTeXt{\hologo{ConTeXt}}
\DeclareDocumentCommand \cmd { O{} m }
  { \__codedoc_cmd:no {#1} { \token_to_str:N #2 } }
\DeclareDocumentCommand \cs  { O{} m }
  { \__codedoc_cmd:no {#1} { \c_backslash_str #2 } }
\DeclareDocumentCommand \tn  { O{} m }
  {
    \__codedoc_cmd:no
      { module = TeX , replace = false , #1 }
      { \c_backslash_str #2 }
  }
\DeclareDocumentCommand \meta { m }
  { \__codedoc_meta:n {#1} }
\DeclareExpandableDocumentCommand
  { \__codedoc_pdfstring_cmd:w } { o m } { \token_to_str:N #2 }
\DeclareExpandableDocumentCommand
  { \__codedoc_pdfstring_cs:w }  { o m } { \textbackslash \tl_to_str:n {#2} }
\cs_new:Npn \__codedoc_pdfstring_meta:w #1
  { < \tl_to_str:n {#1} > }
\pdfstringdefDisableCommands
  {
    \cs_set_eq:NN \cmd  \__codedoc_pdfstring_cmd:w
    \cs_set_eq:NN \cs   \__codedoc_pdfstring_cs:w
    \cs_set_eq:NN \tn   \__codedoc_pdfstring_cs:w
    \cs_set_eq:NN \meta \__codedoc_pdfstring_meta:w
  }
\newcommand\Arg[1]
  { \texttt{\char`\{} \meta{#1} \texttt{\char`\}} }
\providecommand\marg[1]{ \Arg{#1} }
\providecommand\oarg[1]{ \texttt[ \meta{#1} \texttt] }
\providecommand\parg[1]{ \texttt( \meta{#1} \texttt) }
\DeclareRobustCommand \file {\nolinkurl}
\DeclareRobustCommand \env {\texttt}
\DeclareRobustCommand \pkg {\textsf}
\DeclareRobustCommand \cls {\textsf}
\NewDocumentCommand \EnableDocumentation { }
  { \bool_gset_true:N \g__codedoc_typeset_documentation_bool }
\NewDocumentCommand \EnableImplementation { }
  { \bool_gset_true:N \g__codedoc_typeset_implementation_bool }
\NewDocumentCommand \DisableDocumentation { }
  { \bool_gset_false:N \g__codedoc_typeset_documentation_bool }
\NewDocumentCommand \DisableImplementation { }
  { \bool_gset_false:N \g__codedoc_typeset_implementation_bool }
\NewDocumentEnvironment { documentation } { }
  {
    \bool_if:NTF \g__codedoc_typeset_documentation_bool
      { \bool_set_false:N \l__codedoc_in_implementation_bool }
      { \comment }
  }
  { \bool_if:NF \g__codedoc_typeset_documentation_bool { \endcomment } }
\NewDocumentEnvironment { implementation } { }
  {
    \bool_if:NTF \g__codedoc_typeset_implementation_bool
      { \bool_set_true:N \l__codedoc_in_implementation_bool }
      { \comment }
  }
  { \bool_if:NF \g__codedoc_typeset_implementation_bool { \endcomment } }
\DeclareDocumentEnvironment { variable } { O{} +v }
  {
    \bool_if:NTF \l__codedoc_in_implementation_bool
      { \__codedoc_macro:nnw { var , #1 } {#2} }
      { \__codedoc_function:nnw {#1} {#2} }
  }
  {
    \bool_if:NTF \l__codedoc_in_implementation_bool
      { \__codedoc_macro_end: }
      { \__codedoc_function_end: }
  }
\DeclareDocumentEnvironment { function } { O{} +v }
  { \__codedoc_function:nnw {#1} {#2} }
  { \__codedoc_function_end: }
\DeclareDocumentEnvironment { macro } { O{} +v }
  { \__codedoc_macro:nnw {#1} {#2} }
  { \__codedoc_macro_end: }
\NewDocumentEnvironment { syntax } { }
  { \__codedoc_syntax:w }
  {
    \__codedoc_syntax_end:
    \ignorespacesafterend
  }
\NewDocumentEnvironment { texnote } { }
  {
    \endgraf
    \vspace{3mm}
    \small\textbf{\TeX~hackers~note:}
  }
  {
    \vspace{3mm}
  }
\NewDocumentEnvironment { arguments } { }
  {
    \enumerate [
      nolistsep ,
      label = \texttt{\#\arabic*} ~ : ,
      labelsep = * ,
    ]
  }
  {
    \endenumerate
  }
\NewDocumentCommand { \CodedocExplain } { }
  { \CodedocExplainEXP \ \CodedocExplainREXP \ \CodedocExplainTF }
\NewDocumentCommand { \CodedocExplainEXP } { }
  {
    \raisebox{\baselineskip}[0pt][0pt]{\hypertarget{expstar}{}}%
    \write \@auxout { \def \string \Codedoc@expstar { } }
    \__codedoc_typeset_exp:\ indicates~fully~expandable~functions,~which~
    can~be~used~within~an~\texttt{x}-type~argument~(in~plain~
    \TeX{}~terms,~inside~an~\cs{edef}),~as~well~as~within~an~
    \texttt{f}-type~argument.
  }
\NewDocumentCommand { \CodedocExplainREXP } { }
  {
    \raisebox{\baselineskip}[0pt][0pt]{\hypertarget{rexpstar}{}}%
    \write \@auxout { \def \string \Codedoc@rexpstar { } }
    \__codedoc_typeset_rexp:\ indicates~
    restricted~expandable~functions,~which~can~be~used~within~an~
    \texttt{x}-type~argument~but~cannot~be~fully~expanded~within~an~
    \texttt{f}-type~argument.
  }
\NewDocumentCommand { \CodedocExplainTF } { }
  {
    \raisebox{\baselineskip}[0pt][0pt]{\hypertarget{explTF}{}}%
    \write \@auxout { \def \string \Codedoc@explTF { } }
    \__codedoc_typeset_TF:\ indicates~conditional~(\texttt{if})~functions~
    whose~variants~with~\texttt{T},~\texttt{F}~and~\texttt{TF}~
    argument~specifiers~expect~different~
    \enquote{true}/\enquote{false}~branches.
  }
\keys_define:nn { l3doc/cmd }
  {
    index     .tl_set:N     = \l__codedoc_cmd_index_tl        ,
    module    .tl_set:N     = \l__codedoc_cmd_module_tl       ,
    no-index  .bool_set:N   = \l__codedoc_cmd_noindex_bool    ,
    replace   .bool_set:N   = \l__codedoc_cmd_replace_bool    ,
  }
\cs_new_protected:Npn \__codedoc_cmd:nn #1#2
  {
    \bool_set_false:N \l__codedoc_cmd_noindex_bool
    \bool_set_true:N \l__codedoc_cmd_replace_bool
    \tl_set:Nn \l__codedoc_cmd_index_tl { \q_no_value }
    \tl_set:Nn \l__codedoc_cmd_module_tl { \q_no_value }
    \keys_set:nn { l3doc/cmd } {#1}
    \tl_set:Nn \l__codedoc_cmd_tl {#2}
    \bool_if:NT \l__codedoc_cmd_replace_bool
      {
        \tl_set_rescan:Nnn \l__codedoc_tmpb_tl { } { _ }
        \tl_replace_all:Non \l__codedoc_cmd_tl \l__codedoc_tmpb_tl { _ }
        \__codedoc_replace_at_at:N \l__codedoc_cmd_tl
        \tl_replace_all:Nno \l__codedoc_cmd_tl { _ } \l__codedoc_tmpb_tl
      }
    \mode_if_math:T { \mbox }
      {
        \bool_if:NT \l__codedoc_allow_indexing_bool { \__codedoc_target: }
        \verbatim@font
        \__codedoc_if_almost_str:VT \l__codedoc_cmd_tl
          {
            \__kernel_tl_set:Nx \l__codedoc_cmd_tl { \tl_to_str:N \l__codedoc_cmd_tl }
            \bool_if:NT \g__codedoc_cs_break_bool
              {
                \regex_replace_all:nnN
                  { ([^\\\_]\_*) \_ ([^\_]) }
                  { \1 \c{BreakableUnderscore} \2 }
                  \l__codedoc_cmd_tl
              }
          }
        \tl_replace_all:Nnn \l__codedoc_cmd_tl { ~ } { \@xobeysp }
        \l__codedoc_cmd_tl
        \@
      }
    \bool_if:NT \l__codedoc_allow_indexing_bool
     {
      \bool_if:NF \l__codedoc_cmd_noindex_bool
       {
        \quark_if_no_value:NF \l__codedoc_cmd_index_tl
          {
            \__kernel_tl_set:Nx \l__codedoc_cmd_tl
              { \c_backslash_str \exp_not:o { \l__codedoc_cmd_index_tl } }
          }
        \exp_args:No \__codedoc_key_get:n { \l__codedoc_cmd_tl }
        \quark_if_no_value:NF \l__codedoc_cmd_module_tl
          {
            \__kernel_tl_set:Nx \l__codedoc_index_module_tl
              { \tl_to_str:N \l__codedoc_cmd_module_tl }
          }
        \__codedoc_special_index_module:ooonN
          { \l__codedoc_index_key_tl }
          { \l__codedoc_index_macro_tl }
          { \l__codedoc_index_module_tl }
          { usage }
          \l__codedoc_index_internal_bool
       }
     }
  }
\cs_generate_variant:Nn \__codedoc_cmd:nn { no }
\cs_new_protected:Npn \__codedoc_meta:n #1
  {
    \tl_set:Nn \l__codedoc_tmpa_tl {#1}
    \tl_map_inline:nn
      { { 3 } { 4 } { 7 } { 8 } { 11 } { 12 } { 13 } }
      {
        \tl_set_rescan:Nnn \l__codedoc_tmpb_tl
          { \char_set_catcode:nn { `_ } {##1} } { _ }
        \tl_replace_all:Non \l__codedoc_tmpa_tl \l__codedoc_tmpb_tl
          { \__codedoc_ensuremath_sb:n }
      }
    \exp_args:NV \__codedoc_meta_original:n \l__codedoc_tmpa_tl
  }
\cs_new_protected:Npn \__codedoc_ensuremath_sb:n #1
  { \ensuremath { \sb {#1} } }
\cs_new_protected:Npn \__codedoc_meta_original:n #1
  {
    \ensuremath \langle
    \mode_if_math:T { \nfss@text }
    {
      \meta@font@select
      \edef \meta@hyphen@restore
        { \hyphenchar \the \font \the \hyphenchar \font }
      \hyphenchar \font \m@ne
      \language \l@nohyphenation
      #1 \/
      \meta@hyphen@restore
    }
    \ensuremath \rangle
  }
\cs_new_protected:Npn \__codedoc_typeset_exp:
  {
    \cs_if_exist:NTF \Codedoc@expstar
      { \hyperlink { expstar } }
      { \mbox }
    {$\star$}
  }
\cs_new_protected:Npn \__codedoc_typeset_rexp:
  {
    \cs_if_exist:NTF \Codedoc@rexpstar
      { \hyperlink { rexpstar } }
      { \mbox }
    { \ding { 73 } } % hollow star
  }
\cs_new_protected:Npn \__codedoc_typeset_TF:
  {
    \cs_if_exist:NTF \Codedoc@explTF
      { \hyperlink { explTF } }
      { \mbox }
      {
        \color{black}
        \itshape TF
        \makebox[0pt][r]
          {
            \cs_if_exist:NT \Codedoc@explTF { \color{red} }
            \underline { \phantom{\itshape TF} \kern-0.1em }
          }
      }
  }
\cs_new_protected:Npn \__codedoc_typeset_aux:n #1
  {
    { \color[gray]{0.5} #1 }
  }
\cs_new_protected:Npn \__codedoc_get_hyper_target:nN #1#2
  {
    \__kernel_tl_set:Nx #2 { \tl_to_str:n {#1} }
    \tl_replace_all:Nxn #2 { \c_underscore_str } { / }
    \tl_remove_all:Nx   #2 { \c_backslash_str }
    \tl_put_left:Nn #2 { doc/function// }
  }
\cs_generate_variant:Nn \__codedoc_get_hyper_target:nN { o , x }
\cs_new_protected:Npn \__codedoc_names_get_seq:nN #1#2
  {
    \__kernel_tl_set:Nx \l__codedoc_tmpa_tl { \tl_to_str:n {#1} }
    \bool_if:NTF \l__codedoc_names_verb_bool
      {
        \seq_clear:N #2
        \seq_put_right:NV #2 \l__codedoc_tmpa_tl
      }
      {
        \tl_remove_all:Nx \l__codedoc_tmpa_tl
          { \iow_char:N \^^M \c_percent_str }
        \tl_remove_all:Nx \l__codedoc_tmpa_tl { \tl_to_str:n { ^ ^ A } }
        \tl_remove_all:Nx \l__codedoc_tmpa_tl { \iow_char:N \^^I }
        \tl_remove_all:Nx \l__codedoc_tmpa_tl { \iow_char:N \^^M }
        \__codedoc_detect_internals:N \l__codedoc_tmpa_tl
        \__codedoc_replace_at_at:N \l__codedoc_tmpa_tl
        \exp_args:NNx \seq_set_from_clist:Nn #2
          { \tl_to_str:N \l__codedoc_tmpa_tl }
      }
  }
\cs_new_protected:Npn \__codedoc_names_parse:
  {
    \tl_clear:N \l__codedoc_names_block_tl
    \seq_map_function:NN
      \l__codedoc_names_seq
      \__codedoc_names_parse_one:n
  }
\cs_new_protected:Npn \__codedoc_names_parse_one:n #1
  {
    \__codedoc_split_function_do:nn {#1}
      { \__codedoc_names_parse_one_aux:nnNn }
    {#1}
  }
\cs_new_protected:Npn \__codedoc_names_parse_one_aux:nnNn #1#2#3#4
  {
    \bool_if:NTF #3
      {
        \tl_if_head_eq_charcode:nNTF {#2} :
          { \__codedoc_names_parse_aux:nnn {#4} {#4} { \scan_stop: } }
          {
            \exp_args:Nx \__codedoc_names_parse_aux:nnn
              { \__codedoc_base_form_aux:nnN {#1} {#2} #3 }
              {#1} {#2}
          }
      }
      {
        \bool_if:NT \l__codedoc_macro_TF_bool
          { \msg_error:nnx { l3doc } { no-signature-TF } {#4} }
        \__codedoc_names_parse_aux:nnn {#4} {#4} { \scan_stop: }
      }
  }
\cs_new_protected:Npn \__codedoc_names_parse_aux:nnn #1
  { \exp_args:Nc \__codedoc_names_parse_aux:Nnn { \__codedoc_lseq_name:n {#1} } }
\cs_new_protected:Npn \__codedoc_names_parse_aux:Nnn #1#2#3
  {
    \tl_if_in:NnF \l__codedoc_names_block_tl {#1}
      {
        \tl_put_right:Nn \l__codedoc_names_block_tl {#1}
        \seq_clear_new:N #1
        \seq_put_right:Nn #1 {#2}
      }
    \seq_put_right:Nn #1 {#3}
  }
\cs_new_protected:Npn \__codedoc_names_typeset:
  {
    \tl_map_function:NN \l__codedoc_names_block_tl
      \__codedoc_names_typeset_auxi:n
  }
\cs_new_protected:Npn \__codedoc_names_typeset_auxi:n #1
  {
    \seq_pop:NN #1 \l__codedoc_tmpa_tl
    \tl_gset_eq:NN \g__codedoc_base_name_tl \l__codedoc_tmpa_tl
    \tl_greplace_all:Nno \g__codedoc_base_name_tl
      { ~ } { \c_catcode_other_space_tl }
    \seq_get:NN #1 \l__codedoc_tmpa_tl
    \str_if_eq:VnTF \l__codedoc_tmpa_tl { \scan_stop: }
      {
        \seq_gclear:N \g__codedoc_variants_seq
        \__codedoc_names_typeset_auxii:x { \g__codedoc_base_name_tl }
      }
      {
        \seq_gset_eq:NN \g__codedoc_variants_seq #1
        \seq_gpop:NN \g__codedoc_variants_seq \l__codedoc_tmpb_tl
        \__codedoc_names_typeset_auxii:x
          { \g__codedoc_base_name_tl : \l__codedoc_tmpb_tl }
      }
  }
\cs_new_protected:Npn \__codedoc_names_typeset_auxii:n #1
  {
    \bool_if:NT \l__codedoc_macro_pTF_bool
      {
        \__codedoc_names_typeset_block:xN
          { \__codedoc_predicate_from_base:n {#1} }
          \c_false_bool
      }
    \bool_if:NT \l__codedoc_macro_noTF_bool
      { \__codedoc_names_typeset_block:nN {#1} \c_false_bool }
    \__codedoc_names_typeset_block:nN {#1} \l__codedoc_macro_TF_bool
  }
\cs_generate_variant:Nn \__codedoc_names_typeset_auxii:n { x }
\cs_new_protected:Npn \__codedoc_names_typeset_block:nN
  {
    \int_compare:nNnTF \l__codedoc_nested_macro_int = 0
      { \__codedoc_typeset_function_block:nN }
      { \__codedoc_macro_typeset_block:nN }
  }
\cs_generate_variant:Nn \__codedoc_names_typeset_block:nN { x }
\prg_new_conditional:Npnn \__codedoc_if_macro_internal:n #1 { p , T , F , TF }
  {
    \bool_if:NTF \l__codedoc_macro_internal_set_bool
      {
        \bool_if:NTF \l__codedoc_macro_internal_bool
          { \prg_return_true: } { \prg_return_false: }
      }
      {
        \tl_if_empty:fTF
          {
            \exp_after:wN \__codedoc_if_macro_internal_aux:w
            \tl_to_str:n { #1 ~ __ }
          }
          { \prg_return_false: } { \prg_return_true: }
      }
  }
\exp_last_unbraced:NNNNo
  \cs_new:Npn \__codedoc_if_macro_internal_aux:w #1 { \tl_to_str:n { __ } } { }
\cs_new_protected:Npn \__codedoc_names_block_base_map:N #1
  {
    \tl_map_inline:Nn \l__codedoc_names_block_tl
      {
        \group_begin:
          \seq_set_eq:NN \l__codedoc_tmpa_seq ##1
          \seq_pop:NN \l__codedoc_tmpa_seq \l__codedoc_tmpa_tl
          \seq_get:NN \l__codedoc_tmpa_seq \l__codedoc_tmpb_tl
          \exp_args:NNx
        \group_end:
        #1
          {
            \l__codedoc_tmpa_tl
            \str_if_eq:VnF \l__codedoc_tmpb_tl { \scan_stop: }
              { : \l__codedoc_tmpb_tl }
            \bool_if:NT \l__codedoc_macro_TF_bool { TF }
          }
      }
  }
\keys_define:nn { l3doc/function }
  {
    TF .value_forbidden:n = true ,
    TF .code:n =
      {
        \bool_set_true:N \l__codedoc_macro_TF_bool
      } ,
    EXP .value_forbidden:n = true ,
    EXP .code:n =
      {
        \bool_set_true:N \l__codedoc_macro_EXP_bool
        \bool_set_false:N \l__codedoc_macro_rEXP_bool
      } ,
    rEXP .value_forbidden:n = true ,
    rEXP .code:n =
      {
        \bool_set_false:N \l__codedoc_macro_EXP_bool
        \bool_set_true:N \l__codedoc_macro_rEXP_bool
      } ,
    pTF .value_forbidden:n = true ,
    pTF .code:n =
      {
        \bool_set_true:N \l__codedoc_macro_pTF_bool
        \bool_set_true:N \l__codedoc_macro_TF_bool
        \bool_set_true:N \l__codedoc_macro_EXP_bool
        \bool_set_false:N \l__codedoc_macro_rEXP_bool
      } ,
    noTF .value_forbidden:n = true ,
    noTF .code:n =
      {
        \bool_set_true:N \l__codedoc_macro_noTF_bool
        \bool_set_true:N \l__codedoc_macro_TF_bool
      } ,
    added .code:n = { \__codedoc_date_set_past:Nn \l__codedoc_date_added_tl {#1} },
    updated .code:n = { \__codedoc_date_set_past:Nn \l__codedoc_date_updated_tl {#1} } ,
    deprecated .code:n = {} , % A stub
    tested .code:n = { } ,
    label .code:n =
      {
        \clist_set:Nn \l__codedoc_function_label_clist {#1}
        \bool_set_true:N \l__codedoc_no_label_bool
      } ,
    verb .value_forbidden:n = true ,
    verb .bool_set:N = \l__codedoc_names_verb_bool ,
    module .tl_set:N = \l__codedoc_override_module_tl ,
  }
\cs_new_protected:Npn \__codedoc_date_set:Nn #1#2
  {
    \tl_set:Nn #1 {#2}
    \regex_replace_once:nnNF
      { \A(\d\d\d\d)[-/](\d\d?)[-/](\d\d?)\Z } { \1-\2-\3 } #1
      {
        \msg_error:nnn { l3doc } { date-format } {#2}
        \tl_set:Nn #1 { 1970-01-01 }
      }
  }
\cs_new_protected:Npn \__codedoc_date_set_past:Nn #1#2
  {
    \__codedoc_date_set:Nn #1 {#2}
    \exp_args:No \__codedoc_date_compare:nNnT
      {#1} > { \c_sys_year_int - \c_sys_month_int - \c_sys_day_int }
      {
        \msg_error:nnxx { l3doc } { future-date }
          { \tl_to_str:N \l__codedoc_macro_argument_tl }
          {#1}
      }
  }
\cs_new_protected:Npn \__codedoc_function:nnw #1#2
  {
    \__codedoc_function_typeset_start:
    \__codedoc_function_init:
    \tl_set:Nn \l__codedoc_macro_argument_tl {#2}
    \keys_set:nn { l3doc/function } {#1}
    \__codedoc_names_get_seq:nN {#2} \l__codedoc_names_seq
    \__codedoc_names_parse:
    \__codedoc_function_typeset:
    \__codedoc_function_reset:
    \__codedoc_function_descr_start:w
  }
\cs_new_protected:Npn \__codedoc_function_end:
  {
    \__codedoc_function_descr_stop:
    \__codedoc_function_assemble:
    \__codedoc_function_typeset_stop:
  }
\cs_new_protected:Npn \__codedoc_function_typeset_start:
  {
    \par \bigskip \noindent
  }
\cs_new_protected:Npn \__codedoc_function_typeset_stop:
  {
    \par
    \dim_set:Nn \prevdepth { \box_dp:N \l__codedoc_descr_coffin }
    \allowbreak
  }
\cs_new_protected:Npn \__codedoc_function_init:
  {
    \box_if_empty:NF \g__codedoc_syntax_box
      { \msg_error:nn { l3doc } { syntax-nested-function } }
    \coffin_clear:N \l__codedoc_descr_coffin
    \box_gclear:N \g__codedoc_syntax_box
    \coffin_clear:N \l__codedoc_syntax_coffin
    \coffin_clear:N \l__codedoc_functions_coffin
    \bool_set_false:N \l__codedoc_macro_TF_bool
    \bool_set_false:N \l__codedoc_macro_pTF_bool
    \bool_set_false:N \l__codedoc_macro_noTF_bool
    \bool_set_false:N \l__codedoc_macro_EXP_bool
    \bool_set_false:N \l__codedoc_macro_rEXP_bool
    \bool_set_false:N \l__codedoc_no_label_bool
    \bool_set_false:N \l__codedoc_names_verb_bool
    \bool_set_true:N \l__codedoc_in_function_bool
    \clist_clear:N \l__codedoc_function_label_clist
    \tl_set:Nn \l__codedoc_override_module_tl { \q_no_value }
    \char_set_active_eq:NN \< \__codedoc_shorthand_meta:
    \char_set_catcode_active:N \<
  }
\cs_new_protected:Npn \__codedoc_shorthand_meta:
  { \mode_if_math:TF { < } { \__codedoc_shorthand_meta:w } }
\cs_new_protected_nopar:Npn \__codedoc_shorthand_meta:w #1 > { \meta {#1} }
\cs_new_protected:Npn \__codedoc_function_reset:
  {
    \tl_set:Nn \l__codedoc_override_module_tl { \q_no_value }
  }
\cs_new_protected:Npn \__codedoc_function_typeset:
  {
    \dim_zero:N \l__codedoc_trial_width_dim
    \hcoffin_set:Nn \l__codedoc_functions_coffin { \__codedoc_typeset_functions: }
    \dim_set:Nn \l__codedoc_trial_width_dim
      { \box_wd:N \l__codedoc_functions_coffin }
    \bool_set:Nn \l__codedoc_long_name_bool
      { \dim_compare_p:nNn \l__codedoc_trial_width_dim > \marginparwidth }
  }
\cs_new_protected:Npn \__codedoc_function_descr_start:w
  {
    \vcoffin_set:Nnw \l__codedoc_descr_coffin { \textwidth }
      \noindent \ignorespaces
  }
\cs_new_protected:Npn \__codedoc_function_descr_stop:
  { \vcoffin_set_end: }
\cs_new_protected:Npn \__codedoc_function_assemble:
  {
    \hcoffin_set:Nn  \l__codedoc_syntax_coffin
      { \box_use_drop:N \g__codedoc_syntax_box }
    \bool_if:NTF \l__codedoc_long_name_bool
      {
        \coffin_join:NnnNnnnn
          \l__codedoc_output_coffin {hc} {vc}
          \l__codedoc_syntax_coffin {l} {T}
          {0pt} {0pt}
        \coffin_join:NnnNnnnn
          \l__codedoc_output_coffin {l} {t}
          \l__codedoc_functions_coffin  {r} {t}
          {-\marginparsep} {0pt}
        \coffin_join:NnnNnnnn
          \l__codedoc_output_coffin {l} {b}
          \l__codedoc_descr_coffin  {l} {t}
          {0.75\marginparwidth + \marginparsep} {-\medskipamount}
        \coffin_typeset:Nnnnn \l__codedoc_output_coffin
          {\l__codedoc_descr_coffin-l} {\l__codedoc_descr_coffin-t}
          {0pt} {0pt}
      }
      {
        \coffin_join:NnnNnnnn
          \l__codedoc_output_coffin {hc} {vc}
          \l__codedoc_syntax_coffin {l} {t}
          {0pt} {0pt}
        \coffin_join:NnnNnnnn
          \l__codedoc_output_coffin {l} {b}
          \l__codedoc_descr_coffin  {l} {t}
          {0pt} {-\medskipamount}
        \coffin_join:NnnNnnnn
          \l__codedoc_output_coffin {l} {t}
          \l__codedoc_functions_coffin  {r} {t}
          {-\marginparsep} {0pt}
        \coffin_typeset:Nnnnn \l__codedoc_output_coffin
          {\l__codedoc_syntax_coffin-l} {\l__codedoc_syntax_coffin-T}
          {0pt} {0pt}
      }
  }
\cs_new_protected:Npn \__codedoc_typeset_functions:
  {
    \small\ttfamily
    \__codedoc_target:
    \Hy@MakeCurrentHref { HD. \int_use:N \c@HD@hypercount }
    \begin{tabular} [t] { @{} l @{} >{\hspace{\tabcolsep}} r @{} }
      \toprule
      \__codedoc_function_extra_labels:
      \__codedoc_names_typeset:
      \__codedoc_typeset_dates:
      \bottomrule
    \end{tabular}
    \normalfont\normalsize
  }
\cs_new_protected:Npn \__codedoc_typeset_function_block:nN #1#2
  {
    \__codedoc_function_index:x
      { #1 \bool_if:NT #2 { \tl_to_str:n {TF} } }
    \__codedoc_function_label:xN {#1} #2
    #1
    \bool_if:NT #2 { \__codedoc_typeset_TF: }
    \__codedoc_typeset_expandability:
    \seq_if_empty:NF \g__codedoc_variants_seq
      { \__codedoc_typeset_variant_list:nN {#1} #2 }
    \\
  }
\cs_generate_variant:Nn \__codedoc_typeset_function_block:nN { x }
\cs_new_protected:Npn \__codedoc_function_index:n #1
  {
    \seq_gput_right:Nn \g_doc_functions_seq {#1}
    \__codedoc_special_index:nn {#1} { usage }
  }
\cs_generate_variant:Nn \__codedoc_function_index:n { x }
\cs_new_protected:Npn \__codedoc_typeset_expandability:
  {
    &
    \bool_if:NT \l__codedoc_macro_EXP_bool  { \__codedoc_typeset_exp: }
    \bool_if:NT \l__codedoc_macro_rEXP_bool { \__codedoc_typeset_rexp: }
  }
\cs_new_protected:Npn \__codedoc_typeset_variant_list:nN #1#2
  {
    \\
    \__codedoc_typeset_aux:n { \__codedoc_get_function_name:n {#1} }
    :
    \int_compare:nTF { \seq_count:N \g__codedoc_variants_seq == 1 }
      { \seq_use:Nn \g__codedoc_variants_seq { } }
      {
        \hbox_set:Nn \l_tmpa_box
          { \seq_use:Nn \g__codedoc_variants_seq { \textrm| \nolinebreak[2] } }
        \textrm(
        \dim_compare:nNnTF { \box_wd:N \l_tmpa_box } > { .4\columnwidth }
          {
            \parbox[t]{.4\columnwidth}
              {
                \raggedright
                \hbox_unpack_drop:N \l_tmpa_box
                \textrm)
                \bool_if:NT #2 { \__codedoc_typeset_TF: }
              }
          }
          {
            \hbox_unpack_drop:N \l_tmpa_box
            \textrm)
            \bool_if:NT #2 { \__codedoc_typeset_TF: }
          }
      }
    \__codedoc_typeset_expandability:
  }
\cs_new_protected:Npn \__codedoc_function_extra_labels:
  {
    \bool_if:NT \l__codedoc_no_label_bool
      {
        \clist_map_inline:Nn \l__codedoc_function_label_clist
          {
            \__codedoc_get_hyper_target:oN { \token_to_str:N ##1 }
              \l__codedoc_tmpa_tl
            \exp_args:No \label { \l__codedoc_tmpa_tl }
          }
      }
  }
\cs_new_protected:Npn \__codedoc_function_label:nN #1#2
  {
    \bool_if:NF \l__codedoc_no_label_bool
      {
        \__codedoc_get_hyper_target:xN
          {
            \exp_not:n {#1}
            \bool_if:NT #2 { \tl_to_str:n {TF} }
          }
          \l__codedoc_tmpa_tl
        \exp_args:No \label { \l__codedoc_tmpa_tl }
      }
  }
\cs_generate_variant:Nn \__codedoc_function_label:nN { x }
\cs_new:Npn \__codedoc_typeset_dates:
  {
    \bool_lazy_and:nnF
      { \tl_if_empty_p:N \l__codedoc_date_added_tl }
      { \tl_if_empty_p:N \l__codedoc_date_updated_tl }
      { \midrule }
    \tl_if_empty:NF \l__codedoc_date_added_tl
      {
        \multicolumn { 2 } { @{} r @{} }
          { \scriptsize New: \, \l__codedoc_date_added_tl } \\
      }

    \tl_if_empty:NF \l__codedoc_date_updated_tl
      {
        \multicolumn { 2 } { @{} r @{} }
          { \scriptsize Updated: \, \l__codedoc_date_updated_tl } \\
      }
  }
\dim_new:N \l__codedoc_syntax_dim
\cs_new_protected:Npn \__codedoc_syntax:w
  {
    \box_if_empty:NF \g__codedoc_syntax_box
      { \msg_error:nn { l3doc } { multiple-syntax } }
    \dim_set:Nn \l__codedoc_syntax_dim
      {
        \textwidth
        \bool_if:NT \l__codedoc_long_name_bool
          { + 0.75 \marginparwidth - \l__codedoc_trial_width_dim }
      }
    \hbox_gset:Nw \g__codedoc_syntax_box
      \small \ttfamily
      \arrayrulecolor{white}
      \begin{tabular} { @{} l @{} }
        \toprule
        \begin{minipage}[t]{\l__codedoc_syntax_dim}
          \raggedright
          \obeyspaces
          \obeylines
  }
\cs_new_protected:Npn \__codedoc_syntax_end:
  {
        \end{minipage}
      \end{tabular}
      \arrayrulecolor{black}
    \hbox_gset_end:
    \bool_if:NF \l__codedoc_in_function_bool
      {
        \begin{quote}
          \mode_leave_vertical:
          \box_use_drop:N \g__codedoc_syntax_box
        \end{quote}
      }
  }
\keys_define:nn { l3doc/macro }
  {
    aux .value_forbidden:n = true ,
    aux .code:n =
      {
        \msg_warning:nnnn { l3doc } { deprecated-option }
          { aux } { function/macro }
      } ,
    internal .value_forbidden:n = true ,
    internal .code:n =
      {
        \bool_set_true:N \l__codedoc_macro_internal_bool
        \bool_set_true:N \l__codedoc_macro_internal_set_bool
      } ,
    int .value_forbidden:n = true ,
    int .code:n =
      {
        \bool_set_true:N \l__codedoc_macro_internal_bool
        \bool_set_true:N \l__codedoc_macro_internal_set_bool
      } ,
    var .value_forbidden:n = true ,
    var .code:n =
      { \bool_set_true:N \l__codedoc_macro_var_bool } ,
    TF .value_forbidden:n = true ,
    TF .code:n =
      { \bool_set_true:N \l__codedoc_macro_TF_bool } ,
    pTF .value_forbidden:n = true ,
    pTF .code:n =
      {
        \bool_set_true:N \l__codedoc_macro_TF_bool
        \bool_set_true:N \l__codedoc_macro_pTF_bool
        \bool_set_true:N \l__codedoc_macro_EXP_bool
        \bool_set_false:N \l__codedoc_macro_rEXP_bool
      } ,
    noTF .value_forbidden:n = true ,
    noTF .code:n =
      {
        \bool_set_true:N \l__codedoc_macro_TF_bool
        \bool_set_true:N \l__codedoc_macro_noTF_bool
      } ,
    EXP .value_forbidden:n = true ,
    EXP .code:n =
      {
        \bool_set_true:N \l__codedoc_macro_EXP_bool
        \bool_set_false:N \l__codedoc_macro_rEXP_bool
      } ,
    rEXP .value_forbidden:n = true ,
    rEXP .code:n =
      {
        \bool_set_false:N \l__codedoc_macro_EXP_bool
        \bool_set_true:N \l__codedoc_macro_rEXP_bool
      } ,
    tested .code:n =
      {
        \bool_set_true:N \l__codedoc_macro_tested_bool
      } ,
    added .code:n = {} , % TODO
    updated .code:n = {} , % TODO
    deprecated .code:n = {} , % A stub
    verb .bool_set:N = \l__codedoc_names_verb_bool ,
    module .tl_set:N = \l__codedoc_override_module_tl ,
    documented-as .tl_set:N = \l__codedoc_macro_documented_tl ,
    do-not-index .value_required:n = true ,
    do-not-index .tl_set:N = \l__codedoc_macro_do_not_index_tl ,
    % do-not-index .default:n = \q_no_value ,
  }
\cs_new_protected:Npn \__codedoc_macro:nnw #1#2
  {
    \__codedoc_macro_init:
    \tl_set:Nn \l__codedoc_macro_argument_tl {#2}
    \keys_set:nn { l3doc/macro } {#1}
    \__codedoc_names_get_seq:nN {#2} \l__codedoc_names_seq
    \__codedoc_names_parse:
    \__codedoc_macro_exclude_index:
    \__codedoc_macro_save_names:
    \__codedoc_names_typeset:
    \__codedoc_macro_dump:
    \__codedoc_macro_reset:
  }
\cs_new_protected:Npn \__codedoc_macro_init:
  {
    \int_incr:N \l__codedoc_nested_macro_int
    \bool_set_false:N \l__codedoc_macro_internal_bool
    \bool_set_false:N \l__codedoc_macro_internal_set_bool
    \bool_set_false:N \l__codedoc_macro_TF_bool
    \bool_set_false:N \l__codedoc_macro_pTF_bool
    \bool_set_false:N \l__codedoc_macro_noTF_bool
    \bool_set_false:N \l__codedoc_macro_EXP_bool
    \bool_set_false:N \l__codedoc_macro_rEXP_bool
    \bool_set_false:N \l__codedoc_macro_var_bool
    \bool_set_false:N \l__codedoc_macro_tested_bool
    \bool_set_false:N \l__codedoc_names_verb_bool
    \tl_set:Nn \l__codedoc_override_module_tl { \q_no_value }
    \tl_clear:N \l__codedoc_macro_documented_tl
    \cs_set_eq:NN \testfile \__codedoc_print_testfile:n
    \box_clear:N \l__codedoc_macro_index_box
    \vbox_set:Nn \l__codedoc_macro_box
      {
        \hbox:n
          {
            \strut
            \int_compare:nNnT \l__codedoc_macro_int = 0 { \__codedoc_target: }
          }
        \vskip \int_eval:n { \l__codedoc_macro_int - 1 } \baselineskip
      }
  }
\cs_new_protected:Npn \__codedoc_macro_reset:
  {
    \tl_set:Nn \l__codedoc_override_module_tl { \q_no_value }
  }
\cs_new_protected:Npn \__codedoc_macro_save_names:
  {
    \tl_if_empty:NTF \l__codedoc_macro_documented_tl
      { \__codedoc_names_block_base_map:N \__codedoc_macro_save_names_aux:n }
      {
        \seq_gput_right:Nf \g__codedoc_nested_names_seq
          { \exp_after:wN \token_to_str:N \l__codedoc_macro_documented_tl }
      }
  }
\cs_new_protected:Npn \__codedoc_macro_save_names_aux:n #1
  { \seq_gput_right:Nn \g__codedoc_nested_names_seq {#1} }
\cs_new_protected:Npn \__codedoc_macro_exclude_index:
  {
    \tl_if_empty:NF \l__codedoc_macro_do_not_index_tl
      {
        \tl_set_rescan:NnV \l__codedoc_macro_do_not_index_tl
          { \MakePrivateLetters \catcode`\\12 }
          \l__codedoc_macro_do_not_index_tl
        \exp_args:NNV \seq_set_from_clist:Nn
          \l__codedoc_tmpa_seq \l__codedoc_macro_do_not_index_tl
        \__kernel_tl_set:Nx \l__codedoc_macro_do_not_index_tl
          { \seq_use:Nn \l__codedoc_tmpa_seq { , } }
        \exp_args:NV \DoNotIndex \l__codedoc_macro_do_not_index_tl
      }
  }
\cs_new_protected:Npn \__codedoc_macro_dump:
  {
    \topsep\MacroTopsep
    \trivlist
    \cs_set:Npn \makelabel ##1
      {
        \llap
          {
            \hbox_unpack_drop:N \l__codedoc_macro_index_box
            \vtop to \baselineskip
              {
                \vbox_unpack_drop:N \l__codedoc_macro_box
                \vss
              }
          }
      }
    \item [ ]
  }
\cs_new_protected:Npn \__codedoc_macro_typeset_block:nN #1#2
  {
    \__codedoc_macro_single:nNN {#1} \c_true_bool #2
    \seq_if_empty:NF \g__codedoc_variants_seq
      {
        \__codedoc_macro_typeset_variant_list:xN
          { \__codedoc_get_function_name:n {#1} } #2
      }
  }
\cs_generate_variant:Nn \__codedoc_macro_typeset_block:nN { x }
\cs_new_protected:Npn \__codedoc_macro_typeset_variant_list:nN #1#2
  {
    \seq_map_inline:Nn \g__codedoc_variants_seq
      { \__codedoc_macro_single:nNN { #1 : ##1 } \c_false_bool #2 }
  }
\cs_generate_variant:Nn \__codedoc_macro_typeset_variant_list:nN { x }
\cs_new_protected:Npn \__codedoc_macro_single:nNN #1#2#3
  {
    \tl_set:Nn \saved@macroname {#1}
    \__codedoc_macro_typeset_one:nN {#1} #3
    \bool_if:NT #3 { \DoNotIndex {#1} }
    \exp_args:Nx \__codedoc_macro_index:nN
      { #1 \bool_if:NT #3 { \tl_to_str:n { TF } } }
      #2
  }
\cs_new_protected:Npn \__codedoc_macro_index:nN #1#2
  {
    \DoNotIndex {#1}
    \bool_if:NT #2
      {
        \__codedoc_if_macro_internal:nF {#1}
          { \seq_gput_right:Nn \g_doc_macros_seq {#1} }
        \hbox_set:Nw \l__codedoc_macro_index_box
          \hbox_unpack_drop:N \l__codedoc_macro_index_box
          \int_gincr:N \c@CodelineNo
          \__codedoc_special_index:nn {#1} { main }
          \int_gdecr:N \c@CodelineNo
        \exp_args:NNNo \hbox_set_end:
          \tl_set:Nn \saved@indexname { \l__codedoc_index_key_tl }
      }
  }
\cs_new_protected:Npn \__codedoc_macro_typeset_one:nN #1#2
  {
    \vbox_set:Nn \l__codedoc_macro_box
      {
        \vbox_unpack_drop:N \l__codedoc_macro_box
        \hbox { \llap { \__codedoc_print_macroname:nN {#1} #2
            \MacroFont \
        } }
      }
    \int_incr:N \l__codedoc_macro_int
  }
\cs_new_protected:Npn \__codedoc_print_macroname:nN #1#2
  {
    \strut
    \__codedoc_get_hyper_target:xN
      {
        \exp_not:n {#1}
        \bool_if:NT #2 { \tl_to_str:n {TF} }
      }
      \l__codedoc_tmpa_tl
    \cs_if_exist:cTF { r@ \l__codedoc_tmpa_tl }
      { \exp_last_unbraced:NNo \hyperref [ \l__codedoc_tmpa_tl ] }
      { \use:n }
      {
        \int_compare:nTF { \str_count:n {#1} <= 28 }
          { \MacroFont } { \MacroLongFont }
        \tl_set:Nn \l__codedoc_tmpa_tl {#1}
        \tl_replace_all:Nno \l__codedoc_tmpa_tl
          { ~ } { \c_catcode_other_space_tl }
        \__codedoc_macroname_prefix:o \l__codedoc_tmpa_tl
        \__codedoc_macroname_suffix:N #2
      }
  }
\cs_new_protected:Npn \__codedoc_macroname_prefix:n #1
  {
    \__codedoc_if_macro_internal:nTF {#1}
      { \__codedoc_typeset_aux:n {#1} } {#1}
  }
\cs_generate_variant:Nn \__codedoc_macroname_prefix:n { o }
\cs_new_protected:Npn \__codedoc_macroname_suffix:N #1
  { \bool_if:NTF #1 { \__codedoc_typeset_TF: } { } }
\providecommand \MacroLongFont
  {
    \fontfamily{lmtt}\fontseries{lc}\small
  }
\cs_new_protected:Npn \__codedoc_print_testfile:n #1
  {
    \bool_set_true:N \l__codedoc_macro_tested_bool
    \tl_if_eq:nnF {#1} {*}
      {
        \seq_if_in:NnF \g__codedoc_testfiles_seq {#1}
          {
            \seq_gput_right:Nn \g__codedoc_testfiles_seq {#1}
            \par
            \__codedoc_print_testfile_aux:n {#1}
          }
      }
  }
\cs_new_protected:Npn \__codedoc_print_testfile_aux:n #1
  {
    \footnotesize
    (
    \textit
      {
        The~ test~ suite~ for~ this~ command,~
        and~ others~ in~ this~ file,~ is~ \textsf{#1}
      }.
    )\par
  }
\DeclareDocumentCommand \TestFiles {m}
  {
    \par
    \textit
      {
        The~ following~ test~ files~ are~
        used~ for~ this~ code:~ \textsf{#1}.
      }
    \par \ignorespaces
  }
\DeclareDocumentCommand \UnitTested { } { \testfile* }
\DeclareDocumentCommand \TestMissing { m }
  { \__codedoc_test_missing:n {#1} }
\cs_new_protected:Npn \__codedoc_test_missing:n #1
  {
    \__codedoc_test_missing_aux:Nxn
      \g__codedoc_missing_tests_prop
      { \seq_use:Nn \l__codedoc_names_seq { , } }
      { { \g_file_curr_name_str \c_space_tl (#1) } }
  }
\cs_new_protected:Npn \__codedoc_test_missing_aux:Nnn #1#2#3
  {
    \prop_get:NnNTF #1 {#2} \l__codedoc_tmpa_tl
      { \tl_put_right:Nn \l__codedoc_tmpa_tl { , #3 } }
      { \tl_set:Nn \l__codedoc_tmpa_tl {#3} }
    \prop_put:Nno #1 {#2} \l__codedoc_tmpa_tl
  }
\cs_generate_variant:Nn \__codedoc_test_missing_aux:Nnn { Nx }
\cs_new_protected:Npn \__codedoc_macro_end:
  {
    \endtrivlist
    \__codedoc_macro_end_check_tested:
    \int_compare:nNnT \l__codedoc_nested_macro_int = 1
      { \__codedoc_macro_end_style:n { \__codedoc_print_end_definition: } }
  }
\cs_new_protected:Npn \__codedoc_macro_end_check_tested:
  {
    \bool_lazy_all:nT
     {
       { \g__codedoc_checktest_bool }
       { ! \l__codedoc_macro_var_bool }
       { ! \l__codedoc_macro_tested_bool }
     }
     {
       \seq_set_filter:NNn \l__codedoc_tmpa_seq \l__codedoc_names_seq
         { ! \__codedoc_if_macro_internal_p:n {##1} }
       \seq_gput_right:Nx \g__codedoc_not_tested_seq
         {
           \seq_use:Nn \l__codedoc_tmpa_seq { , }
           \bool_if:NTF \l__codedoc_macro_pTF_bool {~(pTF)}
             { \bool_if:NT \l__codedoc_macro_TF_bool {~(TF)} }
         }
     }
  }
\cs_new_protected:Npn \__codedoc_macro_end_style:n #1
  {
    \nobreak \noindent
    { \footnotesize ( \emph{#1} ) \par }
  }
\cs_new_protected:Npn \__codedoc_macro_end_wrap_item:n #1
  {
    \tl_set:Nn \l__codedoc_tmpa_tl {#1}
    \tl_replace_all:Non \l__codedoc_tmpa_tl
      { \token_to_str:N _ } { \_ }
    \texttt { \l__codedoc_tmpa_tl }
  }
\cs_new_protected:Npn \__codedoc_print_end_definition:
  {
    \seq_set_map:NNn \l__codedoc_tmpa_seq
      \g__codedoc_nested_names_seq
      { \__codedoc_macro_end_wrap_item:n {##1} }
    End~ of~ definition~ for~
    \int_compare:nTF { \seq_count:N \l__codedoc_tmpa_seq <= 3 }
      {
        \seq_use:Nnnn \l__codedoc_tmpa_seq
          { \,~and~ } { \,,~ } { \,,~and~ }
      }
      { \seq_item:Nn \l__codedoc_tmpa_seq {1}\,~and~others }
    \@.
    \__codedoc_print_documented:
  }
\cs_new_protected:Npn \__codedoc_print_documented:
  {
    \seq_gset_filter:NNn \g__codedoc_nested_names_seq
      \g__codedoc_nested_names_seq
      { ! \__codedoc_if_macro_internal_p:n {##1} }
    \seq_if_empty:NF \g__codedoc_nested_names_seq
      {
        \int_set:Nn \l__codedoc_tmpa_int
          { \seq_count:N \g__codedoc_nested_names_seq }
        \int_compare:nNnTF \l__codedoc_tmpa_int = 1 {~This~} {~These~}
        \bool_if:NTF \l__codedoc_macro_var_bool {variable} {function}
        \int_compare:nNnTF \l__codedoc_tmpa_int = 1 {~is~} {s~are~}
        documented~on~page~
        \__codedoc_get_hyper_target:xN
          { \seq_item:Nn \g__codedoc_nested_names_seq { 1 } }
          \l__codedoc_tmpa_tl
        \exp_args:Nx \pageref { \l__codedoc_tmpa_tl } .
      }
    \seq_gclear:N \g__codedoc_nested_names_seq
  }
\NewDocElement[idxtype = option, idxgroup = options]{Option}{optionenv}
\font \manual = manfnt \scan_stop:
\cs_gset:Npn \dbend { {\manual\char127} }
\newenvironment {danger}
  {
    \begin{trivlist}\item[]\noindent
    \begingroup\hangindent=2pc\hangafter=-2
    \cs_set:Npn \par{\endgraf\endgroup}
    \hbox to0pt{\hskip-\hangindent\dbend\hfill}\ignorespaces
  }
  {
    \par\end{trivlist}
  }
\newenvironment {ddanger}
  {
    \begin{trivlist}\item[]\noindent
    \begingroup\hangindent=3.5pc\hangafter=-2
    \cs_set:Npn \par{\endgraf\endgroup}
    \hbox to0pt{\hskip-\hangindent\dbend\kern2pt\dbend\hfill}\ignorespaces
  }{
      \par\end{trivlist}
  }
\bool_if:NTF \g__codedoc_show_notes_bool
  {
    \NewDocumentCommand\NB{mm}
      {
        (\emph{Note}\footnote{\ttfamily [#1]:~\detokenize{#2}})
      }
  }
  {
    \NewDocumentCommand\NB{mm}{}
  }
\bool_if:NTF \g__codedoc_show_notes_bool
  {
    \NewDocumentEnvironment{NOTE}{m}
      {
        \par\noindent (\emph{Note}~[\texttt{#1}]:\par
        \verbatim
      }
      {
        \endverbatim
        \par\noindent \emph{Note~end})\par
      }
  }
  {
    \NewDocumentEnvironment{NOTE}{m}{\comment}{\endcomment}
  }
\newenvironment{TemplateInterfaceDescription}[1]
  {
    \subsection{The~object~type~`#1'}
    \begingroup
    \@beginparpenalty\@M
    \description
    \def\TemplateArgument##1##2{\item[Arg:~##1]##2\par}
    \def\TemplateSemantics
      {
        \enddescription\endgroup
        \subsubsection*{Semantics:}
      }
  }
  {
    \par\bigskip
  }
\newenvironment{TemplateDescription}[2]
  {
    \subsection{The~template~`#2'~(object~type~#1)}
    \subsubsection*{Attributes:}
    \begingroup
    \@beginparpenalty\@M
    \description
    \def\TemplateKey##1##2##3##4
      {
        \item[##1~(##2)]##3%
        \ifx\TemplateKey##4\TemplateKey\else
          \hfill\penalty500\hbox{}\hfill Default:~##4%
          \nobreak\hskip-\parfillskip\hskip0pt\relax
        \fi
        \par
      }
    \def\TemplateSemantics
      {
        \enddescription\endgroup
        \subsubsection*{Semantics~\&~Comments:}
      }
  }
  { \par \bigskip }
\newenvironment{InstanceDescription}[4][xxxxxxxxxxxxxxx]
  {
    \subsubsection{The~instance~`#3'~(template~#2/#4)}
    \subsubsection*{Attribute~values:}
    \begingroup
    \@beginparpenalty\@M
    \def\InstanceKey##1##2{\>\textbf{##1}\>##2\\}
    \def\InstanceSemantics{\endtabbing\endgroup
      \vskip-30pt\vskip0pt
      \subsubsection*{Layout~description~\&~Comments:}}
    \tabbing
    xxxx\=#1\=\kill
  }
  { \par \bigskip }
\DeclareDocumentCommand \OnlyDescription { }
  { \bool_gset_false:N \g__codedoc_typeset_implementation_bool }
\DeclareDocumentCommand \AlsoImplementation { }
  { \bool_gset_true:N \g__codedoc_typeset_implementation_bool }
\DeclareDocumentCommand \StopEventually { m }
  {
    \bool_if:NTF \g__codedoc_typeset_implementation_bool
      {
        \@bsphack
        \tl_gset:Nn \g__codedoc_finale_tl { #1 \check@checksum }
        \init@checksum
        \@esphack
      }
      { #1 \endinput }
  }
\cs_if_exist:NT \MaybeStop
   { \RenewCommandCopy \MaybeStop \StopEventually }
\DeclareDocumentCommand \Finale { }
  { \tl_use:N \g__codedoc_finale_tl }
\tl_new:N \g__codedoc_finale_tl
\cs_new_protected:Npn \__codedoc_input:n #1
  {
    \tl_gclear:N \g__codedoc_module_name_tl
    \MakePercentIgnore
    \input{#1}
    \MakePercentComment
  }
\DeclareDocumentCommand \DocInput { m }
  {
    \clist_map_inline:nn {#1}
      {
        \clist_put_right:Nn \g_docinput_clist {##1}
        \__codedoc_input:n {##1}
      }
  }
\DeclareDocumentCommand \DocInputAgain { }
  { \clist_map_function:NN \g_docinput_clist \__codedoc_input:n }
\NewDocumentCommand \DocInclude { m }
  {
    \relax\clearpage
    \docincludeaux
    \IfFileExists{#1.fdd}
      { \cs_set:Npn \currentfile{#1.fdd} }
      { \cs_set:Npn \currentfile{#1.dtx} }
    \int_compare:nNnTF \@auxout = \@partaux
      { \@latexerr{\string\include\space cannot~be~nested}\@eha }
      { \@docinclude {#1} }
  }
\cs_gset:Npn \@docinclude #1
  {
    \clearpage
    \immediate\write\@mainaux{\string\@input{#1.aux}}
    \@tempswatrue
    \if@partsw
      \@tempswafalse
      \cs_set:Npx \@tempb {#1}
      \clist_map_inline:Nn \@partlist
        {
          \if_meaning:w \@tempa \@tempb
            \@tempswatrue
          \fi:
        }
    \fi
    \if@tempswa
      \cs_set_eq:NN \@auxout                 \@partaux
      \immediate\openout\@partaux #1.aux
      \immediate\write\@partaux{\relax}
      \cs_set_eq:NN \@ltxdoc@PrintIndex      \PrintIndex
      \cs_set_eq:NN \PrintIndex              \relax
      \cs_set_eq:NN \@ltxdoc@PrintChanges    \PrintChanges
      \cs_set_eq:NN \PrintChanges            \relax
      \cs_set_eq:NN \@ltxdoc@theglossary     \theglossary
      \cs_set_eq:NN \@ltxdoc@endtheglossary  \endtheglossary
      \part{\currentfile}
      {
        \cs_set_eq:NN \ttfamily\relax
        \cs_gset:Npx \filekey
          { \filekey,~ \thepart = { \ttfamily \currentfile } }
      }
      \DocInput{\currentfile}
      \cs_set_eq:NN \PrintIndex              \@ltxdoc@PrintIndex
      \cs_set_eq:NN \PrintChanges            \@ltxdoc@PrintChanges
      \cs_set_eq:NN \theglossary             \@ltxdoc@theglossary
      \cs_set_eq:NN \endtheglossary          \@ltxdoc@endtheglossary
      \clearpage
      \@writeckpt{#1}
      \immediate \closeout \@partaux
    \else
      \@nameuse{cp@#1}
    \fi
    \cs_set_eq:NN \@auxout \@mainaux
  }
\cs_gset_protected:Npn \@wrindex #1
  {
    \protected@write \@indexfile {}
      { \string \indexentry {#1} { MMMMI - \thepage } }
    \endgroup \@esphack
  }
\cs_gset_protected:Npn \codeline@wrindex #1
  {
    \immediate\write\@indexfile
      {
        \string\indexentry{#1}
          { MMMMV - \filesep \int_use:N \c@CodelineNo }
      }
  }
\tl_gclear:N \filesep
\cs_new_protected:Npn \__codedoc_index_page_hc:nn #1#2
  {
    \protected@write \@indexfile {}
      {
        \string \indexentry { #1 \encapchar hdpindex{#2} }
          { MMMMI - \thepage }
      }
  }
\cs_new_protected:Npn \__codedoc_index_codeline_hc:nn #1#2
  {
    \immediate\write\@indexfile
      {
        \string \indexentry { #1 \encapchar hdclindex{\the\c@HD@hypercount}{#2} }
          { MMMMV - \filesep \int_use:N \c@CodelineNo - MMMD - \the\c@HD@hypercount - M }
      }
  }
\cs_gset:Npn \docincludeaux
  {
    \tl_set:Nn \thepart { \alphalph { part } }
    \tl_set:Nn \filesep { \thepart - }
    \cs_set_eq:NN \filekey \use_none:n
    \tl_gput_right:Nn \index@prologue
      {
        \cs_gset:Npn \@oddfoot
          {
            \parbox { \textwidth }
              {
                \strut \footnotesize
                \raggedright { \bfseries File~Key: } ~ \filekey
              }
          }
        \cs_set_eq:NN \@evenfoot \@oddfoot
      }
    \cs_gset_eq:NN \docincludeaux \relax
    \cs_gset:Npn \@oddfoot
      {
        \cs_if_exist:cTF { ver @ \currentfile }
          { File~\thepart :~{\ttfamily\currentfile}~ }
          {
            \GetFileInfo{\currentfile}
            File~\thepart :~{\ttfamily\filename}~
            Date:~\ExplFileDate\ % space
            Version~\ExplFileVersion
          }
        \hfill \thepage
      }
    \cs_set_eq:NN \@evenfoot \@oddfoot
  }
\group_begin:
  \char_set_catcode_other:N \^^A
  \char_set_catcode_active:N \^^S
  \char_set_catcode_active:N \^^B
  \char_set_catcode_other:N \^^L
  \char_set_catcode_other:N \^^R
  \char_set_lccode:nn { `\^^A } { `\% }
  \char_set_lccode:nn { `\^^S } { `\  }
  \char_set_lccode:nn { `\^^B } { `\\ }
  \char_set_lccode:nn { `\^^L } { `\{ }
  \char_set_lccode:nn { `\^^R } { `\} }
  \tex_lowercase:D
    {
      \group_end:
      \cs_set_protected:Npn \xmacro@code
          #1 ^^A ^^S^^S^^S^^S ^^Bend ^^Lmacrocode^^R
        { \__codedoc_xmacro_code:n {#1} \end{macrocode} }
    }
\group_begin:
  \char_set_catcode_active:N \<
  \char_set_catcode_active:N \>
  \cs_new_protected:Npn \__codedoc_xmacro_code:n #1
    {
      \tl_clear:N \l__codedoc_tmpa_tl
      \tl_if_in:nnTF {#1} { < @ @ = }
        { \__codedoc_xmacro_code:w #1 < @ @ = \q_recursion_tail > \q_recursion_stop }
        {
          \tl_set:Nn \l__codedoc_tmpa_tl {#1}
          \__codedoc_detect_internals:N \l__codedoc_tmpa_tl
          \__codedoc_replace_at_at:N \l__codedoc_tmpa_tl
          \tl_use:N \l__codedoc_tmpa_tl
        }
    }
  \cs_new_protected:Npn \__codedoc_xmacro_code:w #1 < @ @ = #2 >
    {
      % Add code before <@@=...>
      \tl_set:Nn \l__codedoc_tmpb_tl {#1}
      \__codedoc_detect_internals:N \l__codedoc_tmpb_tl
      \__codedoc_replace_at_at:N \l__codedoc_tmpb_tl
      \tl_put_right:NV \l__codedoc_tmpa_tl \l__codedoc_tmpb_tl
      % Check for \q_recursion_tail
      \quark_if_recursion_tail_stop_do:nn {#2}
        { \tl_use:N \l__codedoc_tmpa_tl }
      % Change module name and add <@@=#2> to typeset output
      \tl_gset:Nn \g__codedoc_module_name_tl {#2}
      \tl_put_right:Nn \l__codedoc_tmpa_tl { < \text { \verbatim@font @ @ = #2 } > }
      % Loop
      \__codedoc_xmacro_code:w
    }
\group_end:
\iow_new:N \g__codedoc_func_iow
\tl_new:N \l__codedoc_doc_def_tl
\tl_new:N \l__codedoc_doc_undef_tl
\tl_new:N \l__codedoc_undoc_def_tl
\cs_new_protected:Npn \__codedoc_show_functions_defined:
  {
    \bool_lazy_and:nnT
      { \g__codedoc_typeset_implementation_bool } { \g__codedoc_checkfunc_bool }
      {
        \iow_term:x { \c__codedoc_iow_separator_tl \iow_newline: }
        \iow_open:Nn \g__codedoc_func_iow { \c_sys_jobname_str .cmds }

        \tl_clear:N \l__codedoc_doc_def_tl
        \tl_clear:N \l__codedoc_doc_undef_tl
        \tl_clear:N \l__codedoc_undoc_def_tl
        \seq_map_inline:Nn \g_doc_functions_seq
          {
            \seq_if_in:NnTF \g_doc_macros_seq {##1}
              {
                \tl_put_right:Nx \l__codedoc_doc_def_tl
                  { ##1 \iow_newline: }
                \iow_now:Nn \g__codedoc_func_iow { > ~ ##1 }
              }
              {
                \tl_put_right:Nx \l__codedoc_doc_undef_tl
                  { ##1 \iow_newline: }
                \iow_now:Nn \g__codedoc_func_iow { ! ~ ##1 }
              }
          }
        \seq_map_inline:Nn \g_doc_macros_seq
          {
            \seq_if_in:NnF \g_doc_functions_seq {##1}
              {
                \tl_put_right:Nx \l__codedoc_undoc_def_tl
                  { ##1 \iow_newline: }
                \iow_now:Nn \g__codedoc_func_iow { ? ~ ##1 }
              }
          }
        \__codedoc_functions_typeout:nN
          {
            Functions~both~documented~and~defined: \iow_newline:
            (In~order~of~being~documented)
          }
          \l__codedoc_doc_def_tl
        \__codedoc_functions_typeout:nN
          { Functions~documented~but~not~defined: }
          \l__codedoc_doc_undef_tl
        \__codedoc_functions_typeout:nN
          { Functions~defined~but~not~documented: }
          \l__codedoc_undoc_def_tl

        \iow_close:N \g__codedoc_func_iow
        \iow_term:x { \c__codedoc_iow_separator_tl }
      }
  }
\AtEndDocument { \__codedoc_show_functions_defined: }
\cs_new_protected:Npn \__codedoc_functions_typeout:nN #1#2
  {
    \tl_if_empty:NF #2
      {
        \typeout
          {
            \c__codedoc_iow_midrule_tl \iow_newline:
            #1 \iow_newline:
            \c__codedoc_iow_midrule_tl \iow_newline:
            #2
          }
        \tl_clear:N #2
      }
  }
\cs_new_protected:Npn \__codedoc_show_not_tested:
  {
    \bool_if:NT \g__codedoc_checktest_bool
      {
        \tl_clear:N \l__codedoc_tmpa_tl
        \prop_if_empty:NF \g__codedoc_missing_tests_prop
          {
            \cs_set:Npn \__codedoc_tmpa:w ##1##2
              {
                \iow_newline:
                \space\space\space\space \exp_not:n {##1}
                \clist_map_function:nN {##2} \__codedoc_tmpb:w
              }
            \cs_set:Npn \__codedoc_tmpb:w ##1
              {
                \iow_newline:
                \space\space\space\space\space\space * ~ ##1
              }
            \tl_put_right:Nx \l__codedoc_tmpa_tl
              {
                \iow_newline: \iow_newline:
                The~ following~ macro(s)~ have~ incomplete~ tests:
                \iow_newline:
                \prop_map_function:NN
                  \g__codedoc_missing_tests_prop \__codedoc_tmpa:w
              }
          }
        \seq_if_empty:NF \g__codedoc_not_tested_seq
          {
            \cs_set:Npn \__codedoc_tmpa:w ##1
              { \clist_map_function:nN {##1} \__codedoc_tmpb:w }
            \cs_set:Npn \__codedoc_tmpb:w ##1
              {
                \iow_newline:
                \space\space\space\space ##1
              }
            \tl_put_right:Nx \l__codedoc_tmpa_tl
              {
                \iow_newline:
                \iow_newline:
                The~ following~ macro(s)~ do~ not~ have~ any~ tests:
                \iow_newline:
                \seq_map_function:NN
                  \g__codedoc_not_tested_seq \__codedoc_tmpa:w
              }
          }
        \tl_if_empty:NF \l__codedoc_tmpa_tl
          {
            \int_set:Nn \l__codedoc_tmpa_int { \tex_interactionmode:D }
            \errorstopmode
            \ClassError { l3doc } { \l__codedoc_tmpa_tl } { }
            \int_set:Nn \tex_interactionmode:D { \l__codedoc_tmpa_int }
          }
      }
  }
\AtEndDocument { \__codedoc_show_not_tested: }
\cs_new_protected:Npn \__codedoc_target:
  {
    \mode_leave_vertical:
    \group_begin:
      \HD@savedestfalse \HD@target
    \group_end:
  }
\cs_set_nopar:Npx \theCodelineNo
  {
    \group_begin:
      \exp_not:N \HD@savedestfalse
      \exp_not:o \theCodelineNo
    \group_end:
  }
\bool_new:N \l__codedoc_allow_indexing_bool
\bool_set_true:N \l__codedoc_allow_indexing_bool
\use:x
  {
    \exp_not:n { \cs_set_nopar:Npn \@starttoc #1 }
      {
        \group_begin:
          \bool_set_false:N \l__codedoc_allow_indexing_bool
          \exp_not:o { \@starttoc {#1} }
        \group_end:
      }
  }
\g@addto@macro \theindex { \MakePrivateLetters }
\cs_gset:Npn \verbatimchar {&}
\setcounter { IndexColumns } { 2 }
\IndexPrologue
  {
    \part*{Index}
    \markboth{Index}{Index}
    \addcontentsline{toc}{part}{Index}
    The~italic~numbers~denote~the~pages~where~the~
    corresponding~entry~is~described,~
    numbers~underlined~point~to~the~definition,~
    all~others~indicate~the~places~where~it~is~used.
  }
\cs_gset_protected:Npn \SpecialIndex #1
  {
    \@bsphack
    \__codedoc_special_index:nn {#1} { }
    \@esphack
  }
\msg_new:nnn { l3doc } { print-index-howto }
  {
    Generate~the~index~by~executing\\
    \iow_indent:n
      { makeindex~-s~gind.ist~-o~\c_sys_jobname_str.ind~\c_sys_jobname_str.idx }
  }
\tl_gput_right:Nn \PrintIndex
  { \AtEndDocument { \msg_info:nn { l3doc } { print-index-howto } } }
\cs_gset_protected:Npn \it@is@a #1
  {
    \use:x
      {
        \__codedoc_special_index_module:nnnnN
          {#1}
          { \bslash #1 }
          { }
          { }
          \c_false_bool
      }
  }
\cs_new_protected:Npn \__codedoc_special_index:nn #1#2
  {
    \__codedoc_key_get:n {#1}
    \quark_if_no_value:NF \l__codedoc_override_module_tl
      { \tl_set_eq:NN \l__codedoc_index_module_tl \l__codedoc_override_module_tl }
    \__codedoc_special_index_module:ooonN
      { \l__codedoc_index_key_tl }
      { \l__codedoc_index_macro_tl }
      { \l__codedoc_index_module_tl }
      {#2}
      \l__codedoc_index_internal_bool
  }
\cs_generate_variant:Nn \__codedoc_special_index:nn { o }
\tl_new:N \l__codedoc_index_escaped_macro_tl
\tl_new:N \l__codedoc_index_escaped_key_tl
\cs_new_protected:Npn \__codedoc_special_index_module:nnnnN #1#2#3#4#5
  {
    \use:x
      {
        \exp_not:n { \__codedoc_special_index_aux:nnnnnn {#1} {#2} }
          \tl_if_empty:nTF {#3}
            { { } { } { } }
            {
              \str_if_eq:nnTF {#3} { TeX }
                {
                  { TeX~and~LaTeX2e }
                  { \string\TeX{}~and~\string\LaTeXe{} }
                }
                {
                  {#3}
                  { \string\pkg{#3} }
                }
              { \bool_if:NT #5 { ~internal } ~commands: }
            }
      }
          {#4}
  }
\cs_generate_variant:Nn \__codedoc_special_index_module:nnnnN { ooo }
\cs_new_protected:Npn \__codedoc_special_index_aux:nnnnnn #1#2#3#4#5#6
  {
    \tl_set:Nn \l__codedoc_index_escaped_key_tl {#1}
    \__codedoc_quote_special_char:N \l__codedoc_index_escaped_key_tl
    \__codedoc_special_index_set:Nn \l__codedoc_index_escaped_macro_tl {#2}
    \str_if_eq:onTF { \@currenvir } { macrocode }
      { \__codedoc_index_codeline_hc:nn }
      {
        \str_case:nnF {#6}
          {
            { main }  { \__codedoc_index_codeline_hc:nn }
            { usage } { \__codedoc_index_page_hc:nn }
          }
          { \__codedoc_target: \__codedoc_index_page_hc:nn }
      }
      {
        \tl_if_empty:nF { #3 #4 #5 }
          { #3 #5 \actualchar #4 #5 \levelchar }
        \l__codedoc_index_escaped_key_tl
        \actualchar
        {
          \token_to_str:N \verbatim@font \c_space_tl
          \l__codedoc_index_escaped_macro_tl
        }
      }
      {#6}
  }
\group_begin:
\char_set_active_eq:NN - \scan_stop:
\tl_const:Nx \c__codedoc_active_minus_tl { \char_generate:nn { `- } { 13 } }
\group_end:
\cs_new_eq:NN \__codedoc_old_hdpindex:nn \hdpindex
\cs_new_eq:NN \__codedoc_old_hdclindex:nnn \hdclindex
\cs_gset_protected:Npn \hdpindex #1
  { \__codedoc_hdindex:nn { \__codedoc_old_hdpindex:nn {#1} } }
\cs_gset_protected:Npn \hdclindex #1#2
  { \__codedoc_hdindex:nn { \__codedoc_old_hdclindex:nnn {#1} {#2} } }
\cs_new_protected:Npn \__codedoc_hdindex:nn #1#2
  {
    \tl_set:Nn \l__codedoc_tmpa_tl {#2}
    \tl_replace_all:Nxn \l__codedoc_tmpa_tl
      { \exp_not:V \c__codedoc_active_minus_tl \exp_not:V \c__codedoc_active_minus_tl }
      { -- }
    \seq_set_split:NnV \l__codedoc_tmpa_seq { -- } \l__codedoc_tmpa_tl
    \seq_set_map:NNn \l__codedoc_tmpa_seq \l__codedoc_tmpa_seq
      { \__codedoc_hdindex_aux:nn {#1} {##1} }
    \seq_use:Nn \l__codedoc_tmpa_seq { -- }
  }
\cs_new_protected:Npn \__codedoc_hdindex_aux:nn #1#2
  {
    \tl_set:Nn \l__codedoc_tmpa_tl {#2}
    \tl_replace_all:Nnn \l__codedoc_tmpa_tl { MMMM } { \use_none:nn }
    \tl_if_in:NnT \l__codedoc_tmpa_tl { MMMD }
      {
        \tl_replace_all:Nxn \l__codedoc_tmpa_tl
          { \exp_not:V \c__codedoc_active_minus_tl MMMD } { - MMMD }
        \tl_replace_all:Nnn \l__codedoc_tmpa_tl { - MMMD } { \__codedoc_hdindex_aux:w }
      }
    \use:x { \exp_not:n {#1} { \exp_not:V \l__codedoc_tmpa_tl } }
  }
\cs_new_protected:Npn \__codedoc_hdindex_aux:w #1 M { }
\cs_new_protected:Npn \__codedoc_special_index_set:Nn #1#2
  {
    \__kernel_tl_set:Nx #1 { \tl_to_str:n {#2} }
    \__codedoc_if_almost_str:nTF {#2}
      {
        \tl_replace_all:Non #1 { \tl_to_str:n { __ } }
          {
            \verbatimchar
            \token_to_str:N \_ \token_to_str:N \_
            \token_to_str:N \verb * \verbatimchar
          }
        \exp_args:Nx \tl_map_inline:nn
          { \tl_to_str:N \verbatimchar \token_to_str:N _ }
          {
            \tl_replace_all:Nnn #1 {##1}
              {
                \verbatimchar \c_backslash_str ##1
                \token_to_str:N \verb * \verbatimchar
              }
          }
        \__kernel_tl_set:Nx #1
          {
            \token_to_str:N \verb * \verbatimchar
            #1 \verbatimchar
          }
      }
      {
        \tl_set:Nn #1 {#2}
        \tl_replace_all:Non #1
          { \c_backslash_str }
          { \token_to_str:N \bslash \c_space_tl }
      }
    \__codedoc_quote_special_char:N #1
  }
\cs_new_protected:Npn \__codedoc_quote_special_char:N #1
  {
    \tl_map_inline:nn { \quotechar \actualchar \encapchar \levelchar \bslash }
      {
        \tl_replace_all:Nxn #1
          { \tl_to_str:N ##1 } { \quotechar \tl_to_str:N ##1 }
      }
  }
\cs_new_protected:Npn \__codedoc_key_get:n #1
  {
    \__codedoc_key_get_base:nN {#1} \l__codedoc_index_macro_tl
    \__kernel_tl_set:Nx \l__codedoc_index_key_tl
      { \tl_to_str:N \l__codedoc_index_macro_tl }
    \tl_clear:N \l__codedoc_index_module_tl
    \tl_if_in:NoTF \l__codedoc_index_key_tl { \tl_to_str:n { __ } }
      { \bool_set_true:N \l__codedoc_index_internal_bool }
      { \bool_set_false:N \l__codedoc_index_internal_bool }
    \exp_last_unbraced:NNo
    \tl_if_head_eq_charcode:oNT
      { \l__codedoc_index_key_tl } \c_backslash_str
      { \__codedoc_key_pop: }
    \tl_if_in:NoTF \l__codedoc_index_key_tl { \token_to_str:N : }
      { \__codedoc_key_func: }
      {
        \tl_if_in:NoTF \l__codedoc_index_key_tl { \token_to_str:N _ }
          { \__codedoc_key_var: }
          {
            \tl_if_in:NoT \l__codedoc_index_key_tl { \token_to_str:N @ }
              { \tl_set:Nn \l__codedoc_index_module_tl { TeX } }
          }
      }
  }
\cs_new_protected:Npn \__codedoc_key_pop:
  {
    \__kernel_tl_set:Nx \l__codedoc_index_key_tl
      { \tl_tail:N \l__codedoc_index_key_tl }
  }
\cs_new_protected:Npn \__codedoc_key_trim_module:n #1
  {
    \cs_set:Npn \__codedoc_tmpa:w ##1 #1 ##2 \q_stop
      { \exp_not:n {##1} }
    \__kernel_tl_set:Nx \l__codedoc_index_module_tl
      { \exp_after:wN \__codedoc_tmpa:w \l__codedoc_index_module_tl #1 \q_stop }
  }
\cs_new_protected:Npn \__codedoc_key_drop_underscores:
  {
    \tl_if_head_eq_charcode:oNT { \l__codedoc_index_key_tl } _
      { \__codedoc_key_pop: \__codedoc_key_drop_underscores: }
  }
\cs_new_protected:Npn \__codedoc_key_func:
  {
    \tl_if_head_eq_charcode:oNT { \l__codedoc_index_key_tl } .
      { \__codedoc_key_pop: }
    \__codedoc_key_drop_underscores:
    \tl_set_eq:NN \l__codedoc_index_module_tl \l__codedoc_index_key_tl
    \exp_args:No \__codedoc_key_trim_module:n { \token_to_str:N : }
    \exp_args:No \__codedoc_key_trim_module:n { \token_to_str:N _ }
  }
\cs_new_protected:Npn \__codedoc_key_var:
  {
    \exp_args:Nx \tl_if_head_eq_charcode:nNTF
      { \exp_args:No \str_tail:n \l__codedoc_index_key_tl } _
      {
        \str_case:fn { \str_head:N \l__codedoc_index_key_tl }
          {
            { q } { \tl_set:Nn \l__codedoc_index_module_tl { quark } }
            { s } { \tl_set:Nn \l__codedoc_index_module_tl { scan } }
          }
        \__codedoc_key_pop:
        \__codedoc_key_pop:
        \__codedoc_key_drop_underscores:
        \tl_if_empty:NT \l__codedoc_index_module_tl
          {
            \seq_set_split:NoV \l__codedoc_tmpa_seq
              { \token_to_str:N _ } \l__codedoc_index_key_tl
            \seq_get_left:NN \l__codedoc_tmpa_seq \l__codedoc_index_module_tl
            \clist_if_in:NoT \g__codedoc_non_modules_clist \l__codedoc_index_module_tl
              {
                \seq_get_right:NN \l__codedoc_tmpa_seq \l__codedoc_index_module_tl
                \clist_if_in:NoT \g__codedoc_non_modules_clist \l__codedoc_index_module_tl
                  {
                    \tl_clear:N \l__codedoc_index_module_tl
                  }
              }
          }
      }
      {
        \tl_set_eq:NN \l__codedoc_index_module_tl \l__codedoc_index_key_tl
        \exp_args:No \__codedoc_key_trim_module:n { \token_to_str:N _ }
      }
  }
\clist_new:N \g__codedoc_non_modules_clist
\clist_gset:Nx \g__codedoc_non_modules_clist
  {
    \tl_to_str:n
      {

        alignment, ampersand, atsign, backslash, catcode, circumflex,
        code, colon, document, dollar, e, empty, false, hash, inf,
        initex, job, left, log, math, mark, max, minus, nan, nil, no,
        novalue, other, parameter, percent, pi, recursion, right, space,
        stop, term, tilde, tmpa, tmpb, true, underscore, zero, one, two,
        three, four, five, six, seven, eight, nine, ten, eleven, twelve,
        thirteen, fourteen, fifteen, sixteen, thirty, hundred

      }
  }
\GlossaryPrologue
  {
    \part*{Change~History}
    {\GlossaryParms\ttfamily\hyphenchar\font=`\-}
    \markboth{Change~History}{Change~History}
    \addcontentsline{toc}{part}{Change~History}
  }
\msg_new:nnn { l3doc } { print-changes-howto }
  {
    Generate~the~change~list~by~executing\\
    \iow_indent:n
      { makeindex~-s~gglo.ist~-o~\c_sys_jobname_str.gls~\c_sys_jobname_str.glo }
  }
\tl_gput_right:Nn \PrintChanges
  { \AtEndDocument { \msg_info:nn { l3doc } { print-changes-howto } } }
\bool_if:NTF \g__codedoc_typeset_implementation_bool
  {
    \RecordChanges
    \CodelineIndex
    \EnableCrossrefs
    \AlsoImplementation
  }
  {
    \CodelineNumbered
    \DisableCrossrefs
    \OnlyDescription
  }
%% 
%%
%% End of file `l3doc.cls'.
