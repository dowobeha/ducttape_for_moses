

func extract_europarl
     < tarball
     < tools_tarball
     < nonbreaking_prefixes
     :: src_lang
     :: tgt_lang
     :: dev
     :: devtest
     :: test
      > train_src
      > train_tgt
      > dev_src
      > dev_tgt
      > devtest_src
      > devtest_tgt
      > test_src
      > test_tgt
{
	date +"Begin %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp

	# Extract tools to sentence-align the parallel corpus
	#
	tar --extract --verbose --gzip --file=${tools_tarball} sentence-align-corpus.perl tools/split-sentences.perl
	
	# Sentence alignment requires a list of non-breaking prefixes for each language.
	#
	mkdir tools/nonbreaking_prefixes

	if [ -f "${nonbreaking_prefixes}/nonbreaking_prefix.${src_lang}" ] ; then
		cp --verbose "${nonbreaking_prefixes}/nonbreaking_prefix.${src_lang}" "tools/nonbreaking_prefixes"
	fi

	if [ -f "${nonbreaking_prefixes}/nonbreaking_prefix.${tgt_lang}" ] ; then
		cp --verbose "${nonbreaking_prefixes}/nonbreaking_prefix.${tgt_lang}" "tools/nonbreaking_prefixes"
	fi

	# If the non-breaking prefixes for a language doesn't exist,
	#    the tool falls back to the list of English non-breaking prefixes.
	#
	if [ ! -f "tools/nonbreaking_prefixes.en" ] && [ -f "${nonbreaking_prefixes}/nonbreaking_prefix.en" ]; then

	   # So, if we don't already have the list of English non-breaking prefixes, get it too
	   cp --verbose "${nonbreaking_prefixes}/nonbreaking_prefix.en" "tools/nonbreaking_prefixes"

	fi

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
	    ln --verbose $(pwd)/sentence-align-corpus.perl $(pwd)/${d}/sentence-align-corpus.perl
	    ln --verbose -s $(pwd)/tools $(pwd)/${d}/
	    (cd ${d} && ./sentence-align-corpus.perl ${src_lang} ${tgt_lang})

	done
	
	# Sentence align the training data
	date +"Sentence aligning training data for ${src_lang}-${tgt_lang} %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
	./sentence-align-corpus.perl ${src_lang} ${tgt_lang}

	# Concatenate the sentence-aligned source files into a single file
	#         and the sentence-aligned target files into a single file.
	#
	# Training
	ls -1 --directory ./aligned/${src_lang}-${tgt_lang}/${src_lang}/* | xargs cat | grep -v "^<" > ${train_src}
	ls -1 --directory ./aligned/${src_lang}-${tgt_lang}/${tgt_lang}/* | xargs cat | grep -v "^<" > ${train_tgt}
	#
	# Dev (tuning)
	ls -1 --directory dev/aligned/${src_lang}-${tgt_lang}/${src_lang}/* | xargs cat | grep -v "^<" > ${dev_src}
	ls -1 --directory dev/aligned/${src_lang}-${tgt_lang}/${tgt_lang}/* | xargs cat | grep -v "^<" > ${dev_tgt}
	#
	# Dev-test
	ls -1 --directory devtest/aligned/${src_lang}-${tgt_lang}/${src_lang}/* | xargs cat | grep -v "^<" > ${devtest_src}
	ls -1 --directory devtest/aligned/${src_lang}-${tgt_lang}/${tgt_lang}/* | xargs cat | grep -v "^<" > ${devtest_tgt}
	#
	# Test
	ls -1 --directory test/aligned/${src_lang}-${tgt_lang}/${src_lang}/* | xargs cat | grep -v "^<" > ${test_src}
	ls -1 --directory test/aligned/${src_lang}-${tgt_lang}/${tgt_lang}/* | xargs cat | grep -v "^<" > ${test_tgt}

	# Clean up
	date +"Remove dev/ %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
	rm -rf dev

	date +"Remove devtest/ %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
	rm -rf devtest

	date +"Remove test/ %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
	rm -rf test

	date +"Remove txt/ %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
	rm -rf txt

	date +"Remove aligned/ %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp
	rm -rf aligned

	date +"End %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp

}



func extract_europarl_monolingual
     < tarball
     < tools_tarball
     < nonbreaking_prefixes
     :: dev
     :: devtest
     :: test
     :: tgt_lang
      > tgt
{
	date +"Begin %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp

	# Extract tools to sentence-align the parallel corpus
	#
	tar --extract --verbose --gzip --file=${tools_tarball} sentence-align-corpus.perl tools/split-sentences.perl
	
	# Sentence alignment requires a list of non-breaking prefixes for each language.
	#
	mkdir tools/nonbreaking_prefixes

	if [ -f "${nonbreaking_prefixes}/nonbreaking_prefix.${tgt_lang}" ] ; then
		cp --verbose "${nonbreaking_prefixes}/nonbreaking_prefix.${tgt_lang}" "tools/nonbreaking_prefixes"
	fi

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

	date +"End %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp

}

