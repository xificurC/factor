! Copyright (C) 2007 Chris Double.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel parser words arrays strings math.parser sequences quotations vectors namespaces peg ;
IN: peg.ebnf

TUPLE: ebnf-non-terminal symbol ;
TUPLE: ebnf-terminal symbol ;
TUPLE: ebnf-choice options ;
TUPLE: ebnf-sequence elements ;
TUPLE: ebnf-repeat0 group ;
TUPLE: ebnf-optional elements ;
TUPLE: ebnf-rule symbol elements ;
TUPLE: ebnf-action word ;
TUPLE: ebnf rules ;

C: <ebnf-non-terminal> ebnf-non-terminal
C: <ebnf-terminal> ebnf-terminal
C: <ebnf-choice> ebnf-choice
C: <ebnf-sequence> ebnf-sequence
C: <ebnf-repeat0> ebnf-repeat0
C: <ebnf-optional> ebnf-optional
C: <ebnf-rule> ebnf-rule
C: <ebnf-action> ebnf-action
C: <ebnf> ebnf

GENERIC: ebnf-compile ( ast -- quot )

M: ebnf-terminal ebnf-compile ( ast -- quot )
  [
    ebnf-terminal-symbol , \ token ,
  ] [ ] make ;

M: ebnf-non-terminal ebnf-compile ( ast -- quot )
  [
    [ ebnf-non-terminal-symbol , \ search , \ execute , ] [ ] make 
    , \ delay ,
  ] [ ] make ;

M: ebnf-choice ebnf-compile ( ast -- quot )
  [
    [
      ebnf-choice-options [
        ebnf-compile ,
      ] each
    ] { } make ,
    [ call ] , \ map , \ choice , 
  ] [ ] make ;

M: ebnf-sequence ebnf-compile ( ast -- quot )
  [
    [
      ebnf-sequence-elements [
        ebnf-compile ,
      ] each
    ] { } make ,
    [ call ] , \ map , \ seq , 
  ] [ ] make ;

M: ebnf-repeat0 ebnf-compile ( ast -- quot )
  [
    ebnf-repeat0-group ebnf-compile % \ repeat0 , 
  ] [ ] make ;

M: ebnf-optional ebnf-compile ( ast -- quot )
  [
    ebnf-optional-elements ebnf-compile % \ optional , 
  ] [ ] make ;

M: ebnf-rule ebnf-compile ( ast -- quot )
  [
    dup ebnf-rule-symbol , \ in , \ get , \ create , 
    ebnf-rule-elements ebnf-compile , \ define-compound , 
  ] [ ] make ;

M: ebnf-action ebnf-compile ( ast -- quot )
  [
    ebnf-action-word search 1quotation , \ action , 
  ] [ ] make ;

M: vector ebnf-compile ( ast -- quot )
  [
    [ ebnf-compile % ] each 
  ] [ ] make ;

M: f ebnf-compile ( ast -- quot )
  drop [ ] ;

M: ebnf ebnf-compile ( ast -- quot )
  [
    ebnf-rules [
      ebnf-compile %
    ] each 
  ] [ ] make ;

DEFER: 'rhs'

: 'non-terminal' ( -- parser )
  CHAR: a CHAR: z range repeat1 [ >string <ebnf-non-terminal> ] action ;

: 'terminal' ( -- parser )
  "'" token hide [ CHAR: ' = not ] satisfy repeat1 "'" token hide 3array seq [ first >string <ebnf-terminal> ] action ;

: 'element' ( -- parser )
  'non-terminal' 'terminal' 2array choice ;

DEFER: 'choice'

: 'group' ( -- parser )
  "(" token sp hide
  [ 'choice' sp ] delay
  ")" token sp hide 
  3array seq [ first ] action ;

: 'repeat0' ( -- parser )
  "{" token sp hide
  [ 'choice' sp ] delay
  "}" token sp hide 
  3array seq [ first <ebnf-repeat0> ] action ;

: 'optional' ( -- parser )
  "[" token sp hide
  [ 'choice' sp ] delay
  "]" token sp hide 
  3array seq [ first <ebnf-optional> ] action ;

: 'sequence' ( -- parser )
  'element' sp 'group' sp 'repeat0' sp 'optional' sp 4array choice 
   repeat1 [ 
     dup length 1 = [ first ] [ <ebnf-sequence> ] if
   ] action ;  

: 'choice' ( -- parser )
  'sequence' sp "|" token sp list-of [ 
    dup length 1 = [ first ] [ <ebnf-choice> ] if
   ] action ;
  
: 'action' ( -- parser )
  "=>" token hide
  [ blank? ] satisfy ensure-not [ drop t ] satisfy 2array seq [ first ] action repeat1 [ >string ] action sp
  2array seq [ first <ebnf-action> ] action ;

: 'rhs' ( -- parser )
  'choice' 'action' sp optional 2array seq ;
 
: 'rule' ( -- parser )
  'non-terminal' [ ebnf-non-terminal-symbol ] action 
  "=" token sp hide 
  'rhs' 
  3array seq [ first2 <ebnf-rule> ] action ;

: 'ebnf' ( -- parser )
  'rule' sp "." token sp hide list-of [ <ebnf> ] action ;

: ebnf>quot ( string -- quot )
  'ebnf' parse [
     parse-result-ast ebnf-compile  
   ] [
    f
   ] if* ;

: <EBNF "EBNF>" parse-tokens " " join ebnf>quot call ; parsing