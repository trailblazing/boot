" vim: set foldmethod=marker:
"
" Copyright (c) 2021, Tuo Jung
" All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" 1. Redistributions of source code must retain the above copyright notice, this
"    list of conditions and the following disclaimer.
" 2. Redistributions in binary form must reproduce the above copyright notice,
"    this list of conditions and the following disclaimer in the documentation
"    and/or other materials provided with the distribution.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
" ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
" WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
" DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
" ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
" (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
" LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
" ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
" (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
" SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


if exists('g:boot_loaded')
    finish
endif

let g:boot_loaded = 1

if ! exists('g:log_address')
    let g:log_address   = $HOME . '/.vim.log'
endif
if ! exists("g:log_verbose")
    let g:log_verbose = 0
endif
if ! exists("g:fixed_tips_width")
    let g:fixed_tips_width = 40
endif

if ! exists("g:_boot_debug")
    let s:_boot_debug  = 0
else
    let s:_boot_debug = g:_boot_debug
endif

" https://vi.stackexchange.com/questions/2867/how-do-you-chomp-a-string-in-vim
function! boot#chomp(string)
    return substitute(a:string, '\n\+$', '', '')
endfunction

function! boot#chomped_system( ... )
    return substitute(call('system', a:000), '\n\+$', '', '')
endfunction

" https://vi.stackexchange.com/questions/5501/is-there-a-way-to-get-the-name-of-the-current-function-in-vim-script
function! boot#function_name(sid, sfile)
    " return substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
    " return substitute(a:file, '.*\(\.\.\|\s\)', '', '')

    let name   = substitute(a:sfile, '.*\(\.\.\|\s\)', '', '')
    let num    = matchstr(a:sid, '<SNR>\zs\d\+\ze_')
    let index  = stridx(name, num)
    let result = name[index + strlen(num) + 1 : strlen(name) - 1]
    return result
endfunction
" let function_name = boot#function_name(expand('<sfile>'))

function! boot#function(fname) abort
    if ! exists("s:SNR")
        let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zefunction$')
    endif
    return function(s:SNR.a:fname)
endfunction

" https://stackoverflow.com/questions/40254993/how-to-unload-a-vim-script-after-sourcing-it-and-making-changes-to-it/40257268#
function! boot#get_snr(...) abort
    " needed to assure compatibility with old vim versions
    if !exists("s:SNR")
        let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
    endif
    return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

" https://vi.stackexchange.com/questions/1942/how-to-execute-shell-commands-silently
function! boot#silent_exec(cmd)
    let cmd = substitute(a:cmd, '^!', '', '')
    let cmd = substitute(cmd, '%', shellescape(expand('%')), '')
    call system(cmd)
endfunction

command! -nargs=1 Silent call boot#silent_exec(<q-args>)

" https://vi.stackexchange.com/questions/1942/how-to-execute-shell-commands-silently
fun! boot#praeceptum_tacet(cmd)
    silent let f = systemlist(a:cmd)
    if v:shell_error
        echohl Error
        echom "ERROR #" . v:shell_error
        echohl WarningMsg
        for e in f
            echom e
        endfor
        echohl None
    endif
endfun

command! -nargs=+ PT call boot#praeceptum_tacet(<q-args>)

" https://stackoverflow.com/questions/24027506/get-a-vim-scripts-snr
" call eval(printf("<SNR>%d_some_function_in_corresponding_script()", boot#script_number("some_script.vim")))
func! boot#script_number(script_name)
    " Return the <SNR> of a script.
    "
    " Args:
    "   script_name : (str) The name of a sourced script.
    "
    " Return:
    "   (int) The <SNR> of the script; if the script isn't found, -1.

    redir => scriptnames
    silent! scriptnames
    redir END

    for script in split(l:scriptnames, "\n")
        if l:script =~ a:script_name
            return str2nr(split(l:script, ":")[0])
        endif
    endfor

    return -1
endfunc



if ! exists('g:log_verbose')
    let g:log_verbose = 1
endif

" " Demonstration of the plugin directory settings of vim
" if ! exists("g:vimrc_dir")
"
"     " let vimrc_file = boot#chomped_system("sudo realpath $MYVIMRC")
"     let vimrc_file = boot#chomped_system("realpath $MYVIMRC")
"     " call boot#chomped_system("printf \"\nvimrc_file\t\t: \"" . vimrc_file . " >> " . a:log_address)
"
"     " let vimrc_base = boot#chomped_system("basename \"". vimrc_file . "\"")
"
"     let g:vimrc_dir  = boot#chomped_system("dirname \"". vimrc_file ."\" | cat - | xargs realpath")
"     " let g:vimrc_dir  = substitute(vimrc_file, "\/".vimrc_base, '', 'g')
"     " echom 'g:vimrc_dir  =' . g:vimrc_dir
"     silent! execute '!(printf "g:vimrc_dir\t\t: ' . g:vimrc_dir .'")' . ' >> ' . a:log_address . ' 2>&1 &'
"
"     let g:plugin_dir = expand(g:vimrc_dir, 1) . '/.vim'
"
" endif


