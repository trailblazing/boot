" Utilities for vim operation

if exists('g:loaded_boot')
	finish
endif

let g:loaded_boot = 1

let s:_init_value = {}
let s:_init_value._log_address		= $HOME . '/.vim.log'
let s:_init_value._fixed_tips_width = 37
let s:_init_value._log_verbose		= 0
let s:_init_value._is_windows		= 0
let s:_init_value._script_develop	= 0
let s:_init_value._log_one_line		= 1
let s:_init_value._indent			= 4
let s:_init_value._job_start		= has('nvim') ? 'jobstart' : 'job_start'

if ! exists("g:_boot_develop")
	let s:_boot_develop = 0
	let g:_boot_develop = 0
else
	let s:_boot_develop = g:_boot_develop
endif

function! s:print_to_log(header,
	\ key,
	\ value,
	\ fixed_tips_width = 37,
	\ log_address = $HOME . '/.vim.log')

	silent! execute(
		\ '!printf ' . '"\%-' . 37	. 's: \%s\n"' .
		\ ' "' . a:header . '::' . a:key . '"' .
		\ ' "' . a:value . '"' .
		\ ' >> ' . a:log_address . ' 2>&1 &' )
endfunction

function! boot#initialize(object,
	\ _verbose = g:_script_develop,
	\ _init_value = g:_environment)

	for [key, V] in items(a:_init_value)
		if 'new' ==? key
			continue
		endif
		if exists('g:_environment') && exists('g:_environment.' . key)
			execute('let a:object.' . key . ' = g:_environment.' . key)
			if 1 == a:_verbose
				call s:print_to_log(s:_file_name,
					\ "g:_environment." . key,
					\ execute('echon a:object.' . key),
					\ a:_init_value._fixed_tips_width, a:_init_value._log_address)
			endif
		elseif exists('g:' . key)
			execute('let a:object.' . key . ' = g:' . key)
			if 1 == a:_verbose
				call s:print_to_log(s:_file_name,
					\ "g:" . key,
					\ execute('echon a:object.' . key),
					\ a:_init_value._fixed_tips_width, a:_init_value._log_address)
			endif
		elseif exists('a:_init_value.' . key)
			execute('let a:object.' . key . ' = "' . V . '"')
			if 1 == a:_verbose
				call s:print_to_log(s:_file_name,
					\ "a:_init_value." . key,
					\ execute('echon a:object.' . key),
					\ a:_init_value._fixed_tips_width, a:_init_value._log_address)
			endif
		endif
	endfor
	return a:object
endfunction

function! boot#show(object, file_name,
	\ _init_value = g:_environment)

	silent! execute '!printf "\n"' . ' >> '
		\ . a:_init_value._log_address . ' 2>&1 &'

	:let index = 0
	for item in v:argv
		call s:print_to_log(a:file_name, "v:argv[" . index . "]", item,
			\ a:_init_value._fixed_tips_width, a:_init_value._log_address)
		:let index = index + 1
	endfor

	for [key, V] in items(a:object)
		" if 'new' ==? key
		"	  continue
		" endif
		call s:print_to_log(a:file_name, key, V,
			\ a:_init_value._fixed_tips_width, a:_init_value._log_address)
	endfor
endfunction

function! boot#environment(
	\ _self,
	\ _file_name,
	\ _develop = g:_script_develop,
	\ _init_value = g:_environment)

	let object = copy(a:_self)

	let object = boot#initialize(object, a:_develop, a:_init_value)

	if ! exists("g:_environment")
		let g:_environment	= deepcopy(object, 1)
	else
		for [key, V] in items(object)
			if ! exists("g:_environment." . key)
				execute 'let g:_environment.' . key . ' = ' . V
			endif
		endfor
	endif

	call boot#show(object, a:_file_name, a:_init_value)

	return object

endfunction

let s:environment = {}


" https://vi.stackexchange.com/questions/2867/how-do-you-chomp-a-string-in-vim
" Will break on some shell environment [busybox ash?]
" function! boot#chomped_system( ... )
"	  " return substitute(call('system', a:000), '\n\+$', '', '')
"	  return strtrans(substitute(system(a:000), '\n\+$', '', ''))
" endfunction
function! boot#chomp(str) abort "{{{
	return strtrans(substitute(a:str, '\%(\r\n\|[\r\n]\)$', '', ''))
endfunction "}}}

if ! exists("s:_environment")

	let s:_file_name = boot#chomp(system('basename ' . resolve(expand('<script>'))))

	let s:_environment = boot#environment(s:environment,
		\ s:_file_name,
		\ s:_boot_develop, s:_init_value)
	" echo s:_environment
