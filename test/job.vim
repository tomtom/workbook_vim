let cmd = "bash"
let job = job_start(cmd, {'in_mode': 'raw', 'out_mode': 'raw'})
let ch = job_getchannel(job)

" finish

let r = ch_evalraw(ch, "ls\n")
echom 1 string(split(r, "\n"))

let r = ch_evalraw(ch, "sleep 10s && ls\n")
echom 2 string(split(r, "\n"))

call job_stop(job)
sleep 1
echom job_status(job)