" We do not handle a file truncation in this method
" Just redir and echo to a fixed log file, g:log_address
function! boot#log_silent(log_address, tips, value, fix_tips_width, log_verbose)

    " hard to understand, gave up
    " if (0 < a:0)
    "     let value = "\"" . a:1 . "\""
    " else
    "     let value = ""
    " endif

    " if (1 < a:0)
    "     let truncate_method = a:2
    "     if truncate_method == "\"" . '>' . "\""
    "         let truncate_method = '>'
    "     endif
    " else
    "     let truncate_method = ">>"
    " endif

    let truncate_method = ">>"

    " deal with "\n" and '\n'
    let header = ""
    let left_hand_value = a:tips

    " let left_hand_value = substitute(a:tips, '!', '\\!', '')
    " let find_quote = stridx(left_hand_value, "\"")
    " if -1 != find_quote
    "     echom "logsilent has double quote:" . left_hand_value
    " endif
    " let left_hand_value = substitute(left_hand_value, '"', "'", '')
    " let left_hand_value = substitute(left_hand_value_temp, "!", '', '')

    " devide left_hand_value tips to two parts for it has newline original
    if left_hand_value =~ "\n" || left_hand_value =~ '\n' || left_hand_value == "\n" || left_hand_value == '\n'
        if left_hand_value =~ "\n" || left_hand_value == "\n"
            let index = strridx(left_hand_value, "\n")
            if 0 == index
                let header = "\n"  " let header = '\n'   " trick
                " let truncate_method = ">"
            elseif -1 != index
                " let header = left_hand_value[0: index - 1] . '\n' " trick
                let header = left_hand_value[0: index - 1] . "\n" " trick
            endif
            if index == strlen(left_hand_value) - strlen("\n")
                let left_hand_value = ""
            else
                let left_hand_value = left_hand_value[index + strlen("\n") : strlen(left_hand_value) - 1]
            endif
            " silent! execute '!(printf header1: "'. header . '" >> ' . a:log_address . ' 2>&1 &) > /dev/null'
            " silent! execute '!(printf left_hand_value1: "'. left_hand_value . '" >> ' . a:log_address . ' 2>&1 &) > /dev/null'
        endif
        if left_hand_value =~ '\n' || left_hand_value == '\n'
            let index = strridx(left_hand_value, '\n')
            if 0 == index
                let header = "\n"  " let header = '\n' " trick
                " let truncate_method = ">"
            elseif -1 != index
                " let header = left_hand_value[0: index - 1] . '\n' " trick
                let header = left_hand_value[0: index - 1] . "\n" " trick
            endif
            if index == strlen(left_hand_value) - strlen('\n')
                let left_hand_value = ""
            else
                let left_hand_value = left_hand_value[index + strlen('\n') : strlen(left_hand_value) - 1]
            endif
            " silent! execute '!(printf header2: "'. header . '" >> ' . a:log_address . ' 2>&1 &) > /dev/null'
            " silent! execute '!(printf left_hand_value2: "'. left_hand_value . '" >> ' . a:log_address . ' 2>&1 &) > /dev/null'
        endif
    endif


    let display_width = strdisplaywidth(left_hand_value)
    " let fix_tips_width = 40

    let fat_body = ""
    if a:fix_tips_width <= display_width

        "   if left_hand_value !~ "\n" && left_hand_value !~ '\n'
        "       let left_hand_value .= '\n'
        "   endif

        let fat_body = left_hand_value
        let left_hand_value = ""
    endif

    if ! ("" == left_hand_value && "" == a:value)
        let escape_char_count = 0

        " for il in left_hand_value
        "     if ("\\" == il)
        "         let escape_char_count += 1
        "     endif
        " endfor

        " if a:fix_tips_width > display_width

        let display_width = strdisplaywidth(left_hand_value)
        let gap = a:fix_tips_width - display_width + escape_char_count
        let space_full_fill = ""
        while 0 < gap
            let space_full_fill .= " "
            let gap -= 1
        endwhile
        let left_hand_value .= space_full_fill
    endif


    if 1 == a:log_verbose
        :silent! execute 'redir >> ' . a:log_address
        if "" != header

            " if '>' == truncate_method
            "     let index = stridx(header, "\n")
            "     if 0 != index
            "         let header = '\n' . header
            "     endif
            "     let index = stridx(header, '\n')
            "     if 0 != index
            "         let header = '\n' . header
            "     endif
            " endif

            if header == "\n" || header == '\n'

                " use ! to truncate the log
                " :silent! execute '!redir > ' . a:log_address  " redir udefined
                " :silent! execute 'redir! > ' . a:log_address  " truncate the log file
                " :silent! execute 'redir > ' . a:log_address   " does not work

                " :silent! execute 'redir >> ' . a:log_address

                " echom "\n"  " ^@ or display follow message if keep it and will ask for confirmation if donot commont out
                silent! echom ""
                " redir END

                " " needs confirmation
                " silent! execute "!(printf \n  > " . a:log_address . " 2>&1) &>/dev/null"
            else
                " :silent! execute 'redir >> ' . a:log_address

                " silent! execute '!' . '(printf "' . header . '" ' . truncate_method . ' ' . a:log_address . ' 2>&1) &>/dev/null &'
                " :silent! execute '! "' . header . '" '

                silent! echom header
                " redir END
            endif
        endif


        if "" != fat_body

            " if '>' == truncate_method && "" == header
            "     let fat_body = '\n' . fat_body
            " endif
            " silent! execute '!' . '(printf "' . fat_body . '" >> ' . a:log_address . ' 2>&1) &>/dev/null &'
            " :silent! execute '! "' . fat_body . '" '

            silent! echom fat_body
        endif

        " if '>' == truncate_method && "" == fat_body && "" == header
        "     let left_hand_value = '\n' . left_hand_value
        " endif

        let right_hand_value = a:value

        " let right_hand_value = substitute(a:value, '!', '\\!', '')
        " let find_quote = stridx(right_hand_value, "\"")
        " if -1 != find_quote
        "     echo "logsilent has double quote:" . right_hand_value
        " endif
        " let right_hand_value = substitute(right_hand_value, '"', "'", '')
        " let right_hand_value = substitute(right_hand_value_temp, "!", '', '')

        let right_hand_value = substitute(right_hand_value, '\n\+$', '', '')
        let right_hand_value = substitute(right_hand_value, '\n', '', '')
        let right_hand_value = substitute(right_hand_value, "\n", '', '')

        if ! ("" == left_hand_value && "" == a:value)

            " silent! execute '!' . '(printf "' . left_hand_value . '": "'. right_hand_value . '" >> ' . a:log_address . ' 2>&1) &>/dev/null &'
            " silent! execute '! ' . left_hand_value . ': '. right_hand_value . ' '

            silent! echom left_hand_value . ': '. right_hand_value
            " silent! echom ""
            " :call system(shellescape('printf ' . left_hand_value . ': '. right_hand_value ))

        endif
        redir END
    endif     " a:log_verbose