endif

" https://vi.stackexchange.com/questions/5501/is-there-a-way-to-get-the-name-of-the-current-function-in-vim-script
function! boot#function_name(sid, sfile)
	" return substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')
	" return substitute(a:file, '.*\(\.\.\|\s\)', '', '')

	let name   = substitute(a:sfile, '.*\(\.\.\|\s\)', '', '')
	let num    = matchstr(a:sid, '<SNR>\zs\d\+\ze_')
	if num == ""
		let num = matchstr(a:sid, '#')
		let index  = stridx(name, num)
		let result = name[index + strlen(num) : strlen(name) - 1]
	else
		let index  = stridx(name, num)
		let result = name[index + strlen(num) + 1 : strlen(name) - 1]
	endif
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
	"	script_name : (str) The name of a sourced script.
	"
	" Return:
	"	(int) The <SNR> of the script; if the script isn't found, -1.

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

function! boot#standardize(_file_dir)
	if '/' == a:_file_dir
		return a:_file_dir
	endif
	let l:standard_dir = a:_file_dir
	let l:index = stridx(a:_file_dir, "\/")
	" a:_file_dir is a relative dir/empty
	" ./ | dir_name | dir_name/folder | . | ""
	if 0 != l:index || -1 == l:index
		" let l:standard_dir = getcwd() . '/' . a:_file_dir
		let l:standard_dir = fnamemodify(a:_file_dir, ':p:h')
		return l:standard_dir
	endif
	" let l:rindex = strridx(a:_file_dir, "\/")
	" if strlen(a:_file_dir) - 1 == l:rindex
	"	  " let l:standard_dir = getcwd() . '/' . a:_file_dir
	"	  let l:standard_dir = fnamemodify(a:_file_dir, ':p:h')
	" endif
	let l:index = 0
	while '/' ==
		\ l:standard_dir[ strlen(l:standard_dir) - 1
		\ : strlen(l:standard_dir) - 1 ]
		" \ && -1 != stridx(l:standard_dir, "\/")
		" let l:standard_dir = l:standard_dir[ 0 : strlen(l:standard_dir) - 2 ]
		let l:standard_dir = fnamemodify(l:standard_dir, ':p:h')
		let l:index = l:index + 1
		if 100 <= l:index
			let l:func_name = boot#function_name('#', expand('<sfile>'))
			echohl WarningMsg
			echom "l:standard_dir == " . l:standard_dir . "[ " . l:func_name . " ]"
			call feedkeys("\<CR>")
			echohl None
			break
		endif
	endwhile
	return l:standard_dir
endfunction

" https://vi.stackexchange.com/questions/9962/get-filetype-by-extension-or-filename-in-vimscript
function! boot#extension()
	let ext = expand('%:e')
	let matching =
		\ uniq(sort(filter(split(execute('autocmd filetypedetect'), "\n"),
		\ 'v:val =~ "\*\.".ext')))

	if len(matching) == 1 && matching[0]  =~ 'setf'
		return matchstr(matching[0], 'setf\s\+\zs\k\+')
	endif
	throw "sorry, I don't know"
endfunction

function! s:save_file_via_doas() abort
	" https://askubuntu.com/questions/454649/how-can-i-change-the-default-editor-of-the-sudoedit-command-to-be-vim
	" https://unix.stackexchange.com/questions/90866/sudoedit-vim-force-write-update-without-quit/635704#635704
	" inotifywait
	" https://github.com/lambdalisue/suda.vim
	" echo executable('sudo')
	" https://github.com/vim-scripts/sudo.vim
	"	  (command line): vim sudo:/etc/passwd
	"	  (within vim):   :e sudo:/etc/passwd
	if executable('doas')
		silent! execute (has('gui_running') ? '' : 'silent')
			\ 'write !env EDITOR=tee doasedit '
			\ . shellescape(expand('%')) . ' >/dev/null '
		" execute (has('gui_running') ? '' : 'silent')
		"	  \ 'write !env EDITOR=doasedit doas -e '
		"	  \ . shellescape(expand('%')) . ' >/dev/null '
		echohl WarningMsg
		echon expand('%') . " saved by doasedit"
		echohl None
	elseif executable('sudo')
		silent! execute (has('gui_running') ? '' : 'silent')
			\ 'write !env SUDO_EDITOR=tee sudo -e '
			\ . shellescape(expand('%')) . ' >/dev/null '
		echohl WarningMsg
		echon expand('%') . " saved by sudo "
		echohl None
	endif
	let &modified = v:shell_error
