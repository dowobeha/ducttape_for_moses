
func moses_extract_phrases
     < moses_extract
     < moses_extract_parallel_script
     < src_corpus
     < tgt_corpus
     < alignment_file
     :: num_cores
     :: sort_buffer_size
     < split_exec
     < sort_exec
     < sort_compress
     :: max_phrase_length
     > phrases_forward_gz
     > phrases_reverse_gz
     > phrases_ordering_gz
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	output_file_prefix="$(pwd)/extract"

	set -o xtrace

	${moses_extract_parallel_script} \
	                           ${num_cores}  \
	                           ${split_exec} \
				   "${sort_exec} -S ${sort_buffer_size} --compress-program ${sort_compress}" \
				   ${moses_extract} \
				   ${tgt_corpus} \
				   ${src_corpus} \
				   ${alignment_file} \
				   ${output_file_prefix} \
				   ${max_phrase_length}  \
				   orientation \
				   --model wbe-msd \
				   --GZOutput

        # Create links from the file names created by the Moses script
        #                to the file names expected by this ducttape task
	ln ${output_file_prefix}.sorted.gz     ${phrases_forward_gz}
	ln ${output_file_prefix}.inv.sorted.gz ${phrases_reverse_gz}
	ln ${output_file_prefix}.o.sorted.gz   ${phrases_ordering_gz}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}


func moses_extract_lexical_translation_table
     < moses_get_lexical_script
     < src_corpus
     < tgt_corpus
     < alignment_file
     > forward
     > reverse
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	output_file_prefix="$(pwd)/lex"

	set -o xtrace

	${moses_get_lexical_script} ${src_corpus} ${tgt_corpus} ${alignment_file} ${output_file_prefix}

        # Create links from the file names created by the Moses script
        #                to the file names expected by this ducttape task
	ln ${output_file_prefix}.f2e ${forward}
	ln ${output_file_prefix}.e2f ${reverse}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}


func moses_score_phrases_forward
     < moses_score
     < moses_score_parallel_script
     < phrases_forward_gz
     < lex_tt_forward
     :: num_cores
     :: sort_buffer_size
     < sort_exec
     < sort_compress
     > out_gz
     > count_of_counts
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	set -o xtrace

	# The moses_score_parallel_script relies on file extensions 
	#     to determine whether phrases is gzipped
	ln -s ${phrases_forward_gz} phrases.gz

	${moses_score_parallel_script}               \
	                           ${num_cores}      \
				   "${sort_exec} -S ${sort_buffer_size} --compress-program ${sort_compress}" \
				   ${moses_score}    \
				   phrases.gz        \
				   ${lex_tt_forward} \
				   ${out_gz}         \
				   --GoodTuring 0

	ln -s ${out_gz}.coc ${count_of_counts}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}

func moses_score_phrases_reverse
     < moses_score
     < moses_score_parallel_script
     < phrases_reverse_gz
     < lex_tt_reverse
     :: num_cores
     :: sort_buffer_size
     < sort_exec
     < sort_compress
     > out_gz
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	set -o xtrace

	# The moses_score_parallel_script relies on file extensions 
	#     to determine whether phrases is gzipped
	ln -s ${phrases_reverse_gz} phrases.gz

	${moses_score_parallel_script}               \
	                           ${num_cores}      \
				   "${sort_exec} -S ${sort_buffer_size} --compress-program ${sort_compress}" \
				   ${moses_score}    \
				   phrases.gz        \
				   ${lex_tt_reverse} \
				   ${out_gz}         \
				   --Inverse 1

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}


func moses_consolidate_translation_table
     < moses_consolidate
     < phrase_table_forward_gz
     < phrase_table_reverse_gz
     < phrase_table_count_of_counts
     > out_gz
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	# moses_consolidate relies on file extensions 
	#     to determine whether phrases is gzipped
	ln -s ${phrase_table_forward_gz} forward.gz
	ln -s ${phrase_table_reverse_gz} reverse.gz

	${moses_consolidate}                                  \
	       forward.gz                                     \
	       reverse.gz                                     \
	       /dev/stdout                                    \
	       --MinScore 2:0.0001                            \
	       --GoodTuring ${phrase_table_count_of_counts} | \
	gzip -c > ${out_gz}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"

}

