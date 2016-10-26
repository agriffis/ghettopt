example.bash: ghettopt.bash getopt.bash
	./make.bash > example.bash.new && mv example.bash.new example.bash

getopt.bash:
	curl -O https://raw.githubusercontent.com/agriffis/pure-getopt/master/getopt.bash

clean:
	rm getopt.bash

.PHONY: clean
