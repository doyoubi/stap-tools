stap_file="um_func.stp"
binary="/srv/searedis/bin/server_proxy"

echo 'probe begin { println("start") }' > $stap_file
echo 'global stats' >> $stap_file

nm $binary | awk '{print $3}' | grep undermoon | xargs -L 1 printf 'probe process("%s").function("%s").return {
	latency = gettimeofday_ns() - @entry(gettimeofday_ns())
	if (latency > 10000) {
		stats[probefunc()] <<< latency
	}
}\n' ${binary} >> $stap_file

echo 'probe end {
	println("end")
	foreach([funcname] in stats) {
    		printf("%s %d\n", funcname, @avg(stats[funcname]))
		print(@hist_linear(stats[funcname], 0, 1000000, 10000))
	}
}' >> $stap_file
