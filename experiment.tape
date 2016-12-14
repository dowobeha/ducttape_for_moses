global {

       ducttape_experimental_imports=true

       moses_tokenizer=/opt/moses/scripts/tokenizer/tokenizer.perl
       moses_cleaner=/opt/moses/scripts/training/clean-corpus-n.perl
       moses_external_bin_dir=/opt/moses/external/mgiza-online.v0.7.3c/bin
       moses_train_modeler=/opt/moses/scripts/training/train-model.perl
       mkcls=/opt/moses/external/mgiza-online.v0.7.3c/bin/mkcls

       min_sentence_length=1
       max_sentence_length=80

       alignment_symmetrization_method=grow-diag-final-and
       reordering_method=msd-bidirectional-fe
       score_options_flags='--GoodTuring --MinScore 2:0.0001'
       max_phrase_length=5

       mkcls_num_classes=50
       mkcls_num_optimization_runs=2

       europarl_dev=ep-11-04-06-009.txt
       europarl_devtest=ep-11-05-11-006.txt
       europarl_test=ep-11-06-23-014.txt

}



import util.tape

# To get Europarl corpus, uncomment exactly one of the following:
#
# Either 1) Download Europarl corpus
task europarl_tarball calls download 
    :: url="http://www.statmt.org/europarl/v8/europarl.tgz" 
    :: downloader="wget"
    :: downloader_flags=""
     > out="europarl.tgz"
#
#     or 2) Symlink to an existing Europarl tarball on local disk
#task europarl_tarball calls symlink  < in="/path/to/europarl.tgz" > out="europarl.tgz"
#
#     or 3) Copy an existing Europarl tarball on local disk
#task europarl_tarball calls copy  < in="/path/to/europarl.tgz" > out="europarl.tgz"


import europarl.tape
#
# Download Europarl sentence aligner 
task download_sentence_aligner calls download 
    :: url="http://www.statmt.org/europarl/v7/tools.tgz"
    :: downloader="wget"
    :: downloader_flags=""
     > out="tools.tgz"
#
# Extract Europarl sentence aligner
task sentence_aligner < tarball=$out@download_sentence_aligner > out="sentence-align-corpus.perl" {
     tar xfvz ${tarball} sentence-align-corpus.perl
}
#
# Download nonbreaking prefixes
task nonbreaking_prefixes calls download
    :: url="http://www.statmt.org/moses/RELEASE-3.0/binaries/linux-64bit/scripts/share/nonbreaking_prefixes/"
    :: downloader="wget"
    :: downloader_flags="--recursive --no-parent --no-host-directories --no-directories"
     > out="."
#
# Extract and align Europarl training, dev, devtest, and test data
task aligned_europarl calls extract_europarl
     < tarball=$out@europarl_tarball
     < tools_tarball=$out@download_sentence_aligner
     < nonbreaking_prefixes=$out@nonbreaking_prefixes
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
     < tools_tarball=$out@download_sentence_aligner
     < nonbreaking_prefixes=$out@nonbreaking_prefixes
    :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
    :: dev=$europarl_dev
    :: devtest=$europarl_devtest
    :: test=$europarl_test
     > tgt


task trim_train
     :: n=10000
     < src_in=$train_src@aligned_europarl
     < tgt_in=$train_tgt@aligned_europarl
     > src_out
     > tgt_out
{
	head -n ${n} < ${src_in} > ${src_out}
	head -n ${n} < ${tgt_in} > ${tgt_out}
}

import ems.tape
#
# Train Moses using EMS
task configure_ems calls ems
     :: src_lang=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: moses_dir=/opt/moses
     :: external_bin_dir=/opt/moses/external
     :: max_sentence_length=80
     :: ngram_order=5
     :: decoder_cores=4
     < training_src=$train_src@aligned_europarl
     < training_tgt=$train_tgt@aligned_europarl
     < training_monolingual_tgt=$tgt@europarl_monolingual_data
     < tuning_src=$dev_src@aligned_europarl
     < tuning_tgt=$dev_tgt@aligned_europarl
     < test_src=$devtest_src@aligned_europarl
     < test_tgt=$devtest_tgt@aligned_europarl
     > config
#
#      
task tokenize_train_src calls moses_tokenize
     :: language=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$src_out@trim_train
      > out
#
task tokenize_train_tgt calls moses_tokenize
     :: language=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$tgt_out@trim_train
      > out
#      
task tokenize_dev_src calls moses_tokenize
     :: language=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$dev_src@aligned_europarl
      > out
