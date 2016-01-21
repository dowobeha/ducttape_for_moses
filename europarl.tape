task europarl_multi_test
     <  tarball="/projects/cl/data/europarl_v7.tgz"
     <  tools="/projects/cl/data/europarl_v7_tools.tgz"
     <  nonbreaking_dir="/projects/cl/local/moses-v3/scripts/share/nonbreaking_prefixes"
     :: src_lang=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
{
	# Print current date and time
	date

	# Extract tools to sentence-align the parallel corpus
	#
	tar --extract --verbose --gzip --file=${tools} sentence-align-corpus.perl tools/split-sentences.perl
	
	# Sentence alignment requires a list of non-breaking prefixes for each language.
	#
	mkdir tools/nonbreaking_prefixes

	# Moses maintains lists of non-breaking prefixes for many languages
	#
	#url="http://www.statmt.org/moses/RELEASE-3.0/binaries/linux-64bit/scripts/share/nonbreaking_prefixes"

	# Download the non-breaking prefixes for the source and target languages
	#
	#wget "${url}/nonbreaking_prefix.${src_lang}" && mv nonbreaking_prefix.${src_lang} tools/nonbreaking_prefixes
	#wget "${url}/nonbreaking_prefix.${tgt_lang}" && mv nonbreaking_prefix.${tgt_lang} tools/nonbreaking_prefixes
	if [ -f "${nonbreaking_dir}/nonbreaking_prefix.${src_lang}" ] ; then
		cp --verbose ${nonbreaking_dir}/nonbreaking_prefix.${src_lang} tools/nonbreaking_prefixes
	fi

	if [ -f "${nonbreaking_dir}/nonbreaking_prefix.${tgt_lang}" ] ; then
		cp --verbose "${nonbreaking_dir}/nonbreaking_prefix.${tgt_lang}" "tools/nonbreaking_prefixes"
	fi

	# If the non-breaking prefixes for a language doesn't exist,
	#    the tool falls back to the list of English non-breaking prefixes.
	#
	if [ ! -f "tools/nonbreaking_prefixes.en" ] && [ -f "${nonbreaking_dir}/nonbreaking_prefix.en" ]; then

	   # So, if we don't already have the list of English non-breaking prefixes, get it too
	   #
	   #wget "${url}/nonbreaking_prefix.en" && mv nonbreaking_prefix.en tools/nonbreaking_prefixes
	   cp --verbose ${nonbreaking_dir}/nonbreaking_prefix.en tools/nonbreaking_prefixes

	fi

	# Extract the raw data for the source and target languages
	#
	mkdir -p txt/${src_lang} txt/${tgt_lang}
	tar --extract         \
            --verbose         \
            --gzip            \
            --file=${tarball} \
            --to-command='iconv -f utf-8 -t utf-8 -c -o $TAR_FILENAME' \
            "txt/${src_lang}/ep-11-01-*.txt" \
            "txt/${src_lang}/ep-11-02-*.txt" \
            "txt/${src_lang}/ep-11-03-*.txt" \
            "txt/${tgt_lang}/ep-11-01-*.txt" \
            "txt/${tgt_lang}/ep-11-02-*.txt" \
            "txt/${tgt_lang}/ep-11-03-*.txt"

	# Examine the document-aligned parallel data,
	#   and construct a new version that is also aligned at the sentence level.
	#
	# The resulting document-aligned, sentence-aligned files will be located in the ./aligned directory
	#
	./sentence-align-corpus.perl ${src_lang} ${tgt_lang}

	# Print current date and time
	date

	# Delete the raw and intermediate data for the source and target languages
#	rm -rf ./txt ./aligned

	# Print current date and time
#	date

}