endfunction
" https://unix.stackexchange.com/questions/249221/vim-sudo-hack-auto-reload
cnoremap w!! silent! call <sid>save_file_via_doas()<cr>

function! boot#write_generic()
	let l:needs_su = v:true
	if has('nvim')
		if (system(['whoami']) == system(['stat', '-c', '%U', expand('%')])) ||
			\ (join(split(system(['whoami']))) == 'root')
			let l:needs_su = v:false
		endif
	else
		if system('whoami') == system("stat -c %U " . expand('%'))
			let l:needs_su = v:false
		endif
	endif
	if l:needs_su
		call s:save_file_via_doas()
	else
		silent! execute("write " . expand('%'))
		echohl WarningMsg
		echon expand('%') . " saved as ". $USER
		echohl None
	endif
endfunction

command! -nargs=0 W call boot#write_generic()
:cnoreabbrev <expr> w getcmdtype() == ":" && getcmdline() == 'w' ? 'W' : 'w'

" silent will mute the summery of writting
" :cnoreabbrev w silent! call boot#write_generic()
" Automatic substitution will prevent you from typing "w" itself normally
" :cnoreabbrev w call boot#write_generic()


function! s:reload()
	if exists('g:loaded_boot')
		unlet g:loaded_boot
	endif
	" let g:debug_keys	  = 1
	silent! execute "source " . expand('%')
	silent! execute "runtime! " . expand('%')
endfunction

command! -nargs=0 BR :call s:reload()

function! s:tail(_head, _tail = "", _environment = g:_environment)

	if type(a:_head) == v:t_func
		let l:head = "Funcref ... "
	else
		let l:head = a:_head
	endif

	if type(a:_tail) == v:t_func
		let l:tail = "Funcref ... "
	else
		let l:tail = a:_tail
	endif

	let result = ""

	if len(l:head) == 0 && len(l:tail) == 0
		return result
	endif

	if type(l:head) == v:t_list
		let result .= "[ "
		for H in l:head
			let result .=
				\ s:header(H, s:tail(l:tail, "", a:_environment),
				\ a:_environment) . ", "
		endfor
		let result .= "]"
	elseif type(l:head) == v:t_dict
		let result .= "{ "
		for [H, T] in items(l:head)
			let result .=
				\ s:header(H, s:header(T, s:tail(l:tail, "", a:_environment),
				\ a:_environment), a:_environment) . ", "
		endfor
		let result .= "}"
	elseif len(l:head) > 0 &&
		\ len(l:tail) > 0 ||
		\ type(l:tail) == v:t_dict || type(l:tail) == v:t_list

		let result = l:head . " : " . s:tail(l:tail, "", a:_environment)
	elseif len(l:head) > 0 && len(l:tail) > 0
		let result = l:head . " : " . l:tail
	elseif len(l:head) > 0
		let result = l:head
	endif

	return result
endfunction

function! s:header(_head, _tail = "", _environment = g:_environment)

	if type(a:_head) == v:t_func
		let l:head = "Funcref ... "
	else
		let l:head = a:_head
	endif

	if type(a:_tail) == v:t_func
		let l:tail = "Funcref ... "
	else
		let l:tail = a:_tail
	endif

	let result = ""

	if len(l:head) == 0 && len(l:tail) == 0
		return result
	endif

	if type(l:head) == v:t_list
		let result .= "[ "
		for H in l:head
			let result .= s:header(H, s:tail(l:tail, "", a:_environment),
				\ a:_environment) . ", "
		endfor
		let result .= "]"
	elseif type(l:head) == v:t_dict
		let result .= "{ "
		for [H, T] in items(l:head)
			let result .=
				\ s:header(H, s:header(T, s:tail(l:tail, "", a:_environment),
				\ a:_environment), a:_environment) . ", "
		endfor
		let result .= "}"
	elseif len(l:head) > 0 &&
		\ len(l:tail) > 0 ||
		\ type(l:tail) == v:t_dict || type(l:tail) == v:t_list
		let result = l:head . " : " . s:tail(l:tail, "", a:_environment)
	elseif len(l:head) > 0 && len(l:tail) > 0
		let result = l:head . " : " . l:tail
	elseif len(l:head) > 0
		let result = l:head
	endif

	return result
endfunction

