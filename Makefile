target= klop-unstabled

bin/$(target).love:
	7z a bin/$(target).zip ./src/* ./src/.[!.]*
	mv bin/$(target).zip bin/$(target).love
win32: bin/$(target)_win32.zip
bin/$(target)_win32.zip: bin/$(target).love
	mkdir -p bin/$(target)_win32
	cat lib/love.exe bin/$(target).love > bin/$(target)_win32/$(target).exe
	cp lib/* bin/$(target)_win32
	rm bin/$(target)_win32/love.exe
	7z a bin/$(target)_win32.zip ./bin/$(target)_win32
	rm -rf bin/$(target)_win32

run: bin/$(target).love
	love bin/$(target).love
clean:
	rm -rf bin/*