task europarl 
     <  tarball="/projects/cl/data/europarl_v7.tgz"
     <  tools="/projects/cl/data/europarl_v7_tools.tgz"
     <  nonbreaking_dir="/projects/cl/local/moses-v3/scripts/share/nonbreaking_prefixes"
     :: src_lang=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     >  src
     >  tgt
{
	# Print current date and time
	date

	# Extract tools to sentence-align the parallel corpus
	#
	tar --extract --verbose --gzip --file=${tools} sentence-align-corpus.perl tools/split-sentences.perl
	
	# Sentence alignment requires a list of non-breaking prefixes for each language.
	#
	mkdir tools/nonbreaking_prefixes

	# Moses maintains lists of non-breaking prefixes for many languages
	#
	#url="http://www.statmt.org/moses/RELEASE-3.0/binaries/linux-64bit/scripts/share/nonbreaking_prefixes"

	# Download the non-breaking prefixes for the source and target languages
	#
	#wget "${url}/nonbreaking_prefix.${src_lang}" && mv nonbreaking_prefix.${src_lang} tools/nonbreaking_prefixes
	#wget "${url}/nonbreaking_prefix.${tgt_lang}" && mv nonbreaking_prefix.${tgt_lang} tools/nonbreaking_prefixes
	if [ -f "${nonbreaking_dir}/nonbreaking_prefix.${src_lang}" ] ; then
		cp --verbose ${nonbreaking_dir}/nonbreaking_prefix.${src_lang} tools/nonbreaking_prefixes
	fi

	if [ -f "${nonbreaking_dir}/nonbreaking_prefix.${tgt_lang}" ] ; then
		cp --verbose "${nonbreaking_dir}/nonbreaking_prefix.${tgt_lang}" "tools/nonbreaking_prefixes"
	fi

	# If the non-breaking prefixes for a language doesn't exist,
	#    the tool falls back to the list of English non-breaking prefixes.
	#
	if [ ! -f "tools/nonbreaking_prefixes.en" ] && [ -f "${nonbreaking_dir}/nonbreaking_prefix.en" ]; then

	   # So, if we don't already have the list of English non-breaking prefixes, get it too
	   #
	   #wget "${url}/nonbreaking_prefix.en" && mv nonbreaking_prefix.en tools/nonbreaking_prefixes
	   cp --verbose ${nonbreaking_dir}/nonbreaking_prefix.en tools/nonbreaking_prefixes

	fi

	# Extract the raw data for the source and target languages
	#
	tar --extract --verbose --gzip --file=${tarball} --to-command='iconv -f utf-8 -t utf-8 -c -o $TAR_FILENAME' txt/${src_lang} txt/${tgt_lang}

	# Examine the document-aligned parallel data,
	#   and construct a new version that is also aligned at the sentence level.
	#
	# The resulting document-aligned, sentence-aligned files will be located in the ./aligned directory
	#
	./sentence-align-corpus.perl ${src_lang} ${tgt_lang}


	# Concatenate the sentence-aligned source files into a single file
	#         and the sentence-aligned target files into a single file.
	#
	# Explicitly exclude any files from the 4th quarter of 2000,
	#         because that data is reserved for testing.
	#
	ls -1 --directory ./aligned/${src_lang}-${tgt_lang}/${src_lang}/* | grep -v "ep-00-1[012]-*.txt" | xargs cat > ${src}
	ls -1 --directory ./aligned/${src_lang}-${tgt_lang}/${tgt_lang}/* | grep -v "ep-00-1[012]-*.txt" | xargs cat > ${tgt}

	# Print current date and time
	date

	# Delete the raw and intermediate data for the source and target languages
#	rm -rf ./txt ./aligned

	# Print current date and time
#	date

}

task europarl_mono
     <  tarball="/projects/cl/data/europarl_v7.tgz"
     <  tools="/projects/cl/data/europarl_v7_tools.tgz"
     <  nonbreaking_dir="/projects/cl/local/moses-v3/scripts/share/nonbreaking_prefixes"
     :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     >  tgt
{
	# Print current date and time
	date

	# Extract tools to sentence-align the parallel corpus
	#
	tar --extract --verbose --gzip --file=${tools} tools/split-sentences.perl
	
	# Sentence alignment requires a list of non-breaking prefixes for each language.
	#
	mkdir tools/nonbreaking_prefixes

	if [ -f "${nonbreaking_dir}/nonbreaking_prefix.${tgt_lang}" ] ; then
		cp --verbose "${nonbreaking_dir}/nonbreaking_prefix.${tgt_lang}" "tools/nonbreaking_prefixes"
	fi

	# If the non-breaking prefixes for a language doesn't exist,
	#    the tool falls back to the list of English non-breaking prefixes.
	#
	if [ ! -f "tools/nonbreaking_prefixes.en" ] && [ -f "${nonbreaking_dir}/nonbreaking_prefix.en" ]; then

	   # So, if we don't already have the list of English non-breaking prefixes, get it too
	   #
	   cp --verbose ${nonbreaking_dir}/nonbreaking_prefix.en tools/nonbreaking_prefixes

	fi

	# Extract the raw data for the source and target languages
	#
	mkdir -p txt/${tgt_lang}
	tar --extract --verbose --gzip --file=${tarball} --to-command='iconv -f utf-8 -t utf-8 -c -o $TAR_FILENAME' txt/${tgt_lang}


	# Concatenate the sentence-aligned source files into a single file
	#         and the sentence-aligned target files into a single file.
	#
	# Explicitly exclude any files from the 4th quarter of 2000,
	#         because that data is reserved for testing.
	#
#	ls -1 --directory txt/${tgt_lang}/* | grep -v "ep-00-1[012]-*.txt" | xargs cat | ./tools/split-sentences.perl -l ${tgt_lang} | grep -v "^\s*<" | grep -v '^\s*$' > ${tgt}

	mkdir sents
	for i in $(cd txt/${tgt_lang} ; ls -1 *.txt); do
	    ./tools/split-sentences.perl -l ${tgt_lang} < txt/${tgt_lang}/${i} > sents/${i}
	done


	# Print current date and time
	date

	# Delete the raw and intermediate data for the source and target languages
#	rm -rf ./txt

	# Print current date and time
#	date

}



func tokenize
     < script
     <  in
     :: language
     :: threads
     >  out
{
	date

	${script} -l ${language} -threads ${threads} < ${in} > ${out}

	date
}

func lowercase
     < script
     < in
     > out
{
	date

	${script} < ${in} > ${out}

	date
}

task tokenize_src calls tokenize 
     <  script="/projects/cl/local/moses-v3/scripts/tokenizer/tokenizer.perl"
     <  in=$src@europarl
     :: language=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: threads=1
     >  out

task tokenize_tgt calls tokenize 
     <  script="/projects/cl/local/moses-v3/scripts/tokenizer/tokenizer.perl"
     <  in=$tgt@europarl
     :: language=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: threads=1
     >  out

task tokenize_tgt_mono calls tokenize 
     <  script="/projects/cl/local/moses-v3/scripts/tokenizer/tokenizer.perl"
     <  in=$tgt@europarl_mono
     :: language=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: threads=1
     >  out


task lowercase_src calls lowercase
     < script="/projects/cl/local/moses-v3/scripts/tokenizer/lowercase.perl"
     < in=$out@tokenize_src
     > out

task lowercase_tgt calls lowercase
     < script="/projects/cl/local/moses-v3/scripts/tokenizer/lowercase.perl"
     < in=$out@tokenize_tgt
     > out

task lowercase_tgt_mono calls lowercase
     < script="/projects/cl/local/moses-v3/scripts/tokenizer/lowercase.perl"
     < in=$out@tokenize_tgt_mono
     > out


plan {

#     reach europarl_multi_test via (src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: en)

 reach europarl_mono via (tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)


#     reach europarl via (src: ro) * (tgt: pl)    

#     reach lowercase_src via (src: ro) * (tgt: pl)
#     reach lowercase_tgt via (src: ro) * (tgt: pl)
#     reach lowercase_tgt_mono via (src: ro) * (tgt: pl)

#     reach europarl via (src: fi) * (tgt: en)
#     reach europarl via (src: ro) * (tgt: en)

}
