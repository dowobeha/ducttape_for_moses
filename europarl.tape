

func extract_europarl
     < tarball
     :: src_lang
     :: tgt_lang
     :: dev
     :: devtest
     :: test
     :: num_threads
      > train_src
      > train_tgt
      > dev_src
      > dev_tgt
      > devtest_src
      > devtest_tgt
      > test_src
      > test_tgt
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	set -o xtrace

	# Get tools to sentence-align the parallel corpus
	#
	git clone https://github.com/dowobeha/europarl_tools.git

	mv europarl_tools/sentence-align-corpus.perl .
	mv europarl_tools/tools .

	# Extract the raw data for the source and target languages
	#
	echo "Extracting raw data for the source and target languages from ${tarball}"
	mkdir -p txt/${src_lang} txt/${tgt_lang}
	tar --extract         \
            --verbose         \
            --gzip            \
            --wildcards       \
            --file=${tarball} \
            --to-command='iconv -f utf-8 -t utf-8 -c -o $TAR_FILENAME' \
            txt/${src_lang} \
            txt/${tgt_lang}



	for d in dev devtest test; do

    	    files=$(eval echo \$$d)

	    for lang in ${src_lang} ${tgt_lang}; do
	    	mkdir -p ${d}/txt/${lang}
	      
		date +"Gathering ${d} for ${src_lang}-${tgt_lang} %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp

		for file in ${files}; do
		    mv --verbose txt/${lang}/${file} ${d}/txt/${lang}/
		done
		
	    done

	    # Examine the document-aligned parallel data,
            #   and construct a new version that is also aligned at the sentence level.
	    #
            # The resulting document-aligned, sentence-aligned files will be located in the ${d}/aligned directory
	    #
	    date +"Sentence aligning ${d} data for ${src_lang}-${tgt_lang} %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
	    
	    # sentence-align-corpus.perl performs chdir($Bin), so it needs to be located in the same dir as txt
	    ln --verbose -s $(pwd)/sentence-align-corpus.perl $(pwd)/${d}/sentence-align-corpus.perl
	    ln --verbose -s $(pwd)/tools $(pwd)/${d}/
	    (cd ${d} && ./sentence-align-corpus.perl ${src_lang} ${tgt_lang} ${num_threads})

	done
	
	# Sentence align the training data
	date +"Sentence aligning training data for ${src_lang}-${tgt_lang} %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
	./sentence-align-corpus.perl ${src_lang} ${tgt_lang} ${num_threads}

	# Concatenate the sentence-aligned source files into a single file
	#         and the sentence-aligned target files into a single file.
	#
	# Training
	cat ./aligned/${src_lang}-${tgt_lang}/${src_lang}/* | ./tools/split-sentences.perl -l ${src_lang} > train.${src_lang}
	cat ./aligned/${src_lang}-${tgt_lang}/${tgt_lang}/* | ./tools/split-sentences.perl -l ${tgt_lang} > train.${tgt_lang}
	./tools/de-xml.perl train ${src_lang} ${tgt_lang} train.noxml
	ln train.noxml.${src_lang} ${train_src}
	ln train.noxml.${tgt_lang} ${train_tgt}
	if [[ "$(wc -l ${train_src} | cut -f 1 -d ' ')" -ne "$(wc -l ${train_tgt} | cut -f 1 -d ' ')" ]]; then
	   (1>&2 echo "File lengths differ: ${train_src} and ${train_tgt}" && wc -l ${train_src} ${train_tgt} && exit -1) ;
	fi
        #
	# Dev (tuning)
	cat dev/aligned/${src_lang}-${tgt_lang}/${src_lang}/* | ./tools/split-sentences.perl -l ${src_lang} > dev.${src_lang}
	cat dev/aligned/${src_lang}-${tgt_lang}/${tgt_lang}/* | ./tools/split-sentences.perl -l ${tgt_lang} > dev.${tgt_lang}
	./tools/de-xml.perl dev ${src_lang} ${tgt_lang} dev.noxml
	ln dev.noxml.${src_lang} ${dev_src}
	ln dev.noxml.${tgt_lang} ${dev_tgt}
	if [[ "$(wc -l ${dev_src} | cut -f 1 -d ' ')" -ne "$(wc -l ${dev_tgt} | cut -f 1 -d ' ')" ]]; then
	   (1>&2 echo "File lengths differ: ${dev_src} and ${dev_tgt}" && wc -l ${dev_src} ${dev_tgt} && exit -1) ;
	fi
        #
	# Dev-test
	cat devtest/aligned/${src_lang}-${tgt_lang}/${src_lang}/* | ./tools/split-sentences.perl -l ${src_lang} > devtest.${src_lang}
	cat devtest/aligned/${src_lang}-${tgt_lang}/${tgt_lang}/* | ./tools/split-sentences.perl -l ${tgt_lang} > devtest.${tgt_lang}
	./tools/de-xml.perl devtest ${src_lang} ${tgt_lang} devtest.noxml
	ln devtest.noxml.${src_lang} ${devtest_src}
	ln devtest.noxml.${tgt_lang} ${devtest_tgt}
	if [[ "$(wc -l ${devtest_src} | cut -f 1 -d ' ')" -ne "$(wc -l ${devtest_tgt} | cut -f 1 -d ' ')" ]]; then
	   (1>&2 echo "File lengths differ: ${devtest_src} and ${devtest_tgt}" && wc -l ${devtest_src} ${devtest_tgt} && exit -1) ;
	fi
	#
	# Test
	cat test/aligned/${src_lang}-${tgt_lang}/${src_lang}/* | ./tools/split-sentences.perl -l ${src_lang} > test.${src_lang}
	cat test/aligned/${src_lang}-${tgt_lang}/${tgt_lang}/* | ./tools/split-sentences.perl -l ${tgt_lang} > test.${tgt_lang}
	./tools/de-xml.perl test ${src_lang} ${tgt_lang} test.noxml
	ln test.noxml.${src_lang} ${test_src}
	ln test.noxml.${tgt_lang} ${test_tgt}
	if [[ "$(wc -l ${test_src} | cut -f 1 -d ' ')" -ne "$(wc -l ${test_tgt} | cut -f 1 -d ' ')" ]]; then
	   (1>&2 echo "File lengths differ: ${test_src} and ${test_tgt}" && wc -l ${test_src} ${test_tgt} && exit -1) ;
	fi


	# Clean up
#	date +"Remove dev/ %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
#	rm -rf dev

#	date +"Remove devtest/ %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
#	rm -rf devtest

#	date +"Remove test/ %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
#	rm -rf test

#	date +"Remove txt/ %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
#	rm -rf txt

#	date +"Remove aligned/ %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
#	rm -rf aligned

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}



func extract_europarl_monolingual
     < tarball
     :: dev
     :: devtest
     :: test
     :: tgt_lang
      > tgt
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	# Get tools to sentence-align the parallel corpus
	#
	# git clone https://github.com/dowobeha/europarl_tools.git .	

	# Extract the raw data for the target language
	#
	echo "Extracting raw data for the target language from ${tarball}"
	mkdir -p txt/${tgt_lang}
	tar --extract         \
            --verbose         \
            --gzip            \
            --wildcards       \
            --file=${tarball} \
            --to-command='iconv -f utf-8 -t utf-8 -c -o $TAR_FILENAME' \
            txt/${tgt_lang}
            
	for file in $(echo ${dev} ${devtest} ${test}); do
	    echo ${file} >> exclude.txt
	done 

	# Concatenate the target files into a single file.
	#
	# Explicitly exclude any dev, devtest, and testing data files.
	#
	ls -1 --directory txt/${tgt_lang}/* | grep --file=exclude.txt -v | xargs cat | grep -v "^<" > ${tgt}

	date +"Remove txt/ %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
	rm -rf txt

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}

