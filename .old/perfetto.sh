#!/bin/bash


adb shell   perfetto        \
                -c      -       --txt   \
                -o      /data/misc/perfetto-traces/trace        \
<<EOF
buffers: {
    size_kb:    63488
    fill_policy: DISCARD
}
buffers: {
   size_kb:     2048
   fill_policy: DISCARD
}
data_sources:   {
    config      {
        name:   "linux.ftrace"
        ftrace_config   {
                ftrace_events: "raw_syscalls/sys_enter"
                ftrace_events: "raw_syscalls/sys_exit"

        }
    }
}
duration_ms:    1000000
EOF


adb  pull    /data/misc/perfetto-traces/trace ./perf_trace
./traceconv text perf_trace perf.text
