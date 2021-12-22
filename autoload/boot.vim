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


if exists('g:autoloaded_boot')
    finish
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
function! boot#log_silent(log_address, tips, value, log_verbose)

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
    let final = a:tips 

    " let final = substitute(a:tips, '!', '\\!', '')
    " let find_quote = stridx(final, "\"")
    " if -1 != find_quote
    "     echom "logsilent has double quote:" . final
    " endif
    " let final = substitute(final, '"', "'", '')
    " let final = substitute(final_temp, "!", '', '')

    " devide final tips to two parts for it has newline original
    if final =~ "\n" || final =~ '\n' || final == "\n" || final == '\n'
        if final =~ "\n" || final == "\n"
            let index = strridx(final, "\n")
            if 0 == index
                let header = "\n"  " let header = '\n'   " trick
                " let truncate_method = ">"
            elseif -1 != index
                " let header = final[0: index - 1] . '\n' " trick
                let header = final[0: index - 1] . "\n" " trick
            endif
            if index == strlen(final) - strlen("\n")
                let final = ""
            else
                let final = final[index + strlen("\n"): strlen(final) - 1]
            endif
            " silent! execute '!(printf header1: "'. header . '" >> ' . a:log_address . ' 2>&1 &) > /dev/null'
            " silent! execute '!(printf final1: "'. final . '" >> ' . a:log_address . ' 2>&1 &) > /dev/null'
        endif
        if final =~ '\n' || final == '\n'
            let index = strridx(final, '\n')
            if 0 == index
                let header = "\n"  " let header = '\n' " trick
                " let truncate_method = ">"
            elseif -1 != index
                " let header = final[0: index - 1] . '\n' " trick
                let header = final[0: index - 1] . "\n" " trick
            endif
            if index == strlen(final) - strlen('\n')
                let final = ""
            else
                let final = final[index + strlen('\n'): strlen(final) - 1]
            endif
            " silent! execute '!(printf header2: "'. header . '" >> ' . a:log_address . ' 2>&1 &) > /dev/null'
            " silent! execute '!(printf final2: "'. final . '" >> ' . a:log_address . ' 2>&1 &) > /dev/null'
        endif
    endif


    let display_width = strdisplaywidth(final)
    let fix_tips_width = 40

    let body = ""
    if fix_tips_width <= display_width

        "   if final !~ "\n" && final !~ '\n'
        "       let final .= '\n'
        "   endif

        let body = final
        let final = ""
    endif

    if ! ("" == final && "" == a:value)
        let escape_char_count = 0

        " for il in final
        "     if ("\\" == il)
        "         let escape_char_count += 1
        "     endif
        " endfor

        " if fix_tips_width > display_width

        let display_width = strdisplaywidth(final)
        let gap = fix_tips_width - display_width + escape_char_count
        let space_full_fill = ""
        while 0 < gap
            let space_full_fill .= " "
            let gap -= 1
        endwhile
        let final .= space_full_fill
    endif

    if 1 == a:log_verbose
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
                :silent! execute 'redir >> ' . a:log_address

                " echom "\n"  " ^@ or display follow message if keep it and will ask for confirmation if donot commont out
                silent! echom ""
                redir END
                " " needs confirmation
                " silent! execute "!(printf \n  > " . a:log_address . " 2>&1) &>/dev/null"
            else
                :silent! execute 'redir >> ' . a:log_address

                " silent! execute '!' . '(printf "' . header . '" ' . truncate_method . ' ' . a:log_address . ' 2>&1) &>/dev/null &'
                " :silent! execute '! "' . header . '" '

                silent! echom header
                redir END
            endif
        endif
    endif     " a:log_verbose

    if 1 == a:log_verbose
        :silent! execute 'redir >> ' . a:log_address

        if "" != body 

            " if '>' == truncate_method && "" == header
            "     let body = '\n' . body
            " endif
            " silent! execute '!' . '(printf "' . body . '" >> ' . a:log_address . ' 2>&1) &>/dev/null &'
            " :silent! execute '! "' . body . '" '

            silent! echom body
        endif

        " if '>' == truncate_method && "" == body && "" == header
        "     let final = '\n' . final
        " endif

        let final_value = a:value

        " let final_value = substitute(a:value, '!', '\\!', '')
        " let find_quote = stridx(final_value, "\"")
        " if -1 != find_quote
        "     echo "logsilent has double quote:" . final_value
        " endif
        " let final_value = substitute(final_value, '"', "'", '')
        " let final_value = substitute(final_value_temp, "!", '', '')

        let final_value = substitute(final_value, '\n\+$', '', '')
        let final_value = substitute(final_value, '\n', '', '')
        let final_value = substitute(final_value, "\n", '', '')

        if ! ("" == final && "" == a:value)

            " silent! execute '!' . '(printf "' . final . '": "'. final_value . '" >> ' . a:log_address . ' 2>&1) &>/dev/null &'
            " silent! execute '! ' . final . ': '. final_value . ' '

            silent! echom final . ': '. final_value

            " :call system(shellescape('printf ' . final . ': '. final_value ))

        endif
        redir END
    endif     " a:log_verbose
endfunction

command! -nargs=+ -complete=command LogSilent call boot#log_silent(<f-args>)

" Get project directory
function! boot#project(log_address, is_windows, log_verbose) 
    call boot#log_silent(a:log_address, "\n", "", a:log_verbose) 
    call boot#log_silent(a:log_address, "project::a:is_windows", a:is_windows, a:log_verbose)
    "   let l:git = finddir('.git', '.;')
    "   let l:git = finddir('.git', resolve(expand('%:p:h')))
    let l:git  = ""
    "   let git_list = finddir(".git", resolve(expand("#". bufnr(). ":p:h")), "-1")
    let git_list = finddir(".git", ".;", "-1")
    let l:dir  = ""
    let git_count  = 0
    for gp in git_list
        if (10 > git_count)
            call boot#log_silent(a:log_address, "project::git_list[ 0" . git_count . " ]", gp, a:log_verbose)
        else
            call boot#log_silent(a:log_address, "project::git_list[ " . git_count . " ]", gp, a:log_verbose)
        endif
        if ("" == l:git)
            let l:git     = gp
        elseif (l:git =~ gp)
            let l:git     = gp
        endif
        let git_count     += 1
    endfor

    call boot#log_silent(a:log_address, "project::l:git", l:git, a:log_verbose)
    call boot#log_silent(a:log_address, "project::getcwd()", getcwd(), a:log_verbose)

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
    call boot#log_silent(a:log_address, "project::l:dir", l:dir, a:log_verbose)
    call boot#log_silent(a:log_address, "\n", "", a:log_verbose) 
    return l:dir
endfunction

let g:autoloaded_boot = 1









