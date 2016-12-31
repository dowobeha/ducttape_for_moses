func moses_tokenize
     :: language
      < moses_tokenizer
      < in
      > out
{
	${moses_tokenizer} -a -l ${language} < ${in} > ${out}
}

func moses_clean_corpus
     :: min_sentence_length
     :: max_sentence_length
      < moses_cleaner
     :: src_lang
     :: tgt_lang
      < src_in
      < tgt_in
      > lines_retained
      > src_out
      > tgt_out
{
	ln -s ${src_in} in.${src_lang}
	ln -s ${tgt_in} in.${tgt_lang}

	${moses_cleaner} in ${src_lang} ${tgt_lang} out ${min_sentence_length} ${max_sentence_length} ${lines_retained}

	ln out.${src_lang} ${src_out}
	ln out.${tgt_lang} ${tgt_out}
}

func moses_prepare_data
     < moses_train_modeler
     :: src_lang
     :: tgt_lang
     :: external_bin_dir
     :: alignment_symmetrization_method
     :: reordering_method
     :: max_phrase_length
     :: score_options_flags
     < src_in
     < tgt_in
     > src_vcb
     > tgt_vcb
     > src_vcb_cls
     > tgt_vcb_cls
     > src_vcb_cls_cats
     > tgt_vcb_cls_cats
     > e2f_snt
     > f2e_snt
{

	ln -s ${src_in} in.${src_lang}
	ln -s ${tgt_in} in.${tgt_lang}

	${moses_train_modeler} -dont-zip    \
                               -last-step 1 \
                               -external-bin-dir ${external_bin_dir} \
                               -f ${src_lang} \
                               -e ${tgt_lang} \
			       -alignment ${alignment_symmetrization_method} \
			       -max-phrase-length ${max_phrase_length} \
			       -reordering ${reordering_method} \
			       -score-options "${score_options_flags}" \
			       -parallel \
			       -corpus in \
			       -corpus-dir out

	ln -s out/${src_lang}.vcb ${src_vcb}
	ln -s out/${tgt_lang}.vcb ${tgt_vcb}
	ln -s out/${src_lang}.vcb.classes  ${src_vcb_cls}
	ln -s out/${tgt_lang}.vcb.classes  ${tgt_vcb_cls}
	ln -s out/${src_lang}.vcb.classes.cats  ${src_vcb_cls_cats}
	ln -s out/${tgt_lang}.vcb.classes.cats  ${tgt_vcb_cls_cats}
	ln -s out/${tgt_lang}-${src_lang}-int-train.snt ${e2f_snt}
	ln -s out/${src_lang}-${tgt_lang}-int-train.snt ${f2e_snt}

}

func moses_run_giza
     < moses_train_modeler
     :: src_lang
     :: tgt_lang
     :: external_bin_dir
     :: alignment_symmetrization_method
     :: reordering_method
     :: max_phrase_length
     :: score_options_flags
     < src_vcb
     < tgt_vcb
     < src_vcb_cls
     < tgt_vcb_cls
     < src_vcb_cls_cats
     < tgt_vcb_cls_cats
     < e2f_snt
     < f2e_snt
     > out
{
	mkdir in
	ln -s ${src_vcb} in/${src_lang}.vcb
	ln -s ${tgt_vcb} in/${tgt_lang}.vcb
	ln -s ${src_vcb_cls} in/${src_lang}.vcb.classes
	ln -s ${tgt_vcb_cls} in/${tgt_lang}.vcb.classes
	ln -s ${src_vcb_cls_cats} in/${src_lang}.vcb.classes.cats
	ln -s ${tgt_vcb_cls_cats} in/${tgt_lang}.vcb.classes.cats
	ln -s ${e2f_snt} in/${tgt_lang}-${src_lang}-int-train.snt
	ln -s ${f2e_snt} in/${src_lang}-${tgt_lang}-int-train.snt

	${moses_train_modeler}	-mgiza	\
				-dont-zip	\
				-first-step 2	\
				-last-step 2	\
				-external-bin-dir ${external_bin_dir}	\
				-f ${src_lang}	\
				-e ${tgt_lang}	\
				-alignment ${alignment_symmetrization_method}	\
				-max-phrase-length ${max_phrase_length}	\
				-reordering ${reordering_method}	\
				-score-options "${score_options_flags}"	\
				-parallel	\
				-corpus-dir in	\
				-giza-e2f ${out}	\
				-direction 2
}