#
task tokenize_dev_tgt calls moses_tokenize
     :: language=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$dev_tgt@aligned_europarl
      > out
#      
task tokenize_devtest_src calls moses_tokenize
     :: language=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$devtest_src@aligned_europarl
      > out
#
task tokenize_devtest_tgt calls moses_tokenize
     :: language=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$devtest_tgt@aligned_europarl
      > out
#
#      
task tokenize_test_src calls moses_tokenize
     :: language=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$test_src@aligned_europarl
      > out
#
task tokenize_test_tgt calls moses_tokenize
     :: language=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < moses_tokenizer=@
      < in=$test_tgt@aligned_europarl
      > out
#
task clean_europarl_train calls moses_clean_corpus
     :: min_sentence_length=@
     :: max_sentence_length=@
      < moses_cleaner=@
     :: src_lang=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < src_in=$out@tokenize_train_src
      < tgt_in=$out@tokenize_train_tgt
      > lines_retained
      > src_out
      > tgt_out
#
task clean_europarl_dev calls moses_clean_corpus
     :: min_sentence_length=@
     :: max_sentence_length=@
      < moses_cleaner=@
     :: src_lang=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
      < src_in=$out@tokenize_dev_src
      < tgt_in=$out@tokenize_dev_tgt
      > lines_retained
      > src_out
      > tgt_out
#
task prepare_data calls moses_prepare_data
     < moses_train_modeler=@
     :: src_lang=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     :: external_bin_dir=$moses_external_bin_dir
     :: alignment_symmetrization_method=@
     :: reordering_method=@
     :: max_phrase_length=@
     :: score_options_flags=@
     < src_in=$src_out@clean_europarl_train
     < tgt_in=$tgt_out@clean_europarl_train
     > src_out
     > tgt_out


plan {

#     reach aligned_europarl via (src:    cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: bg)
#     reach aligned_europarl via (src: bg    da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: cs)
#     reach aligned_europarl via (src: bg cs    de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: da)
#     reach aligned_europarl via (src: bg cs da    el en es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: de)
#     reach aligned_europarl via (src: bg cs da de    en es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: el)
#     reach aligned_europarl via (src: bg cs da de el    es et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: en)
#     reach aligned_europarl via (src: bg cs da de el en    et fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: es)
#     reach aligned_europarl via (src: bg cs da de el en es    fi fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: et)
#     reach aligned_europarl via (src: bg cs da de el en es et    fr hu it lt lv nl pl pt ro sk sl sv) * (tgt: fi)
#     reach aligned_europarl via (src: bg cs da de el en es et fi    hu it lt lv nl pl pt ro sk sl sv) * (tgt: fr)
#     reach aligned_europarl via (src: bg cs da de el en es et fi fr    it lt lv nl pl pt ro sk sl sv) * (tgt: hu)
#     reach aligned_europarl via (src: bg cs da de el en es et fi fr hu    lt lv nl pl pt ro sk sl sv) * (tgt: it)
#     reach aligned_europarl via (src: bg cs da de el en es et fi fr hu it    lv nl pl pt ro sk sl sv) * (tgt: lt)
#     reach aligned_europarl via (src: bg cs da de el en es et fi fr hu it lt    nl pl pt ro sk sl sv) * (tgt: lv)
#     reach aligned_europarl via (src: bg cs da de el en es et fi fr hu it lt lv    pl pt ro sk sl sv) * (tgt: nl)
#     reach aligned_europarl via (src: bg cs da de el en es et fi fr hu it lt lv nl    pt ro sk sl sv) * (tgt: pl)
#     reach aligned_europarl via (src: bg cs da de el en es et fi fr hu it lt lv nl pl    ro sk sl sv) * (tgt: pt)
#     reach aligned_europarl via (src: bg cs da de el en es et fi fr hu it lt lv nl pl pt    sk sl sv) * (tgt: ro)
#     reach aligned_europarl via (src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro    sl sv) * (tgt: sk)
#     reach aligned_europarl via (src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk    sv) * (tgt: sl)
#     reach aligned_europarl via (src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl   ) * (tgt: sv)

#     reach europarl_monolingual_data via (tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)

      reach aligned_europarl via (src: fr) * (tgt: en)

      reach europarl_monolingual_data via (tgt: en)

      reach configure_ems via (src: fr) * (tgt: en)

      reach prepare_data via (src: fr) * (tgt: en)

#      reach moses via (src:fr) * (tgt:en)

}