" Dealing with list, dict, and Funcref ...
function! boot#log_one_line(key,
	\ value = "", _environment = g:_environment)

	let result = s:header(a:key, a:value, a:_environment)

	" "_log_verbose" should not be here
	" if 1 == a:_environment._log_verbose
	" silent! execute 'redir >> ' . a:_environment._log_address
	" silent! echom result
	silent! execute '!(printf "\%s\n" "' . result . '"
		\ >> ' . a:_environment._log_address . ' 2>&1 &' . ')'
	" redir END
	" endif
endfunction

function! s:right_hand_output(
	\ _indent,
	\ _left_hand_string,
	\ _right_hand_value,
	\ _delimiter   = ',',
	\ _new_line    = '\n',
	\ _environment = g:_environment
	\ )

	if type(a:_right_hand_value) == v:t_func
		let l:right_hand_value = "Funcref ... "
	else
		let l:right_hand_value = a:_right_hand_value
	endif

	if type(l:right_hand_value) == v:t_dict
		for [K, V] in items(l:right_hand_value)
			" call s:log_no_new_line(a:_indent . "::" .
			" \ a:_left_hand_string, K, V, a:_delimiter, a:_environment)
			call s:log_no_new_line(a:_left_hand_string . "::",
				\ K, V, ',', '\n', a:_environment)
		endfor
	elseif type(l:right_hand_value) == v:t_list
		for V in l:right_hand_value
			" call s:right_hand_output(a:_indent,
			" \ a:_left_hand_string, V, ',', '\n', a:_environment)
			call s:right_hand_output("", a:_left_hand_string,
				\ V, ',', '\n', a:_environment)
		endfor
	else
		let l:right_hand_string = l:right_hand_value
		" let l:right_hand_string =
		"	  \ substitute(l:right_hand_string, '!', '\\!', '')
		" let find_quote = stridx(l:right_hand_string, "\"")
		" if -1 != find_quote
		"	  echo "logsilent has double quote:" . l:right_hand_string
		" endif
		" let l:right_hand_string =
		"	  \ substitute(l:right_hand_string, '"', "'", '')
		" let l:right_hand_string =
		"	  \ substitute(l:right_hand_string, "!", '', '')

		let l:right_hand_string =
			\ substitute(l:right_hand_string, '\n\+$', '', '')
		let l:right_hand_string =
			\ substitute(l:right_hand_string, '\n', '', '')
		let l:right_hand_string =
			\ substitute(l:right_hand_string, "\n", '', '')

		if ! ("" == a:_left_hand_string && "" == l:right_hand_string)
			call assert_true(type(a:_left_hand_string) !=
				\ v:t_dict, "a:_left_hand_string design expected string")
			call assert_true(type(l:right_hand_string) !=
				\ v:t_dict, "l:right_hand_string design expected string")

			" if type(l:right_hand_string) == v:t_dict
			" \ || type(a:_left_hand_string) == v:t_dict
			"
			"	  " silent! execute '!printf "\%s: \%s"
			"	  "		\ "type(l:right_hand_string)" "' .
			"	  "		\ type(l:right_hand_string) . '" >> '
			"	  "		\ . a:_environment._log_address . ' 2>&1 &'
			"	  call boot#log_one_line(">>>>value of l:right_hand_string",
			"		  \ l:right_hand_string, a:_environment)
			"
			"	  " silent! execute '!printf "\%s: \%s"
			"	  "		\ "value of _left_hand_string" "' .
			"	  "		\ a:_left_hand_string . '" >> '
			"	  "		\ . a:_environment._log_address . ' 2>&1 &'
			"	  call boot#log_one_line("<<<<value of a:_left_hand_string",
			"		  \ a:_left_hand_string, a:_environment)
			"
			" else
			"	  let cmd = '!(printf "' . a:_indent . '\%s: \%s'
			"		  \ . a:_delimiter . '" "' . a:_left_hand_string . '" "' .
			"		  \ l:right_hand_string . '") >> '
			"		  \ . a:_environment._log_address . ' 2>&1'
			" endif

			" silent! execute '!printf "\n" "" >> '
			"	  \ . a:_environment._log_address . ' 2>&1 &'
			" call boot#log_one_line(">>>debug", "cmd", a:_environment)
			" exec '!printf "' . shellescape(cmd, 1)
			"	  \ . '" >> ' . a:_environment._log_address . ' 2>&1'
			" silent! execute '!printf "\n" "" >> '
			"	  \ . a:_environment._log_address . ' 2>&1 &'

			" silent! execute '!printf "\%' . a:_environment._indent . 's"' .
			" \ ' "" >> '  . a:_environment._log_address . ' 2>&1 &'
			" silent! execute '!(printf "\%s" "' . a:_left_hand_string . ': '.
			" \ l:right_hand_string . '") >> '
			" \ . a:_environment._log_address . ' 2>&1 &'

			silent! execute '!(printf "\%s: \%s' .
				\ a:_delimiter . ' ' .
				\ a:_new_line . '" "' .
				\ a:_indent .
				\ a:_left_hand_string . '" "' .
				\ l:right_hand_string . '" >> ' .
				\ a:_environment._log_address .
				\ ' 2>&1 &' . ')'
			" silent! echom a:_left_hand_string . ': '. l:right_hand_string
			" :call system(shellescape('printf '
			" \ . a:_left_hand_string . ': '. l:right_hand_string ))

		endif
	endif

