" AutoClose, closes what's opened.
"
"  Karl Guertin <grayrest@gr.ayre.st>
"  1.0.1 released April 3, 2007
"
"    This plugin closes opened parenthesis, braces, brackets, quotes as you
"    type them.
"
"    You can enable or disable this plugin by typing \a (or <Leader>a if
"    you've redefined your leader character) in normal mode. You'll also
"    probably want to know you can type <C-V> (<C-Q> if mswin is set) and the next
"    character you type doesn't have mappings applied. This is useful when you
"    want to insert only an opening paren or something.
"
"    Version Changes:
"    1.0.1 -- Cruft from other parts of the mapping, knew I shouldn't have
"             released the first as 1.0

" Setup -----------------------------------------------------{{{1
if exists('g:autoclose_loaded') || &cp
    finish
endif

let g:autoclose_loaded = 1
let s:omni_active = 0
let s:cotstate = &completeopt

if !exists('g:autoclose_on')
    let g:autoclose_on = 1
endif

" (Toggle) Mappings -----------------------------{{{1
"
nmap <Plug>ToggleAutoCloseMappings :call <SID>ToggleAutoCloseMappings()<CR>
if ( !hasmapto( '<Plug>ToggleAutoCloseMappings', 'n' ))
    nmap <unique> <Leader>a <Plug>ToggleAutoCloseMappings
endif
fun <SID>ToggleAutoCloseMappings() " --- {{{2
    if g:autoclose_on
        iunmap "
        iunmap '
        iunmap (
        iunmap )
        iunmap [
        iunmap ]
        iunmap {
        iunmap }
        iunmap <BS>
        iunmap <Esc>
        ""iunmap <C-[>
        let g:autoclose_on = 0
        echo "AutoClose Off"
    else
        inoremap <silent> " <C-R>=<SID>QuoteDelim('"')<CR>
        inoremap <silent> ' <C-R>=match(getline('.')[col('.') - 2],'\w') == 0 && getline('.')[col('.')-1] != "'" ? "'" : <SID>QuoteDelim("'")<CR>
        inoremap <silent> ( (<C-R>=<SID>CloseStackPush(')')<CR>
        inoremap <silent> ) <C-R>=<SID>CloseStackPop(')')<CR>
        inoremap <silent> [ [<C-R>=<SID>CloseStackPush(']')<CR>
        inoremap <silent> ] <C-R>=<SID>CloseStackPop(']')<CR>
        inoremap <silent> { {<C-R>=<SID>CloseStackPush('}')<CR>
        inoremap <silent> } <C-R>=<SID>CloseStackPop('}')<CR>
        inoremap <silent> <BS> <C-R>=<SID>OpenCloseBackspace()<CR>
        inoremap <silent> <Esc> <C-R>=<SID>CloseStackPop('')<CR><Esc>
        inoremap <silent> <C-[> <C-R>=<SID>CloseStackPop('')<CR><C-[>
        let g:autoclose_on = 1
        if a:0 == 0
            "this if is so this message doesn't show up at load
            echo "AutoClose On"
        endif
    endif
endf
let s:closeStack = []

" AutoClose Utilities -----------------------------------------{{{1
function <SID>CloseStackPush(char) " ---{{{2
    echom "push"
    let line = getline('.')
    let col = col('.')-2
    echom string(col).':'.line[:(col)].'|'.line[(col+1):]
    call setline('.',line[:(col)].a:char.line[(col+1):])
    call insert(s:closeStack, a:char)
    echom join(s:closeStack,'').' -- '.a:char
    return ''
endf

function <SID>CloseStackPop(char) " ---{{{2
    echom "pop"
    if len(s:closeStack) == 0
        return a:char
    endif
    let popped = ''
    let lastpop = ''
    echom join(s:closeStack,'').' || '.lastpop
    while len(s:closeStack) > 0 && ((lastpop == '' && popped == '') || lastpop != a:char)
        let lastpop = remove(s:closeStack,0)
        let popped .= lastpop
        echom join(s:closeStack,'').' || '.lastpop.' || '.popped
    endwhile
    echom ' --> '.popped
    let splits = split(getline('.'),popped,1)
    call setline('.',join(splits[:-2],popped).splits[-1])
    return popped
endf

function <SID>QuoteDelim(char) " ---{{{2
  let line = getline('.')
  let col = col('.')
  if line[col - 2] == "\\"
    "Inserting a quoted quotation mark into the string
    return a:char
  elseif line[col - 1] == a:char
    "Escaping out of the string
    return "\<C-R>=".s:SID()."CloseStackPop(\"\\".a:char."\")\<CR>"
  else
    "Starting a string
    return a:char."\<C-R>=".s:SID()."CloseStackPush(\"\\".a:char."\")\<CR>"
  endif
endf

" The strings returned from QuoteDelim aren't in scope for <SID>, so I
" have to fake it using this function (from the Vim help, but tweaked)
function s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSID$')
endfun

function <SID>OpenCloseBackspace() " ---{{{2
    "if pumvisible()
    "    pclose
    "    call <SID>StopOmni()
    "    return "\<C-E>"
    "else
        let curline = getline('.')
        let curpos = col('.')
        let curletter = curline[curpos-1]
        let prevletter = curline[curpos-2]
        if (prevletter == '"' && curletter == '"') ||
\          (prevletter == "'" && curletter == "'") ||
\          (prevletter == "(" && curletter == ")") ||
\          (prevletter == "{" && curletter == "}") ||
\          (prevletter == "[" && curletter == "]")
            call remove(s:closeStack,0)
            return "\<Delete>\<BS>"
        else
            return "\<BS>"
        endif
    "endif
endf

" Initialization ----------------------------------------{{{1
if g:autoclose_on
    let g:autoclose_on = 0
    silent call <SID>ToggleAutoCloseMappings()
endif
