global {

       ducttape_experimental_imports=true

       moses_tokenizer=/opt/moses/scripts/tokenizer/tokenizer.perl
       moses_cleaner=/opt/moses/scripts/training/clean-corpus-n.perl
       moses_external_bin_dir=/opt/moses/external/mgiza-online.v0.7.3c/bin
       moses_train_modeler=/opt/moses/scripts/training/train-model.perl

       lmplz=/opt/moses/bin/lmplz
       build_binary=/opt/moses/bin/build_binary

       moses=/opt/moses/bin/moses
       moses_bin_dir=/opt/moses/bin
       moses_consolidate=/opt/moses/bin/consolidate
       moses_extract=/opt/moses/bin/extract
       moses_extract_parallel_script=/opt/moses/scripts/generic/extract-parallel.perl
       moses_get_lexical_script=/opt/moses/scripts/training/get-lexical.perl
       moses_filter_model_script=/opt/moses/scripts/training/filter-model-given-input.pl
       moses_lexical_reordering_score=/opt/moses/bin/lexical-reordering-score
       moses_mert_script=/opt/moses/scripts/training/mert-moses.pl
       moses_multibleu_script=/opt/moses/scripts/generic/multi-bleu.perl
       moses_phrase_table_binarizer=/opt/moses/bin/CreateOnDiskPt
       moses_score=/opt/moses/bin/score
       moses_score_parallel_script=/opt/moses/scripts/generic/score-parallel.perl
       moses_scripts_dir=/opt/moses/scripts
       moses_substitute_weights_script=/opt/moses/scripts/ems/support/substitute-weights.perl

       # MGIZA scripts and binaries
       giza2bal=/opt/moses/external/mgiza-online.v0.7.3c/scripts/giza2bal.pl
       mgiza=/opt/moses/external/mgiza-online.v0.7.3c/bin/mgiza
       mgiza_merge_alignment_script=/opt/moses/external/mgiza-online.v0.7.3c/scripts/merge_alignment.py
       mkcls=/opt/moses/external/mgiza-online.v0.7.3c/bin/mkcls
       plain2snt=/opt/moses/external/mgiza-online.v0.7.3c/bin/plain2snt
       snt2cooc=/opt/moses/external/mgiza-online.v0.7.3c/bin/snt2cooc
       symal=/opt/moses/external/mgiza-online.v0.7.3c/bin/symal

       mgiza_num_cpus=4
       moses_extract_num_cores=4
       moses_decode_threads=8

       sort_buffer_size="20G"

       split_exec="/usr/bin/split"
       sort_exec="/usr/bin/sort"
       sort_compress="/bin/gzip"

       min_sentence_length=1
       max_sentence_length=80

       reordering_method=msd-bidirectional-fe
       score_options_flags='--GoodTuring --MinScore 2:0.0001'
       max_phrase_length=5
       max_ngram_order=5
       moses_phrase_table_binarizer_flags="1 1 4 100 2"
       moses_mert_max_iterations=4

       europarl_dev=ep-11-04-06-009.txt
       europarl_devtest=ep-11-05-11-006.txt
       europarl_test=ep-11-06-23-014.txt

}



import util.tape

# To get Europarl corpus, uncomment exactly one of the following:
#
# Either 1) Download Europarl corpus
#task europarl_tarball calls download
#    :: url="http://www.statmt.org/europarl/v8/europarl.tgz"
#    :: downloader="wget"
#    :: downloader_flags=""
#     > out="europarl.tgz"
#
#     or 2) Symlink to an existing Europarl tarball on local disk
#task europarl_tarball calls symlink  < in="/path/to/europarl.tgz" > out="europarl.tgz"
#
#     or 3) Copy an existing Europarl tarball on local disk
#task europarl_tarball calls copy  < in="/path/to/europarl.tgz" > out="europarl.tgz"
task europarl_tarball calls symlink < in="/nas/data/parallel/training/tarball/europarl.v8.tgz" > out="europarl.tgz"

