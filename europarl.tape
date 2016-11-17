

func extract_europarl_test
     < tarball
     < sentence_aligner
     :: nonbreaking_prefixes
     :: src_lang
     :: tgt_lang
      > src
      > tgt
{
	date +"Begin %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp

	# Extract tools to sentence-align the parallel corpus
	#
	wget "${tools_url}" --output-document=tools.tgz
	tar --extract --verbose --gzip --file=tools.tgz sentence-align-corpus.perl tools/split-sentences.perl
	
	# Sentence alignment requires a list of non-breaking prefixes for each language.
	#
	mkdir tools/nonbreaking_prefixes

	if [ -f "${nonbreaking_prefixes}/nonbreaking_prefix.${src_lang}" ] ; then
		cp --verbose "${nonbreaking_dir}/nonbreaking_prefix.${src_lang}" "tools/nonbreaking_prefixes"
	fi

	if [ -f "${nonbreaking_prefixes}/nonbreaking_prefix.${tgt_lang}" ] ; then
		cp --verbose "${nonbreaking_dir}/nonbreaking_prefix.${tgt_lang}" "tools/nonbreaking_prefixes"
	fi

	# If the non-breaking prefixes for a language doesn't exist,
	#    the tool falls back to the list of English non-breaking prefixes.
	#
	if [ ! -f "tools/nonbreaking_prefixes.en" ] && [ -f "${nonbreaking_prefixes}/nonbreaking_prefix.en" ]; then

	   # So, if we don't already have the list of English non-breaking prefixes, get it too
	   cp --verbose "${nonbreaking_dir}/nonbreaking_prefix.en" "tools/nonbreaking_prefixes"

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


	# Concatenate the sentence-aligned source files into a single file
	#         and the sentence-aligned target files into a single file.
	#
	ls -1 --directory ./aligned/${src_lang}-${tgt_lang}/${src_lang}/* | xargs cat > ${src}
	ls -1 --directory ./aligned/${src_lang}-${tgt_lang}/${tgt_lang}/* | xargs cat > ${tgt}

	date +"End %Y-%m-%d %H:%M:%S.%m %z" # Print timestamp

}