endfunction


function! s:key_string(
	\ _indent,
	\ _left_hand_value,
	\ _right_hand_value = "",
	\ _delimiter		= ',',
	\ _new_line			= '\n',
	\ _environment		= g:_environment
	\ )

	function! s:length(_right_hand_value)
		if type(a:_right_hand_value) == v:t_func
			let l:right_hand_value = "Funcref ... "
		else
			let l:right_hand_value = a:_right_hand_value
		endif
		return len(l:right_hand_value)
	endfunction

	if s:length(a:_right_hand_value) == 0
		\ && s:length(a:_left_hand_value) == 0
		return
	endif

	if type(a:_left_hand_value) == v:t_func
		let l:left_hand_value = "Funcref ... "
	else
		let l:left_hand_value = a:_left_hand_value
	endif

	if type(a:_right_hand_value) == v:t_func
		let l:right_hand_value = "Funcref ... "
	else
		let l:right_hand_value = a:_right_hand_value
	endif

	" hard to understand, gave up
	" if (0 < a:0)
	"	  let value = "\"" . a:1 . "\""
	" else
	"	  let value = ""
	" endif

	" if (1 < a:0)
	"	  let truncate_method = a:2
	"	  if truncate_method == "\"" . '>' . "\""
	"		  let truncate_method = '>'
	"	  endif
	" else
	"	  let truncate_method = ">>"
	" endif

	let truncate_method = ">>"

	" deal with "\n" and '\n'
	let header = ""

	let l:left_hand_string = l:left_hand_value

	" let l:left_hand_string = substitute(a:key, '!', '\\!', '')
	" let find_quote = stridx(l:left_hand_string, "\"")
	" if -1 != find_quote
	"	  echom "logsilent has double quote:" . l:left_hand_string
	" endif
	" let l:left_hand_string = substitute(l:left_hand_string, '"', "'", '')
	" let l:left_hand_string = substitute(l:left_hand_string_temp, "!", '', '')

	" devide l:left_hand_string tips to two parts for it has newline original
	if l:left_hand_string =~ "\n" || l:left_hand_string =~ '\n'
		\ || l:left_hand_string == "\n" || l:left_hand_string == '\n'

		if l:left_hand_string =~ "\n" || l:left_hand_string == "\n"
			let index = stridx(l:left_hand_string, "\n")
			if 0 == index
				let header = "\n"  " let header = '\n'	 " trick
				" let truncate_method = ">"
			elseif -1 != index
				" let header = l:left_hand_string[0: index - 1] . '\n' " trick
				let header = l:left_hand_string[0: index - 1] . "\n" " trick
			endif
			if index == strlen(l:left_hand_string) - strlen("\n")
				let l:left_hand_string = ""
			else
				let l:left_hand_string =
					\ l:left_hand_string[index + strlen("\n")
					\ : strlen(l:left_hand_string) - 1]
			endif
			" silent! execute '!(printf header1: "'. header . '" >> ' .
			" \ a:_environment._log_address . ' 2>&1 &) > /dev/null'
			" silent! execute '!(printf l:left_hand_string1: "'. l:left_hand_string .
			" \ '" >> ' . a:_environment._log_address . ' 2>&1 &) > /dev/null'
		endif
		if l:left_hand_string =~ '\n' || l:left_hand_string == '\n'
			let index = stridx(l:left_hand_string, '\n')
			if 0 == index
				let header = "\n"  " let header = '\n' " trick
				" let truncate_method = ">"
			elseif -1 != index
				" let header = l:left_hand_string[0: index - 1] . '\n' " trick
				let header = l:left_hand_string[0: index - 1] . "\n" " trick
			endif
			if index == strlen(l:left_hand_string) - strlen('\n')
				let l:left_hand_string = ""
			else
				let l:left_hand_string =
					\ l:left_hand_string[index + strlen('\n')
					\ : strlen(l:left_hand_string) - 1]
			endif
			" silent! execute '!(printf header2: "'. header . '" >> '
			" \ . a:_environment._log_address . ' 2>&1 &) > /dev/null'
			" silent! execute '!(printf l:left_hand_string2: "'. l:left_hand_string .
			" \ '" >> ' . a:_environment._log_address . ' 2>&1 &) > /dev/null'
		endif
	endif


	let display_width = strdisplaywidth(l:left_hand_string)
	" let fixed_tips_width = 40

	let fat_body = ""
	if a:_environment._fixed_tips_width <= display_width

		"	if l:left_hand_string !~ "\n" && l:left_hand_string !~ '\n'
		"		let l:left_hand_string .= '\n'
		"	endif

		let fat_body = l:left_hand_string
		let l:left_hand_string = ""
	endif
	" Align indentations
	if ! ("" == l:left_hand_string && 0 == s:length(l:right_hand_value))
		let escape_char_count = 0

		" for il in l:left_hand_string
		"	  if ("\\" == il)
		"		  let escape_char_count += 1
		"	  endif
		" endfor

		" if a:_environment._fixed_tips_width > display_width

		let display_width = strdisplaywidth(l:left_hand_string)
		let gap = a:_environment._fixed_tips_width
			\ - display_width + escape_char_count
		let space_full_fill = ""
		while 0 < gap
			let space_full_fill .= " "
			let gap -= 1
		endwhile
		let l:left_hand_string .= space_full_fill
	endif

	" "_log_verbose" should not be here
	" if exists("a:_environment._log_verbose")
	"	  \ && 1 == a:_environment._log_verbose

	" :silent! execute 'redir >> ' . a:_environment._log_address

	if "" != header

		" if '>' == truncate_method
		"	  let index = stridx(header, "\n")
		"	  if 0 != index
		"		  let header = '\n' . header
		"	  endif
		"	  let index = stridx(header, '\n')
		"	  if 0 != index
		"		  let header = '\n' . header
		"	  endif
		" endif

		if header == "\n" || header == '\n'

			" use ! to truncate the log
			" :silent! execute 'redir! > '
			" \ . a:_environment._log_address  " truncate the log file
			"
			" :silent! execute 'redir > '
			" \ . a:_environment._log_address	" does not work

			" :silent! execute 'redir >> ' . a:_environment._log_address

			" echom "\n"  " ^@ or display follow message if keep
			" it and will ask for confirmation if donot commont out

			" silent! echom ""
			silent! execute '!printf "\n"' . ' >> '
				\ . a:_environment._log_address . ' 2>&1'

			" redir END
		else
			" :silent! execute 'redir >> ' . a:_environment._log_address

			" :silent! execute '!' . '(printf "' . header . '" '
			"	  \ . truncate_method . ' ' . a:_environment._log_address
			"	  \ . ' 2>&1) &'

			" silent! echom header
			silent! execute '!printf "' . header . '\n"'
				\ . ' >> '	. a:_environment._log_address . ' 2>&1'
			" redir END
		endif
	endif


	if "" != fat_body

		" if '>' == truncate_method && "" == header
		"	  let fat_body = '\n' . fat_body
		" endif

		" :silent! execute '!' . '(printf "' . fat_body . '" >> '
		" \ . a:_environment._log_address . ' 2>&1) &'

		" silent! echom fat_body
		silent! execute '!printf "' . fat_body . '"'
			\ . ' >> '	. a:_environment._log_address . ' 2>&1'
	endif

	" if '>' == truncate_method && "" == fat_body && "" == header
	"	  let l:left_hand_string = '\n' . l:left_hand_string
	" endif

	call s:right_hand_output(
		\ a:_indent,
		\ l:left_hand_string,
		\ l:right_hand_value,
		\ a:_delimiter,
		\ a:_new_line,
		\ a:_environment)

	" redir END

	" endif		" a:_environment._log_verbose