import europarl.tape
#
# Download Europarl sentence aligner 
task europarl_tarball_sentence_aligner calls download
    :: url="http://www.statmt.org/europarl/v7/tools.tgz"
    :: downloader="wget"
    :: downloader_flags=""
     > out="tools.tgz"
#
# Download nonbreaking prefixes
task moses_nonbreaking_prefixes calls download
    :: url="http://www.statmt.org/moses/RELEASE-3.0/binaries/linux-64bit/scripts/share/nonbreaking_prefixes/"
    :: downloader="wget"
    :: downloader_flags="--recursive --no-parent --no-host-directories --no-directories"
     > out="."
#
# Extract and align Europarl training, dev, devtest, and test data
task europarl_sentence_aligned calls extract_europarl
     < tarball=$out@europarl_tarball
     < tools_tarball=$out@europarl_tarball_sentence_aligner
     < nonbreaking_prefixes=$out@moses_nonbreaking_prefixes
    :: src_lang=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
    :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
    :: dev=$europarl_dev
    :: devtest=$europarl_devtest
    :: test=$europarl_test
     > train_src
     > train_tgt
     > dev_src
     > dev_tgt
     > devtest_src
     > devtest_tgt
     > test_src
     > test_tgt
#
# Extract Europarl monolingual training data
task europarl_monolingual_data calls extract_europarl_monolingual
     < tarball=$out@europarl_tarball
     < tools_tarball=$out@europarl_tarball_sentence_aligner
     < nonbreaking_prefixes=$out@moses_nonbreaking_prefixes
    :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
    :: dev=$europarl_dev
    :: devtest=$europarl_devtest
    :: test=$europarl_test
     > tgt


task europarl_train_trim
     :: n=10000
     < src_in=$train_src@europarl_sentence_aligned
     < tgt_in=$train_tgt@europarl_sentence_aligned
     > src_out
     > tgt_out
{
	head -n ${n} < ${src_in} > ${src_out}
	head -n ${n} < ${tgt_in} > ${tgt_out}
}
#
task europarl_dev_trim
     :: n=100
     < src_in=$dev_src@europarl_sentence_aligned
     < tgt_in=$dev_tgt@europarl_sentence_aligned
     > src_out
     > tgt_out
{
	head -n ${n} < ${src_in} > ${src_out}
	head -n ${n} < ${tgt_in} > ${tgt_out}
}
#
task europarl_devtest_trim
     :: n=100
     < src_in=$devtest_src@europarl_sentence_aligned
     < tgt_in=$devtest_tgt@europarl_sentence_aligned
     > src_out
     > tgt_out
{
	head -n ${n} < ${src_in} > ${src_out}
	head -n ${n} < ${tgt_in} > ${tgt_out}
}



import ems.tape
#
# Train Moses using EMS
task moses_ems calls ems
     :: src_lang=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: moses_dir=/opt/moses
     :: external_bin_dir=/opt/moses/external
     :: max_sentence_length=80
     :: ngram_order=5
     :: decoder_cores=8
     < training_src=$src_out@europarl_train_trim
     < training_tgt=$tgt_out@europarl_train_trim
     < training_monolingual_tgt=$tgt_out@europarl_train_trim
     < tuning_src=$src_out@europarl_dev_trim
     < tuning_tgt=$tgt_out@europarl_dev_trim
     < test_src=$src_out@europarl_devtest_trim
     < test_tgt=$tgt_out@europarl_devtest_trim
     > config
#
#      
task europarl_train_tokenize_src calls moses_tokenize
     :: language=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$src_out@europarl_train_trim
      > out
#
task europarl_train_tokenize_tgt calls moses_tokenize
     :: language=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$tgt_out@europarl_train_trim
      > out
#      
task europarl_dev_tokenize_src calls moses_tokenize
     :: language=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$src_out@europarl_dev_trim
      > out
#
task europarl_dev_tokenize_tgt calls moses_tokenize
     :: language=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$tgt_out@europarl_dev_trim
      > out