func moses_lexical_reordering_table
     < moses_lexical_reordering_score
     < phrases_ordering_gz
     > out_gz
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	smoothing_value=0.5
	output_prefix="$(pwd)/reordering-table."

	set -o xtrace

	ln -s ${phrases_ordering_gz} phrases.o.gz

	${moses_lexical_reordering_score} \
	          phrases.o.gz            \
		  ${smoothing_value}      \
		  ${output_prefix}        \
		  --model "wbe msd wbe-msd-bidirectional-fe"

	ln ${output_prefix}wbe-msd-bidirectional-fe.gz ${out_gz}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}

func moses_ini_unfiltered_untuned
     < phrase_table_gz
     < lexicalized_reordering_model_gz
     < binarized_lm
     :: max_ngram_order
#     > ini_phrase_table_gz
#     > ini_lexicalized_reordering_model_gz
#     > ini_binarized_lm    
     > ini
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	# Create nice human-readable file names
	mkdir models
	ln ${phrase_table_gz} models/phrase-table.gz
	ln ${lexicalized_reordering_model_gz} models/lexicalized_reordering_model.gz
	ln ${binarized_lm} models/binlm

	unfiltered_ini="$(pwd)/models/moses.ini"

#	echo '################################################################################'  > ${unfiltered_ini}
#	echo '#                                                                              #' >> ${unfiltered_ini}
#	echo '#               Unfiltered and untuned Moses configuration file                #' >> ${unfiltered_ini}
#	echo '#                                                                              #' >> ${unfiltered_ini}
#	echo '################################################################################' >> ${unfiltered_ini}
#	echo                                                                                    >> ${unfiltered_ini}
#	echo '# Created' $(date +'%Y-%m-%d %H:%M:%S %Z')                                        >> ${unfiltered_ini}    
	echo '# Moses configuration file'                                                       >> ${unfiltered_ini}
	echo                                                                                    >> ${unfiltered_ini}
	echo '[input-factors]'                                                                  >> ${unfiltered_ini}
	echo '0'                                                                                >> ${unfiltered_ini}
	echo                                                                                    >> ${unfiltered_ini}
	echo '[mapping]'                                                                        >> ${unfiltered_ini}
	echo '0 T 0'                                                                            >> ${unfiltered_ini}
	echo                                                                                    >> ${unfiltered_ini}
	echo '[distortion-limit]'                                                               >> ${unfiltered_ini}
	echo '6'                                                                                >> ${unfiltered_ini}
	echo                                                                                    >> ${unfiltered_ini}
	echo '[feature]'                                                                        >> ${unfiltered_ini}
	echo 'UnknownWordPenalty'                                                               >> ${unfiltered_ini}
	echo 'WordPenalty'                                                                      >> ${unfiltered_ini}
	echo 'PhrasePenalty'                                                                    >> ${unfiltered_ini}
	echo -n 'PhraseDictionaryMemory '                                                       >> ${unfiltered_ini}
	echo -n 'name=TranslationModel0 '                                                       >> ${unfiltered_ini}
	echo -n 'num-features=4 '                                                               >> ${unfiltered_ini}
	echo -n "path=$(pwd)/models/phrase-table.gz "                                           >> ${unfiltered_ini}
	echo -n 'input-factor=0 '                                                               >> ${unfiltered_ini}
	echo    'output-factor=0'                                                               >> ${unfiltered_ini}
	echo -n 'LexicalReordering '                                                            >> ${unfiltered_ini}
	echo -n 'name=LexicalReordering0 '                                                      >> ${unfiltered_ini}
	echo -n 'num-features=6 '                                                               >> ${unfiltered_ini}
	echo -n 'type=wbe-msd-bidirectional-fe-allff '                                          >> ${unfiltered_ini}
	echo -n 'input-factor=0 '                                                               >> ${unfiltered_ini}
	echo -n 'output-factor=0 '                                                              >> ${unfiltered_ini}
	echo    "path=$(pwd)/models/lexicalized_reordering_model.gz"                            >> ${unfiltered_ini}
	echo 'Distortion'                                                                       >> ${unfiltered_ini}
	echo "KENLM name=LM0 factor=0 path=$(pwd)/models/binlm order=${max_ngram_order}"        >> ${unfiltered_ini}
	echo                                                                                    >> ${unfiltered_ini}
	echo '[weight]'                                                                         >> ${unfiltered_ini}
