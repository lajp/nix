" Vim syntax file
" Language: stlcpp
" Maintainer: Gemini CLI
" Latest Revision: 2023-12-11

" 1. Keywords
syn keyword stlcppImport import
syn keyword stlcppControl fun let in if then else lcase case of fix panic trace return fst snd inl inr cons nil
syn keyword stlcppDecl infix infixl infixr

" Types
syn keyword stlcppType Integer Int Boolean Bool Character Char List Type
syn keyword stlcppTypeModifier forall

" Constants
syn keyword stlcppBoolean true false

" 2. Matches

" Variables
" Type variables (start with uppercase)
syn match stlcppTypeVar "\<[A-Z][a-zA-Z0-9_]*\>"
" Term variables (start with lowercase)
syn match stlcppVariable "\<[a-z][a-zA-Z0-9_.]*\>"

" Numbers
syn match stlcppNumber "\<\d\+\>"

" Declaration Names
" Matches 'name :' or 'name =' at start of line
syn match stlcppDeclName /^\zs[a-z][a-zA-Z0-9_.]*\ze\s*:/ 
syn match stlcppDeclName /^\zs[a-z][a-zA-Z0-9_.]*\ze\s*=/ 

" Operators
" ->, =>, ::, :, =, +, -, *, /, ==, !=, <=, >=, <, >, $
" Using / as delimiter, so / is escaped as \/
" * and $ are escaped as \* and \$ because they are regex metacharacters
" + and - are literals in magic mode (default), so no escape needed
syn match stlcppOperator /->\|=>\|::\|:|=\|+\|-\|*\|\/\|==\|!=|<=\|>=\|<\|>\|$/

" Punctuation
syn match stlcppPunctuation /[\(\)\[\]\{\},|]/

" Strings and Characters
syn match stlcppEscape /\\u{[0-9a-fA-F]\+}\|\\./ contained
syn region stlcppString  start=/"/  end=/"/  contains=stlcppEscape keepend
syn region stlcppChar    start=/'/  end=/'/  contains=stlcppEscape keepend

" 3. Comments (Defined last to take precedence if needed)
syn keyword stlcppTodo TODO FIXME XXX contained
syn region stlcppComment start="//" end="$" contains=stlcppTodo

" Highlight linking
hi def link stlcppComment     Comment
hi def link stlcppString      String
hi def link stlcppChar        Character
hi def link stlcppEscape      SpecialChar
hi def link stlcppTodo        Todo

hi def link stlcppImport      Include
hi def link stlcppControl     Keyword
hi def link stlcppDecl        Keyword

hi def link stlcppType        Type
hi def link stlcppTypeModifier StorageClass

hi def link stlcppBoolean     Boolean
hi def link stlcppNumber      Number

hi def link stlcppOperator    Operator

hi def link stlcppTypeVar     Type
hi def link stlcppVariable    Identifier
hi def link stlcppDeclName    Function

hi def link stlcppPunctuation Delimiter

syn sync fromstart
