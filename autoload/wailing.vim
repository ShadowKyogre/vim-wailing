function! wailing#start()
	if !exists("b:is_typing")
		let b:old_is_typing = 1
	else
		let b:old_is_typing = b:is_typing
	endif
	let b:is_typing = 0
	if b:old_is_typing != b:is_typing
		if exists("g:wailing_alert_fpath")
			if !exists("b:alarm_socket")
				let b:alarm_socket = tempname()
				call system("mpv --loop " . shellescape(g:wailing_alert_fpath) . " --input-unix-socket " . shellescape(b:alarm_socket) . " &" )
			else
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
		if exists('b:alarm_socket')
			call system("socat - " . shellescape(b:alarm_socket), "stop\n")
		endif
		autocmd! Wailing * <buffer>
	else
		if !empty(getbufvar(str2nr(expand('<abuf>')), 'alarm_socket'))
			let barm_socket = getbufvar(str2nr(expand('<abuf>')), 'alarm_socket')
			call system("socat - " . shellescape(barm_socket), "stop\n")
		endif
		autocmd! Wailing * <buffer=abuf>
	endif
endfunction

function! wailing#setup()
	augroup Wailing
		autocmd! * <buffer>
		autocmd CursorHoldI <buffer> call wailing#start()
		autocmd TextChangedI <buffer> call wailing#stop()
		autocmd BufUnload <buffer> call wailing#teardown(0)
	augroup END
endfunction