#	echo -n '# The default weights are NOT optimized for translation quality. '             >> ${unfiltered_ini}
#	echo    'You MUST tune the weights.'                                                    >> ${unfiltered_ini}
#	echo -n '# Documentation for tuning is here: '                                          >> ${unfiltered_ini}
#	echo    'http://www.statmt.org/moses/?n=FactoredTraining.Tuning'                        >> ${unfiltered_ini}
	echo 'UnknownWordPenalty0= 1'                                                           >> ${unfiltered_ini}
	echo 'WordPenalty0= -1'                                                                 >> ${unfiltered_ini}
	echo 'PhrasePenalty0= 0.2'                                                              >> ${unfiltered_ini}
	echo 'TranslationModel0= 0.2 0.2 0.2 0.2'                                               >> ${unfiltered_ini}
	echo 'LexicalReordering0= 0.3 0.3 0.3 0.3 0.3 0.3'                                      >> ${unfiltered_ini}
	echo 'Distortion0= 0.3'                                                                 >> ${unfiltered_ini}
	echo 'LM0= 0.5'                                                                         >> ${unfiltered_ini}

	# Create links to the human-readable file names accessible to subsequent ducttape tasks
#	ln models/phrase-table.gz ${ini_phrase_table_gz}
#	ln models/lexicalized_reordering_model.gz ${ini_lexicalized_reordering_model_gz}
#	ln models/binlm ${ini_binarized_lm}
	ln ${unfiltered_ini} ${ini}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}

func moses_filter_models
     < moses_filter_model_script
     < unfiltered_ini
     < src_in
     < moses_phrase_table_binarizer
     :: moses_phrase_table_binarizer_flags
     :: max_ngram_order
     > ini
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	${moses_filter_model_script}                   \
	                             $(pwd)/filtered   \
		                     ${unfiltered_ini} \
				     ${src_in}         \
	                            -Binarizer "${moses_phrase_table_binarizer} ${moses_phrase_table_binarizer_flags}" \
	&& ln $(pwd)/filtered/moses.ini ${ini}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"

}

func moses_decode
     < moses
     < src_in
     < ini
     :: moses_decode_threads
     > tgt_out
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	${moses} -f ${ini} -i ${src_in} --threads ${moses_decode_threads} > ${tgt_out}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}


func moses_multibleu
     < moses_multibleu_script
     < ref_in
     < tgt_in
     > bleu_cased
     > bleu_uncased
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	${moses_multibleu_script}     ${ref_in} < ${tgt_in} > ${bleu_uncased}
	${moses_multibleu_script} -lc ${ref_in} < ${tgt_in} > ${bleu_cased}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}

func moses_mert
     < moses_mert_script
     < moses
     < src_in
     < tgt_in
     < moses_untuned_ini
     :: nbest_size
     :: moses_decode_threads
     :: decoder_flags
     :: moses_scripts_dir
     :: moses_bin_dir
     :: moses_mert_max_iterations
     :: moses_mert_tuning_replicate
     > moses_tuned_ini
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"
	echo "Moses MERT tuning replicate ${moses_mert_tuning_replicate}"

	${moses_mert_script} \
	                     ${src_in} \
			     ${tgt_in} \
			     ${moses}  \
			     ${moses_untuned_ini}    \
			     --nbest ${nbest_size}              \
			     --working-dir $(pwd)/mert          \
			     --decoder-flags "${decoder_flags} -threads ${moses_decode_threads}" \
			     --rootdir ${moses_scripts_dir}     \
			     --mertdir ${moses_bin_dir}         \
			     --no-filter-phrase-table           \
			     --maximum-iterations=${moses_mert_max_iterations}

	ln $(pwd)/mert/moses.ini ${moses_tuned_ini}

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}

func moses_mert_substitute_weights
     < moses_substitute_weights_script
     < untuned_ini
     < tuned_ini
     > out
{
	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tBegin task"

	${moses_substitute_weights_script}      \
	        ${untuned_ini} \
		${tuned_ini}     \
		${out}         

	echo -e "$(date +'%Y-%m-%d %H:%M:%S %Z')\tEnd task"
}