func moses_run_giza_inverse
     < moses_train_modeler
     :: src_lang
     :: tgt_lang
     :: external_bin_dir
     :: alignment_symmetrization_method
     :: reordering_method
     :: max_phrase_length
     :: score_options_flags
     < src_vcb
     < tgt_vcb
     < src_vcb_cls
     < tgt_vcb_cls
     < src_vcb_cls_cats
     < tgt_vcb_cls_cats
     < e2f_snt
     < f2e_snt
     > out
{
	mkdir in
	ln -s ${src_vcb} in/${src_lang}.vcb
	ln -s ${tgt_vcb} in/${tgt_lang}.vcb
	ln -s ${src_vcb_cls} in/${src_lang}.vcb.classes
	ln -s ${tgt_vcb_cls} in/${tgt_lang}.vcb.classes
	ln -s ${src_vcb_cls_cats} in/${src_lang}.vcb.classes.cats
	ln -s ${tgt_vcb_cls_cats} in/${tgt_lang}.vcb.classes.cats
	ln -s ${e2f_snt} in/${tgt_lang}-${src_lang}-int-train.snt
	ln -s ${f2e_snt} in/${src_lang}-${tgt_lang}-int-train.snt

	${moses_train_modeler}	-mgiza	\
				-dont-zip	\
				-first-step 2	\
				-last-step 2	\
				-external-bin-dir ${external_bin_dir}	\
				-f ${src_lang}	\
				-e ${tgt_lang}	\
				-alignment ${alignment_symmetrization_method}	\
				-max-phrase-length ${max_phrase_length}	\
				-reordering ${reordering_method}	\
				-score-options "${score_options_flags}"	\
				-parallel	\
				-corpus-dir in	\
				-giza-f2e ${out}	\
				-direction 1
}

func moses_symmetrize_giza
     < moses_train_modeler
     :: src_lang
     :: tgt_lang
     :: external_bin_dir
     :: alignment_symmetrization_method
     :: reordering_method
     :: max_phrase_length
     :: score_options_flags
     < e2f_in
     < f2e_in
     > alignment_file
     > alignment_stem
{
	${moses_train_modeler}	-dont-zip	\
				-first-step 3	\
				-last-step 3	\
				-external-bin-dir ${external_bin_dir}	\
				-f ${src_lang}	\
				-e ${tgt_lang}	\
				-alignment ${alignment_symmetrization_method}	\
				-max-phrase-length ${max_phrase_length}	\
				-reordering ${reordering_method}	\
				-score-options "${score_options_flags}"	\
				-parallel	\
				-giza-e2f ${e2f_in} \
				-giza-f2e ${f2e_in} \
				-alignment-file ${alignment_file} \
				-alignment-stem ${alignment_stem} \
				-alignment ${alignment_symmetrization_method}
}

func mkcls
     < mkcls
     < in
     :: num_classes
     :: num_optimization_runs
     > out
{
	${mkcls} -c${num_classes} \
	         -n${num_optimization_runs} \
		 -p${in} \
		 -V${out} \
		 opt
}

