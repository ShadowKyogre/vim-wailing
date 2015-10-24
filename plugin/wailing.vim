command! -nargs=0 SetupWailing call wailing#setup(<f-args>)
command! -nargs=1 SetupWailingTimed call wailing#setup(<f-args>)
command! -nargs=0 TeardownWailing call wailing#teardown(1)
