#!/bin/sh
# TODO: configure sasl to write the data to some file under /tmp
script_dirname=`dirname $0`
script_dir=`(cd $script_dirname; pwd)`
filehost=`hostname | cut -d'.' -f1`

cd $script_dir

nodename=sponge_default
erlhost="127.0.0.1"
command="start"

is_started() {
    epmd -names 2>/dev/null | grep "^name $nodename[\t ]" >/dev/null
    return $?
}

compress_data() {
    find data -name $filehost-\* -size 0 -delete
    gzip -q data/$filehost-*
}

start() {
    if ! is_started; then
        compress_data
        exec erl -name "$nodename@$erlhost" \
            -noshell -noinput -detached \
            -pa ebin -pa deps/*/ebin \
            -boot start_sasl -s sponge
    else
        echo "Error: $nodename is already started!" >&2
        exit 1
    fi
}

start_interactive() {
    if ! is_started; then
        compress_data
        exec erl -name "$nodename@$erlhost" \
            -pa ebin -pa deps/*/ebin \
            -boot start_sasl
            -eval 'io:format("Type sponge:start(). to start.~n").'
    else
        echo "Error: $nodename is already started!" >&2
        exit 1
    fi
}

stop() {
    if is_started; then
        stopper_node="${nodename}_stopper@$erlhost"
        exec erl -name "$stopper_node" -noshell -noinput \
            -sasl errlog_type error \
            -pa ebin -pa deps/*/ebin \
            -boot start_sasl -s sponge stop "$nodename@$erlhost" -s erlang halt
    else
        echo "Error: $nodename is not started!" >&2
        exit 1
    fi
}

status() {
    if is_started; then
        echo "Sponge is started."
    else
        echo "Sponge is stopped."
    fi
}

if [ $# -gt 0 ]; then
    case "$1" in
        start|stop|status)
            command=$1
            ;;
        start-interactive)
            command="start_interactive"
            ;;
        *)
            echo "Error: invalid command $1." >&2
            exit 1
            ;;
    esac
fi

$command