endfunction

function! s:log_no_new_line(
	\ _indent,
	\ _left_hand_value,
	\ _right_hand_value = "",
	\ _delimiter		= ',',
	\ _new_line			= '\n',
	\ _environment		= g:_environment
	\ )

	function! s:length(_right_hand_value)
		if type(a:_right_hand_value) == v:t_func
			let l:right_hand_value = "Funcref ... "
		else
			let l:right_hand_value = a:_right_hand_value
		endif
		return len(l:right_hand_value)
	endfunction

	if s:length(a:_right_hand_value) == 0 && s:length(a:_left_hand_value) == 0
		return
	endif

	if type(a:_left_hand_value) == v:t_func
		let l:left_hand_value = "Funcref ... "
	else
		let l:left_hand_value = a:_left_hand_value
	endif

	if type(a:_right_hand_value) == v:t_func
		let l:right_hand_value = "Funcref ... "
	else
		let l:right_hand_value = a:_right_hand_value
	endif

	" let result = s:header(a:key, a:value, a:_environment)

	if type(l:left_hand_value) == v:t_list
		call s:log_no_new_line("", '[ ', "", ',', '\n', a:_environment)
		for H in l:left_hand_value
			call s:log_no_new_line('----', H, "", ',', '\n', a:_environment)
		endfor
		call s:log_no_new_line("", "", ']', ',', '\n', a:_environment)
		call s:log_no_new_line(
			\ '----', "", l:right_hand_value, ',', '\n', a:_environment)
	elseif type(l:left_hand_value) == v:t_dict
		call s:log_no_new_line("", '{ ', "", ',', '\n', a:_environment)
		for [H, T] in items(l:left_hand_value)
			call s:log_no_new_line('----', H, T, ',', '\n', a:_environment)
		endfor
		call s:log_no_new_line("", "", '}', ',', '\n', a:_environment)
		call s:log_no_new_line(
			\ '----', "", l:right_hand_value, ',', '\n', a:_environment)
	else
		call s:key_string(
			\ a:_indent,
			\ l:left_hand_value,
			\ l:right_hand_value,
			\ a:_delimiter,
			\ a:_new_line,
			\ a:_environment)
	endif