func ems
     :: src_lang
     :: tgt_lang
     :: moses_dir
     :: external_bin_dir
     :: max_sentence_length
     :: ngram_order
     :: decoder_cores
     < training_src
     < training_tgt
     < training_monolingual_tgt
     < tuning_src
     < tuning_tgt
     < test_src
     < test_tgt
     > config
{
	training_stem='training'
	ln -s ${training_src} ${training_stem}.${src_lang}
	ln -s ${training_tgt} ${training_stem}.${tgt_lang}

	echo '[GENERAL]'                                                               >  ${config}
	echo ''                                                                        >> ${config}
	echo 'working-dir = '"$(pwd)"                                                  >> ${config}
	echo ''                                                                        >> ${config}
	echo 'moses-src-dir = '"${moses_dir}"                                          >> ${config}
        echo 'moses-script-dir = '"${moses_dir}"'/scripts'                             >> ${config}
        echo 'external-bin-dir = '"${moses_dir}"'/external/bin'                        >> ${config}
	echo ''                                                                        >> ${config}
        echo 'input-extension = '"${src_lang}"                                         >> ${config}
        echo 'output-extension = '"${tgt_lang}"                                        >> ${config}
        echo 'pair-extension = '"${src_lang}-${tgt_lang}"                              >> ${config}
	echo ''                                                                        >> ${config}
	echo '# moses decoder'                                                         >> ${config} 
	echo 'decoder = '"${moses_dir}"'/bin/moses'                                    >> ${config}
	echo ''                                                                        >> ${config}
	echo '# conversion of rule table into binary on-disk format'                   >> ${config}
	echo 'ttable-binarizer = "'"${moses_dir}"'/bin/CreateOnDiskPt 1 1 4 100 2"'    >> ${config}
	echo ''                                                                        >> ${config}
	echo '# tokenizers'                                                            >> ${config}
	echo -n 'input-tokenizer = "'                                                  >> ${config}
	echo -n    "$moses_dir"'/scripts/tokenizer/tokenizer.perl -a -l '              >> ${config}
	echo       "${src_lang}"'"'                                                    >> ${config}
	echo -n 'output-tokenizer = "'                                                 >> ${config}
	echo -n    "$moses_dir"'/scripts/tokenizer/tokenizer.perl -a -l '              >> ${config}
	echo       "${tgt_lang}"'"'                                                    >> ${config}
	echo ''                                                                        >> ${config}
	echo '# truecasers'                                                            >> ${config}
#	echo 'input-truecaser = '"${moses_dir}"'/scripts/recaser/truecase.perl'        >> ${config}
#	echo 'output-truecaser = '"${moses_dir}"'/scripts/recaser/truecase.perl'       >> ${config} 
#	echo 'detruecaser = '"${moses_dir}"'/scripts/recaser/detruecase.perl'          >> ${config}
	echo ''                                                                        >> ${config}
	echo ''                                                                        >> ${config}
	echo '[CORPUS]'                                                                >> ${config}
	echo ''                                                                        >> ${config}
	echo 'max-sentence-length = '"${max_sentence_length}"                          >> ${config}
	echo ''                                                                        >> ${config}
	echo '[CORPUS:europarl]'                                                       >> ${config}
	echo ''                                                                        >> ${config}
	echo 'raw-stem = '"${training_stem}"                                           >> ${config}
	echo ''                                                                        >> ${config}
	echo ''                                                                        >> ${config}
	echo '[LM]'                                                                    >> ${config}
	echo ''                                                                        >> ${config}
	echo -n 'lm-training = "'                                                      >> ${config}
	echo -n "${moses_dir}"'/scripts/ems/support/lmplz-wrapper.perl'                >> ${config}
	echo    ' -bin '"${moses_dir}"'/bin/lmplz"'                                    >> ${config}
	echo 'settings = "--prune '0 0 1' -T $working-dir/lm -S 20%"'                  >> ${config}
	echo ''                                                                        >> ${config}
	echo '# order of the language model'                                           >> ${config}
	echo 'order = '"${ngram_order}"                                                >> ${config}
	echo ''                                                                        >> ${config}
	echo '# KenLM settings for Moses'                                              >> ${config}
	echo 'lm-binarizer = '"${moses_dir}"'/bin/build_binary'                        >> ${config}
	echo 'type = 8'                                                                >> ${config}
	echo ''                                                                        >> ${config}
	echo '[LM:europarl]'                                                           >> ${config}
	echo ''                                                                        >> ${config}
	echo 'raw-corpus = '"${training_monolingual_tgt}"                              >> ${config}
	echo ''                                                                        >> ${config}
	echo ''                                                                        >> ${config}
	echo '[TRAINING]'                                                              >> ${config}
	echo ''                                                                        >> ${config}
	echo 'script = '"${moses_dir}"'/scripts/training/train-model.perl'             >> ${config}
	echo 'parallel = yes'                                                          >> ${config}
	echo 'alignment-symmetrization-method = grow-diag-final-and'                   >> ${config}
	echo 'lexicalized-reordering = msd-bidirectional-fe'                           >> ${config}
	echo 'max-phrase-length = 5'                                                   >> ${config}
	echo 'score-settings = "--GoodTuring --MinScore 2:0.0001"'                     >> ${config}
	echo 'training-options = "-mgiza -mgiza-cpus 8"'                               >> ${config}
	echo ''                                                                        >> ${config}
	echo ''                                                                        >> ${config}
	echo '[TUNING]'                                                                >> ${config}
	echo ''                                                                        >> ${config}
	echo 'tuning-script = '"${moses_dir}"'/scripts/training/mert-moses.pl'         >> ${config}
	echo 'tuning-settings = "--mertdir '"${moses_dir}/bin"' --maximum-iterations=3"'                       >> ${config}
	echo ''                                                                        >> ${config}
	echo 'raw-input = '"${tuning_src}"                                             >> ${config}
	echo 'raw-reference = '"${tuning_tgt}"                                         >> ${config}
	echo 'nbest = 100'                                                             >> ${config}
	echo 'filter-settings = ""'                                                    >> ${config}
	echo 'decoder-settings = "-threads '"${decoder_cores}"'"'                      >> ${config}
#	echo 'maximum-iterations = 3'                                                  >> ${config}
	echo ''                                                                        >> ${config}
	echo ''                                                                        >> ${config}
#	echo '[TRUECASER]'                                                             >> ${config}
#	echo ''                                                                        >> ${config}
#	echo 'trainer = '"${moses_dir}"'/scripts/recaser/train-truecaser.perl'         >> ${config}
	echo ''                                                                        >> ${config}
	echo ''                                                                        >> ${config}
	echo '[EVALUATION]'                                                            >> ${config}
	echo ''                                                                        >> ${config}
	echo -n 'decoder-settings = "'                                                 >> ${config}
	echo -n ' -search-algorithm 1'                                                 >> ${config}
	echo -n ' -cube-pruning-pop-limit 5000'                                        >> ${config}
	echo -n ' -s 5000'                                                             >> ${config}
	echo    ' -threads '"${decoder_cores}"'"'                                      >> ${config}
	echo ''                                                                        >> ${config}
	echo -n 'detokenizer = "'"${moses_dir}"'/scripts/tokenizer/detokenizer.perl '  >> ${config}
	echo    ' -l '"${tgt_lang}"'"'                                                 >> ${config}
	echo ''                                                                        >> ${config}
	echo 'multi-bleu = "'"${moses_dir}"'/scripts/generic/multi-bleu.perl -lc"'     >> ${config}
	echo 'multi-bleu-c = "'"${moses_dir}"'/scripts/generic/multi-bleu.perl"'       >> ${config}
	echo ''                                                                        >> ${config}
#	echo 'analysis = '"${moses_dir}"'/scripts/ems/support/analysis.perl'           >> ${config}
#	echo 'analyze-coverage = yes'                                                  >> ${config}
#	echo 'report-segmentation = yes'                                               >> ${config}
	echo ''                                                                        >> ${config}
	echo '[EVALUATION:newstest2011]'                                               >> ${config}
	echo ''                                                                        >> ${config}
	echo 'raw-input = '"${test_src}"                                               >> ${config}
	echo 'raw-reference = '"${test_tgt}"                                           >> ${config}
	echo ''                                                                        >> ${config}
	echo ''                                                                        >> ${config}
	echo '[REPORTING]'                                                             >> ${config}
	echo ''                                                                        >> ${config}
	echo '### currently no parameters for reporting section'                       >> ${config}


	${moses_dir}/scripts/ems/experiment.perl -config ${config}

}
