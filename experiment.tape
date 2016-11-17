global {

       ducttape_experimental_imports=true

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
# Extract and align Europarl test data
task europarl_test_data calls extract_europarl_test
     < tarball=$out@europarl_tarball
     < tools_tarball=$out@download_sentence_aligner
     < nonbreaking_prefixes=$out@nonbreaking_prefixes
    :: src_lang=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
    :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     > src
     > tgt
#
# Extract and align Europarl training data
task europarl_train_data calls extract_europarl_train
     < tarball=$out@europarl_tarball
     < tools_tarball=$out@download_sentence_aligner
     < nonbreaking_prefixes=$out@nonbreaking_prefixes
    :: src_lang=(src: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
    :: tgt_lang=(tgt: bg cs da de el en es et fi fr hu it lt lv nl pl pt ro sk sl sv)
     > src
     > tgt


plan {

     reach europarl_train_data via (src: *) * (tgt: en)

     reach europarl_test_data  via (src: *) * (tgt: en)

}