endfunction

" We do not handle a file truncation in this method
" Just redir and echo to a fixed log file, g:log_address
" function! boot#log_silent(log_address, tips, value, fixed_tips_width, log_verbose)
function! boot#log_multi_line(
	\ _left_hand_value,
	\ _right_hand_value = "",
	\ _environment = g:_environment)

	call s:log_no_new_line(
		\ "",
		\ a:_left_hand_value,
		\ a:_right_hand_value,
		\ '',
		\ '',
		\ a:_environment)
	silent! execute '!printf "\n" >> '
		\ . a:_environment._log_address . ' 2>&1 &'
endfunction

if s:_environment._log_one_line == 1
	function! boot#log_silent(key,
		\ value = "", _environment = g:_environment)
		call boot#log_one_line(a:key, a:value, a:_environment)
	endfunction
else
	function! boot#log_silent(key,
		\ value = "", _environment = g:_environment)
		call boot#log_multi_line(a:key, a:value, a:_environment)
	endfunction
endif

command! -nargs=+ -complete=command LogSilent call boot#log_silent(<f-args>)

" https://stackoverflow.com/questions/22860459/expand-relative-path-wrt-containing-file
function! boot#absolute_dir(filespec)
	if expand('%:h') !=# '.'
		" Need to change into the file's directory first to get glob results
		" relative to the file.
		let l:save_cwd = getcwd()
		let l:chdirCommand = (haslocaldir() ? 'lchdir!' : 'chdir!')
		execute l:chdirCommand '%:p:h'
	endif
	try
		" Get the full path to a:filespec, relative to the current file's directory.
		let l:absoluteFilespec = fnamemodify(a:filespec, ':p')
	finally
		if exists('l:save_cwd')
			execute l:chdirCommand fnameescape(l:save_cwd)
		endif
	endtry
endfunction

function! boot#bufferslist()
	let all = range(0, bufnr('$'))
	let res = []
	for b in all
		if buflisted(b)
			call add(res, bufname(b))
		endif
	endfor
	return res
endfunction

