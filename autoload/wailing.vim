if !exists('s:wailing_did_init')
	let s:timeout_cmd = expand("<sfile>:p:h") . '/wailing_timeout.sh'
	let s:wailing_did_init = 1
endif

function! s:WailingStart()
	if !exists("b:is_typing")
		let b:old_is_typing = 1
	else
		let b:old_is_typing = b:is_typing
	endif

	let b:is_typing = 0

	if b:old_is_typing != b:is_typing
		if has_key(g:wailing_opts['alert'], 'fpath')
			let mpv_status = <SID>SocatWrapper('{"command": ["get_property", "pause"]}')
			echom '|' . mpv_status . '|'

			if empty(mpv_status) || mpv_status =~ 'Connection refused'
				call <SID>PlayMPV(g:wailing_opts['alert'], b:alarm_socket, 1)
			elseif mpv_status =~ '"data":true'
				call <SID>SocatWrapper("no-osd set playback-time 0\n")
				call <SID>SocatWrapper("no-osd set pause no\n")
			endif
		endif
		" echom "You're not typing!"
	endif
endfunction

function! s:SocatWrapper(cmd, ...)
	let socket = ''

	if a:0 > 0
		let socket = a:1
	else
		let socket = b:alarm_socket
	endif

	return system(
		\ "socat - " . shellescape(socket),
		\ a:cmd)
endfunction

function! s:PlayMPV(opts, socket, loop, ...)
	let cmd_args = ['mpv']

	call add(cmd_args, printf('--input-ipc-server=%s', a:socket))

	if a:loop == 1
		call add(cmd_args, '--loop')
	endif

	if has_key(a:opts, 'fpath')
		call add(cmd_args, fnamemodify(a:opts['fpath'], ':p'))
	endif

	if has_key(a:opts, 'start')
		call add(cmd_args, printf('--start=%f', a:opts['start']) )
	endif

	if has_key(a:opts, 'length')
		call add(cmd_args, printf('--length=%f', a:opts['length']) )
	endif

	let job = job_start(cmd_args)

	return job
endfunction

function! s:WailReward(...)
	call <SID>SocatWrapper("stop\n")
	call <SID>PlayMPV(g:wailing_opts['award'], b:alarm_socket, 0)
endfunction

function! s:WailingRewardSetup(time_as_secs)
	let RewardCB = function('s:WailReward', [])
	let timer_id = timer_start(a:time_as_secs * 1000, RewardCB)
	let b:wail_timer_id = -1
endfunction

function! s:WailingStop()
	if !exists("b:is_typing")
		let b:is_typing = 1
	endif
	if !b:is_typing
		let b:is_typing = 1
		if exists('b:alarm_socket')
			call SocatWrapper("no-osd set pause yes\n")
		endif
		" echom "You're typing!"
	endif
endfunction

function! wailing#teardown(manual)
	if a:manual
		if exists('b:wail_timer_id') && b:wail_timer_id != -1
			call timer_stop(b:wail_timer_id)
			let b:wail_timer_id = -1
		endif
		if exists('b:alarm_socket')
			call <SID>SocatWrapper("stop\n")
		endif
		autocmd! Wailing * <buffer>
	else
		let curbuf = str2nr(expand('<abuf>'))
		let wail_timer_id = getbufvar(curbuf, 'wail_timer_id', -1)
		if wail_timer_id != -1
			call timer_stop(wail_timer_id)
			call setbufvar(curbuf, 'wail_timer_id', -1)
		endif
		if !empty(getbufvar(str2nr(expand('<abuf>')), 'alarm_socket'))
			let barm_socket = getbufvar(str2nr(expand('<abuf>')), 'alarm_socket')
			call <SID>SocatWrapper("stop\n", barm_socket)
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
			let time_as_secs = str2nr(clock_parts[0]) * 3600
				\ + str2nr(clock_parts[1]) * 60
				\ + str2nr(clock_parts[2])
		else
			let time_as_secs = 0
		endif

		if time_as_secs > 0
			call <SID>WailingRewardSetup(time_as_secs)
		else
			let b:wail_timer_id = -1
		endif
	else
		let b:wail_timer_id = -1
	endif
	
	if exists('b:alarm_socket')
		if b:wail_timer_id != -1
			call timer_stop(b:wail_timer_id)
		endif
		call <SID>SocatWrapper("stop\n")
	endif

	let b:is_typing = 1
	let b:old_is_typing = 1

	augroup Wailing
		autocmd! * <buffer>
		autocmd CursorHoldI <buffer> call <SID>WailingStart()
		autocmd TextChangedI <buffer> call <SID>WailingStop()
		autocmd BufUnload <buffer> call wailing#teardown(0)
	augroup END
endfunction