#      
task europarl_devtest_tokenize_src calls moses_tokenize
     :: language=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$src_out@europarl_devtest_trim
      > out
#
task europarl_devtest_tokenize_tgt calls moses_tokenize
     :: language=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$tgt_out@europarl_devtest_trim
      > out
#
#      
task europarl_test_tokenize_src calls moses_tokenize
     :: language=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$test_src@europarl_sentence_aligned
      > out
#
task europarl_test_tokenize_tgt calls moses_tokenize
     :: language=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$test_tgt@europarl_sentence_aligned
      > out
#
task europarl_train_clean calls moses_clean_corpus
     :: min_sentence_length=@
     :: max_sentence_length=@
      < moses_cleaner=@
     :: src_lang=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < src_in=$out@europarl_train_tokenize_src
      < tgt_in=$out@europarl_train_tokenize_tgt
      > lines_retained
      > src_out
      > tgt_out


################################################################################
#                                                                              #
#                Perform bilingual word alignment using MGIZA                  #
#                                                                              #
################################################################################
#
import giza.tape
#
task mgiza_mkcls_src calls mkcls
     < mkcls=@
     < in=$src_out@europarl_train_clean
     > out
#
task mgiza_mkcls_tgt calls mkcls
     < mkcls=@
     < in=$tgt_out@europarl_train_clean
     > out
#
task mgiza_plain2snt calls plain2snt
     < plain2snt=@
     < src_in=$src_out@europarl_train_clean
     < tgt_in=$tgt_out@europarl_train_clean
     > src_vcb
     > src_snt
     > tgt_vcb
     > tgt_snt
#
task mgiza_snt2cooc_forward calls snt2cooc
     < snt2cooc=@
     < src_vcb=@mgiza_plain2snt
     < tgt_vcb=@mgiza_plain2snt
     < integerized_bitext=$src_snt@mgiza_plain2snt
     > out
#
task mgiza_snt2cooc_reverse calls snt2cooc
     < snt2cooc=@
     < src_vcb=$tgt_vcb@mgiza_plain2snt
     < tgt_vcb=$src_vcb@mgiza_plain2snt
     < integerized_bitext=$tgt_snt@mgiza_plain2snt
     > out
#
task mgiza_forward calls mgiza
     < mgiza=@
     < merge_alignment_script=$mgiza_merge_alignment_script
     < coocurrence_file=$out@mgiza_snt2cooc_forward
     < src_vcb=@mgiza_plain2snt
     < src_vcb_classes=$out@mgiza_mkcls_src
     < tgt_vcb=@mgiza_plain2snt
     < tgt_vcb_classes=$out@mgiza_mkcls_tgt
     < integerized_bitext=$src_snt@mgiza_plain2snt
     :: num_cpus=$mgiza_num_cpus
     > out
#
task mgiza_reverse calls mgiza
     < mgiza=@
     < merge_alignment_script=$mgiza_merge_alignment_script
     < coocurrence_file=$out@mgiza_snt2cooc_reverse
     < src_vcb=$tgt_vcb@mgiza_plain2snt
     < src_vcb_classes=$out@mgiza_mkcls_tgt
     < tgt_vcb=$src_vcb@mgiza_plain2snt
     < tgt_vcb_classes=$out@mgiza_mkcls_src
     < integerized_bitext=$tgt_snt@mgiza_plain2snt
     :: num_cpus=$mgiza_num_cpus
     > out
#
task mgiza_alignments calls mgiza_symmetrize
     < giza2bal=@
     < symal=@
     < mgiza_forward_alignments=$out@mgiza_forward
     < mgiza_reverse_alignments=$out@mgiza_reverse
     > out

