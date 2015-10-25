if !exists('s:wailing_did_init')
	let s:timeout_cmd = expand("<sfile>:p:h") . '/wailing_timeout.sh'
	let s:wailing_did_init = 1
endif

function! wailing#start()
	if !exists("b:is_typing")
		let b:old_is_typing = 1
	else
		let b:old_is_typing = b:is_typing
	endif
	let b:is_typing = 0
	if b:old_is_typing != b:is_typing
		if exists("g:wailing_alert_fpath")
			let mpv_status = system("socat - " . shellescape(b:alarm_socket), 
							 \ '{"command": ["get_property", "pause"]}')
			echom '|' . mpv_status . '|'
			if empty(mpv_status) || mpv_status =~ 'Connection refused'
				call system("mpv --loop " . shellescape(fnamemodify(g:wailing_alert_fpath, ':p'))
				\ . " --input-unix-socket " . shellescape(b:alarm_socket) . " &" )
			elseif mpv_status =~ '"data":true'
				call system("socat - " . shellescape(b:alarm_socket), "no-osd set playback-time 0\n")
				call system("socat - " . shellescape(b:alarm_socket), "no-osd set pause no\n")
			endif
		endif
		" echom "You're not typing!"
	endif
endfunction

function! wailing#stop()
	if !exists("b:is_typing")
		let b:is_typing = 1
	endif
	if !b:is_typing
		let b:is_typing = 1
		if exists('b:alarm_socket')
			call system("socat - " . shellescape(b:alarm_socket), "no-osd set pause yes\n")
		endif
		" echom "You're typing!"
	endif
endfunction

function! wailing#teardown(manual)
	if a:manual
		if b:timeout_pid != -1
			call system("kill " . b:timeout_pid)
			let b:timeout_pid = -1
		endif
		if exists('b:alarm_socket')
			call system("socat - " . shellescape(b:alarm_socket), "stop\n")
		endif
		autocmd! Wailing * <buffer>
	else
		let curbuf = str2nr(expand('<abuf>'))
		let timeout_pid = getbufvar(curbuf, 'timeout_pid', -1)
		if timeout_pid != -1
			call system("kill " . b:timeout_pid)
			call setbufvar(curbuf, 'timeout_pid', -1)
		endif
		if !empty(getbufvar(str2nr(expand('<abuf>')), 'alarm_socket'))
			let barm_socket = getbufvar(str2nr(expand('<abuf>')), 'alarm_socket')
			call system("socat - " . shellescape(barm_socket), "stop\n")
		endif
		autocmd! Wailing * <buffer=abuf>
	endif
endfunction

function! wailing#setup(...)
	if !exists('b:alarm_socket')
		let b:alarm_socket = tempname()
	endif
	if a:0 > 0 && match(a:1, '\v^%(\d{1,2}:\d{2}:\d{2}|\d{1,2}:\d{2}|\d+)$') != -1
		let clock_parts = split(a:1, ':')
		let len_clock_parts = len(clock_parts)
		if len_clock_parts == 1
			let time_as_secs = str2nr(clock_parts[0])
		elseif len_clockparts == 2
			let time_as_secs = str2nr(clock_parts[0]) * 60 + str2nr(clock_parts[1])
		elseif len_clockparts == 3
			let time_as_secs = str2nr(clock_parts[0]) * 3600 + str2nr(clock_parts[1]) * 60 + str2nr(clock_parts[2])
		else
			let time_as_secs = 0
		endif
		if time_as_secs > 0
			let b:timeout_pid = system(s:timeout_cmd . ' ' . time_as_secs
			                    \ . ' ' . shellescape(b:alarm_socket) . ' &')
		else
			let b:timeout_pid = -1
		endif
	else
		let b:timeout_pid = -1
	endif
	
	let b:is_typing = 1
	let b:old_is_typing = 1
	
	augroup Wailing
		autocmd! * <buffer>
		autocmd CursorHoldI <buffer> call wailing#start()
		autocmd TextChangedI <buffer> call wailing#stop()
		autocmd BufUnload <buffer> call wailing#teardown(0)
	augroup END
endfunction