" Get project directory
" function! boot#project(log_address, is_windows, fixed_tips_width, log_verbose)
function! boot#project(
	\ _file_dir = "",
	\ _environment = g:_environment)

	if '/' == a:_file_dir
		return a:_file_dir
	endif

	if 1 == a:_environment._log_verbose
		if 1 == s:_boot_develop
			call boot#log_silent("\n", "")
			call boot#log_silent("project::a:_environment._is_windows"
				\, a:_environment._is_windows)
		endif
	endif

	" let l:git = finddir('.git', '.;')
	" let l:git = finddir('.git', resolve(expand('%:p:h')))
	let l:git  = ""
	let target_dir =
		\ fnamemodify(resolve(expand("#". bufnr(). ":p:h")), ':p:h')
	if "" != a:_file_dir
		let target_dir = boot#standardize(a:_file_dir)
	endif

	" let git_list = finddir(".git", resolve(expand("#". bufnr(). ":p:h")), "-1")
	" let git_list = finddir(".git", ".;", "-1")
	" let git_list = finddir(".git", $PWD, "-1")

	let git_list = finddir(".git", target_dir . ";", "-1")
	let l:dir = ""
	let git_count  = 0

	for gp in git_list
		if 1 == s:_boot_develop
			if (10 > git_count)
				call boot#log_silent(
					\ "project::git_list[ 0" . git_count . " ]", gp)
			else
				call boot#log_silent(
					\ "project::git_list[ " . git_count . " ]", gp)
			endif
		endif

		if ("" == l:git)
			let l:git  = gp
		elseif (l:git =~ gp)
			let l:git  = gp
		endif

		let git_count += 1

	endfor

	if 1 == a:_environment._log_verbose
		if 1 == s:_boot_develop
			call boot#log_silent("project::l:git", l:git)
			call boot#log_silent("project::getcwd()", getcwd())
		endif
	endif

	if l:git != ".git"
		" when l:git == "" || l:git == "path/to/somewhere/.git"
		if "" == l:git
			let l:dir  =
				\ fnamemodify(
				\ resolve(expand("#". bufnr(). ":p:h")), ':p:h')
		else
			if 1 == a:_environment._is_windows
				let l:dir  = substitute(l:git, "\\.git", '', 'g')
			else
				let l:dir  = substitute(l:git, "\/.git", '', 'g')
			endif
		endif
	else
		" when l:git == ".git"
		" let l:dir  = "."
		" let l:dir  = resolve(expand('%:p:h'))
		" let l:dir  = resolve(expand(getcwd()))
		let l:dir  =
			\ fnamemodify(
			\ resolve(expand("#". bufnr(). ":p:h")), ':p:h')

	endif

	let l:dir = boot#standardize(l:dir)

	if 1 == a:_environment._log_verbose
		if 1 == s:_boot_develop
			call boot#log_silent("project::l:dir", l:dir)
			call boot#log_silent("\n", "")
		endif
	endif

	return l:dir

endfunction

" " map <F2> :call s:execute_on_writable(':call NERDTreeTlist()') <cr>
" Use this function to prevent CtrlP opening files inside non-writable buffers, e.g. NERDTree
function! boot#execute_on_writable(command)
	call s:to_writable()
	exec a:command
endfunction

function! boot#is_readonly(_winnr = winnr())
	let l:is_readonly = 0
	let bnum = winbufnr(a:_winnr)
	if bnum != -1
		\ && (getbufvar(bnum, '&buftype') !=# ''
		\ || getwinvar(a:_winnr, '&previewwindow'))
		\ && 0 == getbufvar(bnum, '&modifiable')
		let l:is_readonly = 1
	endif
	return l:is_readonly
endfunction

function! boot#to_readonly()
	let avalible_win_nr = winnr("$")
	let i = 1
	while i <= winnr("$")
		let bnum = winbufnr(i)
		if bnum != -1
			\ && (getbufvar(bnum, '&buftype') !=# ''
			\ || getwinvar(i, '&previewwindow'))
			\ && 0 == getbufvar(bnum, '&modifiable')
			let avalible_win_nr = i
			break
		endif

		let i += 1
	endwhile
	echo "avalible_win_nr = " . avalible_win_nr
	exec avalible_win_nr . 'wincmd w'
endfunction

function! boot#is_writable(_winnr = winnr())
	let l:is_writable = 0
	let bnum = winbufnr(a:_winnr)
	if bnum != -1
		\ && getbufvar(bnum, '&buftype') ==# ''
		\ && 1 == getbufvar(bnum, '&modifiable')
		\ && !getwinvar(a:_winnr, '&previewwindow')
		\ && (!getbufvar(bnum, '&modified') || &hidden)
		let l:is_writable = 1
	endif
	return l:is_writable
endfunction

function! boot#to_writable()
	let avalible_win_nr = 0
	let win_count = winnr('$')
	let i = 1
	while i <= win_count
		if boot#is_writable(i)
			let avalible_win_nr = i
			break
		endif
		let i += 1
	endwhile
	echo "avalible_win_nr = " . avalible_win_nr
	exec avalible_win_nr . 'wincmd w'
endfunction








" vim: set ts=4 sw=4 tw=78 noet :
" nvim: set ts=4 sw=4 tw=78 noet :
