build:
	docker build -t hugo/andrelousamarques:v1 . 

sh:
	docker run --rm -it -w /work_area -v $(PWD):/work_area hugo/andrelousamarques:v1 bash

run:
	docker run --rm -it -p 1313:1313 -w /work_area -v $(PWD)/andrelousamarques:/work_area hugo/andrelousamarques:v1 hugo serve --bind=0.0.0.0

build-site:
	docker run --rm -it -p 1313:1313 -w /work_area -v $(PWD)/andrelousamarques:/work_area hugo/andrelousamarques:v1  hugo --minify