endfunction

command! -nargs=+ -complete=command LogSilent call boot#log_silent(<f-args>)

" Get project directory
function! boot#project(log_address, is_windows, fix_tips_width, log_verbose)
    if 1 == a:log_verbose
        if 1 == s:_boot_debug
            call boot#log_silent(a:log_address, "\n", "", a:fix_tips_width, a:log_verbose)
            call boot#log_silent(a:log_address, "project::a:is_windows", a:is_windows, a:fix_tips_width, a:log_verbose)
        endif
    endif

    " let l:git = finddir('.git', '.;')
    " let l:git = finddir('.git', resolve(expand('%:p:h')))
    let l:git  = ""
    " let git_list = finddir(".git", resolve(expand("#". bufnr(). ":p:h")), "-1")
    let git_list = finddir(".git", ".;", "-1")
    let l:dir  = ""
    let git_count  = 0
    for gp in git_list
        if 1 == s:_boot_debug
            if (10 > git_count)
                call boot#log_silent(a:log_address, "project::git_list[ 0" . git_count . " ]", gp, a:fix_tips_width, a:log_verbose)
            else
                call boot#log_silent(a:log_address, "project::git_list[ " . git_count . " ]", gp, a:fix_tips_width, a:log_verbose)
            endif
        endif
        if ("" == l:git)
            let l:git     = gp
        elseif (l:git =~ gp)
            let l:git     = gp
        endif
        let git_count     += 1
    endfor

    if 1 == a:log_verbose
        if 1 == s:_boot_debug
            call boot#log_silent(a:log_address, "project::l:git", l:git, a:fix_tips_width, a:log_verbose)
            call boot#log_silent(a:log_address, "project::getcwd()", getcwd(), a:fix_tips_width, a:log_verbose)
        endif
    endif

    if l:git != ".git"
        " when l:git == "" || l:git == "path/to/somewhere/.git"
        if 1 == a:is_windows
            let l:dir  = substitute(l:git, "\\.git", '', 'g')
        else
            let l:dir  = substitute(l:git, "\/.git", '', 'g')
        endif
    else
        " when l:git == ".git"
        " let l:dir  = "."     " let l:dir  = resolve(expand('%:p:h'))
        let l:dir  = resolve(expand(getcwd()))
    endif
    if 1 == a:log_verbose
        if 1 == s:_boot_debug
            call boot#log_silent(a:log_address, "project::l:dir", l:dir, a:fix_tips_width, a:log_verbose)
            call boot#log_silent(a:log_address, "\n", "", a:fix_tips_width, a:log_verbose)
        endif
    endif
    return l:dir
endfunction