import moses.tape
#
task moses_phrase_pairs calls moses_extract_phrases
     < moses_extract=@
     < moses_extract_parallel_script=@
     < src_corpus=$src_out@europarl_train_clean
     < tgt_corpus=$tgt_out@europarl_train_clean
     < alignment_file=$out@mgiza_alignments
     :: num_cores=$moses_extract_num_cores
     :: sort_buffer_size=@
     < split_exec=@
     < sort_exec=@
     < sort_compress=@
     :: max_phrase_length=@
     > phrases_forward_gz
     > phrases_reverse_gz
     > phrases_ordering_gz
#
task moses_lexical_translation_table calls moses_extract_lexical_translation_table
     < moses_get_lexical_script=@
     < src_corpus=$src_out@europarl_train_clean
     < tgt_corpus=$tgt_out@europarl_train_clean
     < alignment_file=$out@mgiza_alignments
     > forward
     > reverse
#
task moses_score_phrases_forward calls moses_score_phrases_forward
     < moses_score=@
     < moses_score_parallel_script=@
     < phrases_forward_gz=$phrases_forward_gz@moses_phrase_pairs
     < lex_tt_forward=$forward@moses_lexical_translation_table
     :: num_cores=$moses_extract_num_cores
     :: sort_buffer_size=@
     < sort_exec=@
     < sort_compress=@
     > out_gz
     > count_of_counts
#
task moses_score_phrases_reverse calls moses_score_phrases_reverse
     < moses_score=@
     < moses_score_parallel_script=@
     < phrases_reverse_gz=$phrases_reverse_gz@moses_phrase_pairs
     < lex_tt_reverse=$reverse@moses_lexical_translation_table
     :: num_cores=$moses_extract_num_cores
     :: sort_buffer_size=@
     < sort_exec=@
     < sort_compress=@
     > out_gz
#
task moses_phrase_table calls moses_consolidate_translation_table
     < moses_consolidate=@
     < phrase_table_forward_gz=$out_gz@moses_score_phrases_forward
     < phrase_table_reverse_gz=$out_gz@moses_score_phrases_reverse
     < phrase_table_count_of_counts=$count_of_counts@moses_score_phrases_forward
     > out_gz
#
task moses_lexical_reordering_table calls moses_lexical_reordering_table
     < moses_lexical_reordering_score=@
     < phrases_ordering_gz=$phrases_ordering_gz@moses_phrase_pairs
     > out_gz
#
task moses_ini_unfiltered_untuned calls moses_ini_unfiltered_untuned
     < phrase_table_gz=$out_gz@moses_phrase_table
     < lexicalized_reordering_model_gz=$out_gz@moses_lexical_reordering_table
     < binarized_lm=$out@kenlm_binarized
     :: max_ngram_order=@
     > ini
#
task moses_tuning_prepare calls moses_filter_models
     < moses_filter_model_script=@
     < src_in=$out@europarl_dev_tokenize_src
     < unfiltered_ini=$ini@moses_ini_unfiltered_untuned
     < moses_phrase_table_binarizer=@
     :: moses_phrase_table_binarizer_flags=@
     > ini
#
task moses_tuning_mert calls moses_mert
     < moses_mert_script=@
     < moses=@
     < src_in=$out@europarl_dev_tokenize_src
     < tgt_in=$out@europarl_dev_tokenize_tgt
     < moses_untuned_ini=$ini@moses_tuning_prepare
     :: nbest_size=100
     :: moses_decode_threads=@
     :: decoder_flags="-v 0"
     :: moses_scripts_dir=@
     :: moses_bin_dir=@
     :: moses_mert_max_iterations=@
     > moses_tuned_ini
#
task moses_tuning_weights calls moses_mert_substitute_weights
     < moses_substitute_weights_script=@
     < untuned_ini=$ini@moses_ini_unfiltered_untuned
     < tuned_ini=$moses_tuned_ini@moses_tuning_mert
     > out
#
task moses_devtest_prepare calls moses_filter_models
     < moses_filter_model_script=@
     < src_in=$out@europarl_devtest_tokenize_src
     < unfiltered_ini=$ini@moses_ini_unfiltered_untuned
     < moses_phrase_table_binarizer=@
     :: moses_phrase_table_binarizer_flags=@
     > ini
#
task moses_devtest_ini calls moses_mert_substitute_weights
     < moses_substitute_weights_script=@
     < untuned_ini=$ini@moses_devtest_prepare
     < tuned_ini=$out@moses_tuning_weights
     > out
#
task moses_devtest_decode calls moses_decode
     < moses=@
     < src_in=$out@europarl_devtest_tokenize_src
     < ini=$out@moses_devtest_ini
     :: moses_decode_threads=@
     > tgt_out
#
task moses_devtest_multibleu calls moses_multibleu
     < moses_multibleu_script=@
     < ref_in=$out@europarl_devtest_tokenize_tgt
     < tgt_in=$tgt_out@moses_devtest_decode
     > bleu_cased
     > bleu_uncased

import kenlm.tape
#
task kenlm calls lmplz
     < lmplz=@
     < corpus=$out@europarl_train_tokenize_tgt
     :: max_ngram_order=@
     > arpa_file
     :: max_sorting_memory="20%"
     :: tmp_dir="."
#
task kenlm_binarized calls build_binary
     < build_binary=@
     < arpa_file=@kenlm
     > out



plan {

#     reach europarl_sentence_aligned via (src:    cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: bg)
#     reach europarl_sentence_aligned via (src: bg    da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: cs)
#     reach europarl_sentence_aligned via (src: bg cs    de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: da)
#     reach europarl_sentence_aligned via (src: bg cs da    el en es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: de)
#     reach europarl_sentence_aligned via (src: bg cs da de    en es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: el)
#     reach europarl_sentence_aligned via (src: bg cs da de el    es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: en)
#     reach europarl_sentence_aligned via (src: bg cs da de el en    et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: es)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es    fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: et)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et    fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: fi)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi    hu it lt lv nl pl pt ro sk sl sv) * (tgt: fr)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi fr    it lt lv nl pl pt ro sk sl sv) * (tgt: hu)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi fr hu    lt lv nl pl pt ro sk sl sv) * (tgt: it)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi fr hu it    lv nl pl pt ro sk sl sv) * (tgt: lt)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi fr hu it lt    nl pl pt ro sk sl sv) * (tgt: lv)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi fr hu it lt lv    pl pt ro sk sl sv) * (tgt: nl)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi fr hu it lt lv nl    pt ro sk sl sv) * (tgt: pl)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi fr hu it lt lv nl pl    ro sk sl sv) * (tgt: pt)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi fr hu it lt lv nl pl pt    sk sl sv) * (tgt: ro)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro    sl sv) * (tgt: sk)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk    sv) * (tgt: sl)
#     reach europarl_sentence_aligned via (src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl   ) * (tgt: sv)

#     reach europarl_monolingual_data via (tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)

#      reach europarl_sentence_aligned via (src: fr) * (tgt: en)

#      reach europarl_monolingual_data via (tgt: en)

#       reach mgiza_alignments via (src: fr) * (tgt: en)
#	reach moses_phrase_pairs via (src: fr) * (tgt: en)
#	reach moses_lexical_translation_table via (src: fr) * (tgt: en)
#	reach moses_score_phrases_forward via (src: fr) * (tgt: en)
#	reach moses_score_phrases_reverse via (src: fr) * (tgt: en)
#	reach moses_phrase_table via (src: fr) * (tgt: en)
#	reach moses_lexical_reordering_table via (src: fr) * (tgt: en)
#
#	reach moses_tuning_weights via (src: fr) * (tgt: en)
#	reach moses_devtest_ini via (src: fr) * (tgt: en)
	reach moses_devtest_multibleu via (src: fr) * (tgt: en)
	 
#       reach configure_ems via (src: fr) * (tgt: en)

#      reach symmetrize_giza via (src: fr) * (tgt: en)

#      reach prepare_data via (src: fr) * (tgt: en)

#      reach moses via (src:fr) * (tgt:en)

}
